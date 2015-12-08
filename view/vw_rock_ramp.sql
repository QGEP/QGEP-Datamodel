DROP VIEW IF EXISTS qgep.vw_rock_ramp;


--------
-- Subclass: od_rock_ramp
-- Superclass: od_water_control_structure
--------
CREATE OR REPLACE VIEW qgep.vw_rock_ramp AS

SELECT
   RR.obj_id
   , RR.stabilisation
   , RR.vertical_drop
   , CS.identifier
   , CS.remark,
CS.situation_geometry
   , CS.dataowner
   , CS.provider
   , CS.last_modification
  , CS.fk_water_course_segment
  FROM qgep.od_rock_ramp RR
 LEFT JOIN qgep.od_water_control_structure CS
 ON CS.obj_id = RR.obj_id;

-----------------------------------
-- rock_ramp INSERT
-- Function: vw_rock_ramp_insert()
-----------------------------------

CREATE OR REPLACE FUNCTION qgep.vw_rock_ramp_insert()
  RETURNS trigger AS
$BODY$
BEGIN
  INSERT INTO qgep.od_water_control_structure (
             obj_id
           , identifier
           , remark
            , situation_geometry
           , dataowner
           , provider
           , last_modification
           , fk_water_course_segment
           )
     VALUES ( COALESCE(NEW.obj_id,qgep.generate_oid('od_rock_ramp')) -- obj_id
           , NEW.identifier
           , NEW.remark
            , NEW.situation_geometry
           , NEW.dataowner
           , NEW.provider
           , NEW.last_modification
           , NEW.fk_water_course_segment
           )
           RETURNING obj_id INTO NEW.obj_id;

INSERT INTO qgep.od_rock_ramp (
             obj_id
           , stabilisation
           , vertical_drop
           )
          VALUES (
            NEW.obj_id -- obj_id
           , NEW.stabilisation
           , NEW.vertical_drop
           );
  RETURN NEW;
END; $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- DROP TRIGGER vw_rock_ramp_ON_INSERT ON qgep.rock_ramp;

CREATE TRIGGER vw_rock_ramp_ON_INSERT INSTEAD OF INSERT ON qgep.vw_rock_ramp
  FOR EACH ROW EXECUTE PROCEDURE qgep.vw_rock_ramp_insert();

-----------------------------------
-- rock_ramp UPDATE
-- Rule: vw_rock_ramp_ON_UPDATE()
-----------------------------------

CREATE OR REPLACE RULE vw_rock_ramp_ON_UPDATE AS ON UPDATE TO qgep.vw_rock_ramp DO INSTEAD (
UPDATE qgep.od_rock_ramp
  SET
       stabilisation = NEW.stabilisation
     , vertical_drop = NEW.vertical_drop
  WHERE obj_id = OLD.obj_id;

UPDATE qgep.od_water_control_structure
  SET
       identifier = NEW.identifier
     , remark = NEW.remark
      , situation_geometry = NEW.situation_geometry
           , dataowner = NEW.dataowner
           , provider = NEW.provider
           , last_modification = NEW.last_modification
     , fk_water_course_segment = NEW.fk_water_course_segment
  WHERE obj_id = OLD.obj_id;
);

-----------------------------------
-- rock_ramp DELETE
-- Rule: vw_rock_ramp_ON_DELETE ()
-----------------------------------

CREATE OR REPLACE RULE vw_rock_ramp_ON_DELETE AS ON DELETE TO qgep.vw_rock_ramp DO INSTEAD (
  DELETE FROM qgep.od_rock_ramp WHERE obj_id = OLD.obj_id;
  DELETE FROM qgep.od_water_control_structure WHERE obj_id = OLD.obj_id;
);

