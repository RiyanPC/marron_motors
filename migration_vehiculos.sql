ALTER TABLE vehiculos
ADD COLUMN veh_foto VARCHAR(255) NULL
AFTER veh_color;

ALTER TABLE vehiculos ADD COLUMN veh_vin VARCHAR(100) NULL AFTER veh_color;