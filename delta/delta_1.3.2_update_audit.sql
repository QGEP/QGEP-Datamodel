CREATE TABLE qgep_sys.logged_relations (
    relation_name text not null,
    uid_column text not null,
    PRIMARY KEY (relation_name, uid_column)
);

COMMENT ON TABLE qgep_sys.logged_relations IS 'Table used to store unique identifier columns for table or views, so that events can be replayed';
COMMENT ON COLUMN qgep_sys.logged_relations.relation_name IS 'Relation (table or view) name (with schema if needed)';
COMMENT ON COLUMN qgep_sys.logged_relations.uid_column IS 'Name of a column that is used to uniquely identify a row in the relation';

CREATE OR REPLACE FUNCTION qgep_sys.if_modified_func() RETURNS TRIGGER AS $body$
DECLARE
    audit_row qgep_sys.logged_actions;
    include_values BOOLEAN;
    log_diffs BOOLEAN;
    h_old hstore;
    h_new hstore;
    excluded_cols text[] = ARRAY[]::text[];
BEGIN

    IF NOT (TG_WHEN IN ('AFTER' , 'INSTEAD OF')) THEN
        RAISE EXCEPTION 'qgep_sys.if_modified_func() may only run as an AFTER trigger';
    END IF;

    audit_row = ROW(
        NEXTVAL('qgep_sys.logged_actions_event_id_seq'), -- event_id
        TG_TABLE_SCHEMA::text,                        -- schema_name
        TG_TABLE_NAME::text,                          -- table_name
        TG_RELID,                                     -- relation OID for much quicker searches
        session_user::text,                           -- session_user_name
        current_timestamp,                            -- action_tstamp_tx
        statement_timestamp(),                        -- action_tstamp_stm
        clock_timestamp(),                            -- action_tstamp_clk
        txid_current(),                               -- transaction ID
        (SELECT setting FROM pg_settings WHERE name = 'application_name'),
        inet_client_addr(),                           -- client_addr
        inet_client_port(),                           -- client_port
        current_query(),                              -- top-level query or queries (if multistatement) from client
        substring(TG_OP,1,1),                         -- action
        NULL, NULL,                                   -- row_data, changed_fields
        'f'                                           -- statement_only
        );

    IF NOT TG_ARGV[0]::BOOLEAN IS DISTINCT FROM 'f'::BOOLEAN THEN
        audit_row.client_query = NULL;

    END IF;

    IF TG_ARGV[1] IS NOT NULL THEN
        excluded_cols = TG_ARGV[1]::text[];
    END IF;

    IF (TG_OP = 'UPDATE' AND TG_LEVEL = 'ROW') THEN
        h_old = hstore(OLD.*) - excluded_cols;
        audit_row.row_data = h_old;
        h_new = hstore(NEW.*)- excluded_cols;
        audit_row.changed_fields =  h_new - h_old;

        IF audit_row.changed_fields = hstore('') THEN
            -- All changed fields are ignored. Skip this update.
            RAISE WARNING '[qgep_sys.if_modified_func] - Trigger detected NULL hstore. ending';
            RETURN NULL;
        END IF;
  INSERT INTO qgep_sys.logged_actions VALUES (audit_row.*);
  RETURN NEW;

    ELSIF (TG_OP = 'DELETE' AND TG_LEVEL = 'ROW') THEN
        audit_row.row_data = hstore(OLD.*) - excluded_cols;
  INSERT INTO qgep_sys.logged_actions VALUES (audit_row.*);
        RETURN OLD;

    ELSIF (TG_OP = 'INSERT' AND TG_LEVEL = 'ROW') THEN
        audit_row.row_data = hstore(NEW.*) - excluded_cols;
  INSERT INTO qgep_sys.logged_actions VALUES (audit_row.*);
        RETURN NEW;

    ELSIF (TG_LEVEL = 'STATEMENT' AND TG_OP IN ('INSERT','UPDATE','DELETE','TRUNCATE')) THEN
        audit_row.statement_only = 't';
        INSERT INTO qgep_sys.logged_actions VALUES (audit_row.*);
  RETURN NULL;

    ELSE
        RAISE EXCEPTION USING MESSAGE = '[qgep_sys.if_modified_func] - Trigger func added as trigger for unhandled case: '||TG_OP||', '||TG_LEVEL;
        RETURN NEW;
    END IF;


END;
$body$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public;

CREATE OR REPLACE FUNCTION qgep_sys.audit_table(target_table regclass, audit_rows BOOLEAN, audit_query_text BOOLEAN, ignored_cols text[]) RETURNS void AS $body$
DECLARE
  stm_targets text = 'INSERT OR UPDATE OR DELETE OR TRUNCATE';
  _q_txt text;
  _ignored_cols_snip text = '';
