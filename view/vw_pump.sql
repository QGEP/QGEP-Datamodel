DROP VIEW IF EXISTS qgep.vw_pump;


--------
-- Subclass: od_pump
-- Superclass: od_overflow
--------
CREATE OR REPLACE VIEW qgep.vw_pump AS

SELECT
   PU.obj_id
   , PU.contruction_type
   , PU.operating_point
   , PU.placement_of_actuation
   , PU.placement_of_pump
   , PU.pump_flow_max_single
   , PU.pump_flow_min_single
   , PU.start_level
   , PU.stop_level
   , PU.usage_current
   , OF.actuation
   , OF.adjustability
   , OF.brand
   , OF.control
   , OF.discharge_point
   , OF.function
   , OF.gross_costs
   , OF.identifier
   , OF.qon_dim
   , OF.remark
   , OF.signal_transmission
   , OF.subsidies
   , OF.dataowner
   , OF.provider
   , OF.last_modification
  , OF.fk_wastewater_node
  , OF.fk_overflow_to
  , OF.fk_overflow_characteristic
  , OF.fk_control_center
  FROM qgep.od_pump PU
 LEFT JOIN qgep.od_overflow OF
 ON OF.obj_id = PU.obj_id;

-----------------------------------
-- pump INSERT
-- Function: vw_pump_insert()
-----------------------------------

CREATE OR REPLACE FUNCTION qgep.vw_pump_insert()
  RETURNS trigger AS
$BODY$
BEGIN
  INSERT INTO qgep.od_overflow (
             obj_id
           , actuation
           , adjustability
           , brand
           , control
           , discharge_point
           , function
           , gross_costs
           , identifier
           , qon_dim
           , remark
           , signal_transmission
           , subsidies
           , dataowner
           , provider
           , last_modification
           , fk_wastewater_node
           , fk_overflow_to
           , fk_overflow_characteristic
           , fk_control_center
           )
     VALUES ( COALESCE(NEW.obj_id,qgep.generate_oid('od_pump')) -- obj_id
           , NEW.actuation
           , NEW.adjustability
           , NEW.brand
           , NEW.control
           , NEW.discharge_point
           , NEW.function
           , NEW.gross_costs
           , NEW.identifier
           , NEW.qon_dim
           , NEW.remark
           , NEW.signal_transmission
           , NEW.subsidies
           , NEW.dataowner
           , NEW.provider
           , NEW.last_modification
           , NEW.fk_wastewater_node
           , NEW.fk_overflow_to
           , NEW.fk_overflow_characteristic
           , NEW.fk_control_center
           )
           RETURNING obj_id INTO NEW.obj_id;

INSERT INTO qgep.od_pump (
             obj_id
           , contruction_type
           , operating_point
           , placement_of_actuation
           , placement_of_pump
           , pump_flow_max_single
           , pump_flow_min_single
           , start_level
           , stop_level
           , usage_current
           )
          VALUES (
            NEW.obj_id -- obj_id
           , NEW.contruction_type
           , NEW.operating_point
           , NEW.placement_of_actuation
           , NEW.placement_of_pump
           , NEW.pump_flow_max_single
           , NEW.pump_flow_min_single
           , NEW.start_level
           , NEW.stop_level
           , NEW.usage_current
           );
  RETURN NEW;
END; $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- DROP TRIGGER vw_pump_ON_INSERT ON qgep.pump;

CREATE TRIGGER vw_pump_ON_INSERT INSTEAD OF INSERT ON qgep.vw_pump
  FOR EACH ROW EXECUTE PROCEDURE qgep.vw_pump_insert();

-----------------------------------
-- pump UPDATE
-- Rule: vw_pump_ON_UPDATE()
-----------------------------------

CREATE OR REPLACE RULE vw_pump_ON_UPDATE AS ON UPDATE TO qgep.vw_pump DO INSTEAD (
UPDATE qgep.od_pump
  SET
       contruction_type = NEW.contruction_type
     , operating_point = NEW.operating_point
     , placement_of_actuation = NEW.placement_of_actuation
     , placement_of_pump = NEW.placement_of_pump
     , pump_flow_max_single = NEW.pump_flow_max_single
     , pump_flow_min_single = NEW.pump_flow_min_single
     , start_level = NEW.start_level
     , stop_level = NEW.stop_level
     , usage_current = NEW.usage_current
  WHERE obj_id = OLD.obj_id;

UPDATE qgep.od_overflow
  SET
       actuation = NEW.actuation
     , adjustability = NEW.adjustability
     , brand = NEW.brand
     , control = NEW.control
     , discharge_point = NEW.discharge_point
     , function = NEW.function
     , gross_costs = NEW.gross_costs
     , identifier = NEW.identifier
     , qon_dim = NEW.qon_dim
     , remark = NEW.remark
     , signal_transmission = NEW.signal_transmission
     , subsidies = NEW.subsidies
           , dataowner = NEW.dataowner
           , provider = NEW.provider
           , last_modification = NEW.last_modification
     , fk_wastewater_node = NEW.fk_wastewater_node
     , fk_overflow_to = NEW.fk_overflow_to
     , fk_overflow_characteristic = NEW.fk_overflow_characteristic
     , fk_control_center = NEW.fk_control_center
  WHERE obj_id = OLD.obj_id;
);

-----------------------------------
-- pump DELETE
-- Rule: vw_pump_ON_DELETE ()
-----------------------------------

CREATE OR REPLACE RULE vw_pump_ON_DELETE AS ON DELETE TO qgep.vw_pump DO INSTEAD (
  DELETE FROM qgep.od_pump WHERE obj_id = OLD.obj_id;
  DELETE FROM qgep.od_overflow WHERE obj_id = OLD.obj_id;
);

