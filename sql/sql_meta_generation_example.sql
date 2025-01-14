-- !preview conn=con

CREATE TABLE mtcars_meta (
    table_name VARCHAR(255),
    column_name VARCHAR(255),
    description TEXT,
    data_type VARCHAR(255),
    levels TEXT[], -- For categorical columns like 'vs', 'am', 'gear', etc.
    measurement_units VARCHAR(255),
    range_min DOUBLE PRECISION,
    range_max DOUBLE PRECISION,
    PRIMARY KEY (table_name, column_name)
);

-- Insert metadata for the mtcars_data table columns

INSERT INTO mtcars_metadata (table_name, column_name, description, data_type, levels, measurement_units, range_min, range_max)
VALUES
('mtcars_data', 'mpg', 'Miles per gallon of the car.', 'DOUBLE PRECISION', NULL, 'miles/gallon', 10.0, 35.0),
('mtcars_data', 'cyl', 'Number of cylinders in the car engine.', 'INT', ARRAY['4', '6', '8'], NULL, 4, 8),
('mtcars_data', 'disp', 'Displacement of the car engine in cubic inches.', 'DOUBLE PRECISION', NULL, 'cubic inches', 70.0, 500.0),
('mtcars_data', 'hp', 'Horsepower of the car engine.', 'INT', NULL, 'horsepower', 50, 500),
('mtcars_data', 'drat', 'Rear axle ratio.', 'DOUBLE PRECISION', NULL, NULL, 2.0, 4.0),
('mtcars_data', 'wt', 'Weight of the car in 1000 lbs.', 'DOUBLE PRECISION', NULL, '1000 lbs', 1.5, 5.5),
('mtcars_data', 'qsec', 'Quarter mile time in seconds.', 'DOUBLE PRECISION', NULL, 'seconds', 14.0, 20.0),
('mtcars_data', 'vs', 'Engine type (0 = V-shaped, 1 = straight).', 'INT', ARRAY['0', '1'], NULL, 0, 1),
('mtcars_data', 'am', 'Transmission type (0 = automatic, 1 = manual).', 'INT', ARRAY['0', '1'], NULL, 0, 1),
('mtcars_data', 'gear', 'Number of forward gears.', 'INT', ARRAY['3', '4', '5'], NULL, 3, 5),
('mtcars_data', 'carb', 'Number of carburetors.', 'INT', NULL, NULL, 1, 6);

