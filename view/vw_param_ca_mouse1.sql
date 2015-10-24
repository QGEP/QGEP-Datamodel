DROP VIEW IF EXISTS qgep.vw_param_ca_mouse1;


--------
-- Subclass: od_param_ca_mouse1
-- Superclass: od_surface_runoff_parameters
--------
CREATE OR REPLACE VIEW qgep.vw_param_ca_mouse1 AS

SELECT
   PM.obj_id
   , PM.dry_wheather_flow
   , PM.flow_path_length
   , PM.flow_path_slope
   , PM.population_equivalent
   , PM.surface_ca_mouse
   , PM.usage
   , SR.evaporation_loss
   , SR.identifier
   , SR.infiltration_loss
   , SR.remark
   , SR.surface_storage
   , SR.wetting_loss
   , SR.dataowner
   , SR.provider
   , SR.last_modification
  , SR.fk_catchment_area
  FROM qgep.od_param_ca_mouse1 PM
 LEFT JOIN qgep.od_surface_runoff_parameters SR
 ON SR.obj_id = PM.obj_id;

-----------------------------------
-- param_ca_mouse1 INSERT
-- Function: vw_param_ca_mouse1_insert()
-----------------------------------

CREATE OR REPLACE FUNCTION qgep.vw_param_ca_mouse1_insert()
  RETURNS trigger AS
$BODY$
BEGIN
  INSERT INTO qgep.od_surface_runoff_parameters (
             obj_id
           , evaporation_loss
           , identifier
           , infiltration_loss
           , remark
           , surface_storage
           , wetting_loss
           , dataowner
           , provider
           , last_modification
           , fk_catchment_area
           )
     VALUES ( qgep.generate_oid('od_param_ca_mouse1') -- obj_id
           , NEW.evaporation_loss
           , NEW.identifier
           , NEW.infiltration_loss
           , NEW.remark
           , NEW.surface_storage
           , NEW.wetting_loss
           , NEW.dataowner
           , NEW.provider
           , NEW.last_modification
           , NEW.fk_catchment_area
           )
           RETURNING obj_id INTO NEW.obj_id;

INSERT INTO qgep.od_param_ca_mouse1 (
             obj_id
           , dry_wheather_flow
           , flow_path_length
           , flow_path_slope
           , population_equivalent
           , surface_ca_mouse
           , usage
           )
          VALUES (
            NEW.obj_id -- obj_id
           , NEW.dry_wheather_flow
           , NEW.flow_path_length
           , NEW.flow_path_slope
           , NEW.population_equivalent
           , NEW.surface_ca_mouse
           , NEW.usage
           );
  RETURN NEW;
END; $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- DROP TRIGGER vw_param_ca_mouse1_ON_INSERT ON qgep.param_ca_mouse1;

CREATE TRIGGER vw_param_ca_mouse1_ON_INSERT INSTEAD OF INSERT ON qgep.vw_param_ca_mouse1
  FOR EACH ROW EXECUTE PROCEDURE qgep.vw_param_ca_mouse1_insert();

-----------------------------------
-- param_ca_mouse1 UPDATE
-- Rule: vw_param_ca_mouse1_ON_UPDATE()
-----------------------------------

CREATE OR REPLACE RULE vw_param_ca_mouse1_ON_UPDATE AS ON UPDATE TO qgep.vw_param_ca_mouse1 DO INSTEAD (
UPDATE qgep.od_param_ca_mouse1
  SET
       dry_wheather_flow = NEW.dry_wheather_flow
     , flow_path_length = NEW.flow_path_length
     , flow_path_slope = NEW.flow_path_slope
     , population_equivalent = NEW.population_equivalent
     , surface_ca_mouse = NEW.surface_ca_mouse
     , usage = NEW.usage
  WHERE obj_id = OLD.obj_id;

UPDATE qgep.od_surface_runoff_parameters
  SET
       evaporation_loss = NEW.evaporation_loss
     , identifier = NEW.identifier
     , infiltration_loss = NEW.infiltration_loss
     , remark = NEW.remark
     , surface_storage = NEW.surface_storage
     , wetting_loss = NEW.wetting_loss
           , dataowner = NEW.dataowner
           , provider = NEW.provider
           , last_modification = NEW.last_modification
     , fk_catchment_area = NEW.fk_catchment_area
  WHERE obj_id = OLD.obj_id;
);

-----------------------------------
-- param_ca_mouse1 DELETE
-- Rule: vw_param_ca_mouse1_ON_DELETE ()
-----------------------------------

CREATE OR REPLACE RULE vw_param_ca_mouse1_ON_DELETE AS ON DELETE TO qgep.vw_param_ca_mouse1 DO INSTEAD (
  DELETE FROM qgep.od_param_ca_mouse1 WHERE obj_id = OLD.obj_id;
  DELETE FROM qgep.od_surface_runoff_parameters WHERE obj_id = OLD.obj_id;
);

