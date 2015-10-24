DROP VIEW IF EXISTS qgep.vw_waste_water_treatment_plant;


--------
-- Subclass: od_waste_water_treatment_plant
-- Superclass: od_organisation
--------
CREATE OR REPLACE VIEW qgep.vw_waste_water_treatment_plant AS

SELECT
   TP.obj_id
   , TP.bod5
   , TP.cod
   , TP.elimination_cod
   , TP.elimination_n
   , TP.elimination_nh4
   , TP.elimination_p
   , TP.installation_number
   , TP.kind
   , TP.NH4
   , TP.start_year
   , OG.identifier
   , OG.remark
   , OG.uid
   , OG.dataowner
   , OG.provider
   , OG.last_modification
  FROM qgep.od_waste_water_treatment_plant TP
 LEFT JOIN qgep.od_organisation OG
 ON OG.obj_id = TP.obj_id;

-----------------------------------
-- waste_water_treatment_plant INSERT
-- Function: vw_waste_water_treatment_plant_insert()
-----------------------------------

CREATE OR REPLACE FUNCTION qgep.vw_waste_water_treatment_plant_insert()
  RETURNS trigger AS
$BODY$
BEGIN
  INSERT INTO qgep.od_organisation (
             obj_id
           , identifier
           , remark
           , uid
           , dataowner
           , provider
           , last_modification
           )
     VALUES ( qgep.generate_oid('od_waste_water_treatment_plant') -- obj_id
           , NEW.identifier
           , NEW.remark
           , NEW.uid
           , NEW.dataowner
           , NEW.provider
           , NEW.last_modification
           )
           RETURNING obj_id INTO NEW.obj_id;

INSERT INTO qgep.od_waste_water_treatment_plant (
             obj_id
           , bod5
           , cod
           , elimination_cod
           , elimination_n
           , elimination_nh4
           , elimination_p
           , installation_number
           , kind
           , NH4
           , start_year
           )
          VALUES (
            NEW.obj_id -- obj_id
           , NEW.bod5
           , NEW.cod
           , NEW.elimination_cod
           , NEW.elimination_n
           , NEW.elimination_nh4
           , NEW.elimination_p
           , NEW.installation_number
           , NEW.kind
           , NEW.NH4
           , NEW.start_year
           );
  RETURN NEW;
END; $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- DROP TRIGGER vw_waste_water_treatment_plant_ON_INSERT ON qgep.waste_water_treatment_plant;

CREATE TRIGGER vw_waste_water_treatment_plant_ON_INSERT INSTEAD OF INSERT ON qgep.vw_waste_water_treatment_plant
  FOR EACH ROW EXECUTE PROCEDURE qgep.vw_waste_water_treatment_plant_insert();

-----------------------------------
-- waste_water_treatment_plant UPDATE
-- Rule: vw_waste_water_treatment_plant_ON_UPDATE()
-----------------------------------

CREATE OR REPLACE RULE vw_waste_water_treatment_plant_ON_UPDATE AS ON UPDATE TO qgep.vw_waste_water_treatment_plant DO INSTEAD (
UPDATE qgep.od_waste_water_treatment_plant
  SET
       bod5 = NEW.bod5
     , cod = NEW.cod
     , elimination_cod = NEW.elimination_cod
     , elimination_n = NEW.elimination_n
     , elimination_nh4 = NEW.elimination_nh4
     , elimination_p = NEW.elimination_p
     , installation_number = NEW.installation_number
     , kind = NEW.kind
     , NH4 = NEW.NH4
     , start_year = NEW.start_year
  WHERE obj_id = OLD.obj_id;

UPDATE qgep.od_organisation
  SET
       identifier = NEW.identifier
     , remark = NEW.remark
     , uid = NEW.uid
           , dataowner = NEW.dataowner
           , provider = NEW.provider
           , last_modification = NEW.last_modification
  WHERE obj_id = OLD.obj_id;
);

-----------------------------------
-- waste_water_treatment_plant DELETE
-- Rule: vw_waste_water_treatment_plant_ON_DELETE ()
-----------------------------------

CREATE OR REPLACE RULE vw_waste_water_treatment_plant_ON_DELETE AS ON DELETE TO qgep.vw_waste_water_treatment_plant DO INSTEAD (
  DELETE FROM qgep.od_waste_water_treatment_plant WHERE obj_id = OLD.obj_id;
  DELETE FROM qgep.od_organisation WHERE obj_id = OLD.obj_id;
);