BEGIN
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_row ON ' || target_table::text;
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_stm ON ' || target_table::text;

    IF audit_rows THEN
        IF array_length(ignored_cols,1) > 0 THEN
            _ignored_cols_snip = ', ' || quote_literal(ignored_cols);
        END IF;
        _q_txt = 'CREATE TRIGGER audit_trigger_row AFTER INSERT OR UPDATE OR DELETE ON ' ||
                 target_table::text ||
                 ' FOR EACH ROW EXECUTE PROCEDURE qgep_sys.if_modified_func(' ||
                 quote_literal(audit_query_text) || _ignored_cols_snip || ');';
        RAISE NOTICE '%%',_q_txt;
        EXECUTE _q_txt;
        stm_targets = 'TRUNCATE';
    ELSE
    END IF;

    _q_txt = 'CREATE TRIGGER audit_trigger_stm AFTER ' || stm_targets || ' ON ' ||
             target_table ||
             ' FOR EACH STATEMENT EXECUTE PROCEDURE qgep_sys.if_modified_func('||
             quote_literal(audit_query_text) || ');';
    RAISE NOTICE '%%',_q_txt;
    EXECUTE _q_txt;

    -- store primary key names
    insert into qgep_sys.logged_relations (relation_name, uid_column)
         select target_table, a.attname
           from pg_index i
           join pg_attribute a on a.attrelid = i.indrelid
                              and a.attnum = any(i.indkey)
          where i.indrelid = target_table::regclass
            and i.indisprimary
          on conflict do nothing;
END;
$body$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION qgep_sys.audit_table(target_table regclass) RETURNS void AS $body$
SELECT qgep_sys.audit_table($1, BOOLEAN 't', BOOLEAN 't');
$body$ LANGUAGE 'sql';

COMMENT ON FUNCTION qgep_sys.audit_table(regclass) IS $body$
Add auditing support to the given table. Row-level changes will be logged with full client query text. No cols are ignored.
$body$;

CREATE OR REPLACE FUNCTION qgep_sys.unaudit_table(target_table regclass) RETURNS void AS $body$
BEGIN
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_row ON ' || target_table::text;
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_stm ON ' || target_table::text;
END;
$body$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION qgep_sys.replay_event(pevent_id int) RETURNS void AS $body$
DECLARE
  query text;
BEGIN
    with
    event as (
        select * from qgep_sys.logged_actions where event_id = pevent_id
    )
    -- get primary key names
    , where_pks as (
        select array_to_string(array_agg(uid_column || '=' || quote_literal(row_data->uid_column)), ' AND ') as where_clause
          from qgep_sys.logged_relations r
          join event on relation_name = (schema_name || '.' || table_name)
    )
    select into query
        case
            when action = 'I' then
                'INSERT INTO ' || schema_name || '.' || table_name ||
                ' ('||(select string_agg(key, ',') from each(row_data))||') VALUES ' ||
                '('||(select string_agg(case when value is null then 'null' else quote_literal(value) end, ',') from each(row_data))||')'
            when action = 'D' then
                'DELETE FROM ' || schema_name || '.' || table_name ||
                ' WHERE ' || where_clause
            when action = 'U' then
                'UPDATE ' || schema_name || '.' || table_name ||
                ' SET ' || (select string_agg(key || '=' || case when value is null then 'null' else quote_literal(value) end, ',') from each(changed_fields)) ||
                ' WHERE ' || where_clause
        end
    from
        event, where_pks
    ;

    execute query;
END;
$body$
LANGUAGE plpgsql;

COMMENT ON FUNCTION qgep_sys.replay_event(int) IS $body$
Replay a logged event.

Arguments:
   pevent_id:  The event_id of the event in qgep_sys.logged_actions to replay
$body$;

CREATE OR REPLACE FUNCTION qgep_sys.audit_view(target_view regclass, audit_query_text BOOLEAN, ignored_cols text[], uid_cols text[]) RETURNS void AS $body$
DECLARE
  stm_targets text = 'INSERT OR UPDATE OR DELETE';
  _q_txt text;
  _ignored_cols_snip text = '';

BEGIN
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_row ON ' || target_view::text;
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_stm ON ' || target_view::text;

	IF array_length(ignored_cols,1) > 0 THEN
	    _ignored_cols_snip = ', ' || quote_literal(ignored_cols);
	END IF;
	_q_txt = 'CREATE TRIGGER audit_trigger_row INSTEAD OF INSERT OR UPDATE OR DELETE ON ' ||
		 target_view::TEXT ||
		 ' FOR EACH ROW EXECUTE PROCEDURE qgep_sys.if_modified_func(' ||
		 quote_literal(audit_query_text) || _ignored_cols_snip || ');';
	RAISE NOTICE '%%',_q_txt;
	EXECUTE _q_txt;

    -- store uid columns if not already present
  IF (select count(*) from qgep_sys.logged_relations where relation_name = (select target_view)::text AND  uid_column= (select unnest(uid_cols))::text) = 0 THEN
      insert into qgep_sys.logged_relations (relation_name, uid_column)
       select target_view, unnest(uid_cols);
  END IF;

END;
$body$
LANGUAGE plpgsql;

COMMENT ON FUNCTION qgep_sys.audit_view(regclass, BOOLEAN, text[], text[]) IS $body$
ADD auditing support TO a VIEW.

Arguments:
   target_view:      TABLE name, schema qualified IF NOT ON search_path
   audit_query_text: Record the text of the client query that triggered the audit event?
   ignored_cols:     COLUMNS TO exclude FROM UPDATE diffs, IGNORE updates that CHANGE only ignored cols.
   uid_cols:         MANDATORY COLUMNS to use to uniquely identify a row from the view (in order to replay UPDATE and DELETE)

Example:
  SELECT qgep_sys.audit_view('qgep_od.vw_element_installation', 'true'::BOOLEAN, '{field_to_ignore}'::text[], '{key_field1, keyfield2}'::text[])
$body$;

CREATE OR REPLACE FUNCTION qgep_sys.unaudit_view(target_view regclass) RETURNS void AS $body$
BEGIN
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_row ON ' || target_view::text;
    EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_stm ON ' || target_view::text;
END;
$body$
LANGUAGE plpgsql;
