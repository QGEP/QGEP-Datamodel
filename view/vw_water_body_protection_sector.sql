DROP VIEW IF EXISTS qgep.vw_water_body_protection_sector;


--------
-- Subclass: od_water_body_protection_sector
-- Superclass: od_zone
--------
CREATE OR REPLACE VIEW qgep.vw_water_body_protection_sector AS

SELECT
   PS.obj_id
   , PS.kind
   , PS.perimeter_geometry
   , ZO.identifier
   , ZO.remark
   , ZO.dataowner
   , ZO.provider
   , ZO.last_modification
  FROM qgep.od_water_body_protection_sector PS
 LEFT JOIN qgep.od_zone ZO
 ON ZO.obj_id = PS.obj_id;

-----------------------------------
-- water_body_protection_sector INSERT
-- Function: vw_water_body_protection_sector_insert()
-----------------------------------

CREATE OR REPLACE FUNCTION qgep.vw_water_body_protection_sector_insert()
  RETURNS trigger AS
$BODY$
BEGIN
  INSERT INTO qgep.od_zone (
             obj_id
           , identifier
           , remark
           , dataowner
           , provider
           , last_modification
           )
     VALUES ( COALESCE(NEW.obj_id,qgep.generate_oid('od_water_body_protection_sector')) -- obj_id
           , NEW.identifier
           , NEW.remark
           , NEW.dataowner
           , NEW.provider
           , NEW.last_modification
           )
           RETURNING obj_id INTO NEW.obj_id;

INSERT INTO qgep.od_water_body_protection_sector (
             obj_id
           , kind
           , perimeter_geometry
           )
          VALUES (
            NEW.obj_id -- obj_id
           , NEW.kind
           , NEW.perimeter_geometry
           );
  RETURN NEW;
END; $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- DROP TRIGGER vw_water_body_protection_sector_ON_INSERT ON qgep.water_body_protection_sector;

CREATE TRIGGER vw_water_body_protection_sector_ON_INSERT INSTEAD OF INSERT ON qgep.vw_water_body_protection_sector
  FOR EACH ROW EXECUTE PROCEDURE qgep.vw_water_body_protection_sector_insert();

-----------------------------------
-- water_body_protection_sector UPDATE
-- Rule: vw_water_body_protection_sector_ON_UPDATE()
-----------------------------------

CREATE OR REPLACE RULE vw_water_body_protection_sector_ON_UPDATE AS ON UPDATE TO qgep.vw_water_body_protection_sector DO INSTEAD (
UPDATE qgep.od_water_body_protection_sector
  SET
       kind = NEW.kind
     , perimeter_geometry = NEW.perimeter_geometry
  WHERE obj_id = OLD.obj_id;

UPDATE qgep.od_zone
  SET
       identifier = NEW.identifier
     , remark = NEW.remark
           , dataowner = NEW.dataowner
           , provider = NEW.provider
           , last_modification = NEW.last_modification
  WHERE obj_id = OLD.obj_id;
);

-----------------------------------
-- water_body_protection_sector DELETE
-- Rule: vw_water_body_protection_sector_ON_DELETE ()
-----------------------------------

CREATE OR REPLACE RULE vw_water_body_protection_sector_ON_DELETE AS ON DELETE TO qgep.vw_water_body_protection_sector DO INSTEAD (
  DELETE FROM qgep.od_water_body_protection_sector WHERE obj_id = OLD.obj_id;
  DELETE FROM qgep.od_zone WHERE obj_id = OLD.obj_id;
);

