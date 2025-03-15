-- Data Cleaning & EDA Project using MySQL

-- Data Source: https://www.kaggle.com/datasets/mohammedarfathr/smartwatch-health-data-uncleaned

SELECT COUNT(*)
FROM smartwatch_health_data.unclean_smartwatch_health_data;

CREATE TABLE smartwatch_health_data_staging
LIKE smartwatch_health_data.unclean_smartwatch_health_data;

SELECT *
FROM smartwatch_health_data_staging;

INSERT smartwatch_health_data_staging
SELECT *
FROM unclean_smartwatch_health_data;

DROP TABLE smartwatch_health_data_staging;

-- What I will do:
-- 1. Remove Duplicates
-- 2. Standardize Data
-- 3. Look at Null values or Blank Values and remove them if necessary
-- 4. Do EDA 

-- Searching and remove duplicates
WITH all_same_duplicate AS 
(
	SELECT *,
	ROW_NUMBER() OVER(PARTITION BY `User ID`, `Heart Rate (BPM)`, `Blood Oxygen Level (%)`, `Step Count`, `Sleep Duration (hours)`, `Activity Level`,`Stress Level`) AS row_num
	FROM smartwatch_health_data_staging
)
SELECT *
FROM all_same_duplicate
WHERE row_num > 1;

-- There are some typos
SELECT `Activity Level`
FROM smartwatch_health_data_staging
GROUP BY `Activity Level`;

-- Fixing Activity Level
# 1. Highly_Active
SELECT `Activity Level`
FROM smartwatch_health_data_staging
GROUP BY `Activity Level`;

UPDATE smartwatch_health_data_staging
SET `Activity Level` = 'Highly Active'
WHERE `Activity Level` LIKE 'Highly%';

# 2. Seddentary
UPDATE smartwatch_health_data_staging
SET `Activity Level` = 'Sedentary'
WHERE `Activity Level` = 'Seddentary';

# 3. Actve
UPDATE smartwatch_health_data_staging
SET `Activity Level` = 'Active'
WHERE `Activity Level` LIKE 'Act%';

# 4. nan
UPDATE smartwatch_health_data_staging
SET `Activity Level` = NULL
WHERE `Activity Level` = 'nan';

-- Make a checkpoint just to be sure
CREATE TABLE smartwatch_health_data_staging2
LIKE smartwatch_health_data_staging;

INSERT smartwatch_health_data_staging2
SELECT *
FROM smartwatch_health_data_staging;

SELECT *
FROM smartwatch_health_data_staging2;

-- Changing Step Count from text to double
UPDATE smartwatch_health_data_staging2
SET `Step Count` = NULL
WHERE `Step Count` NOT REGEXP '^[0-9]+(\.[0-9]+)?$';

ALTER TABLE smartwatch_health_data_staging2
MODIFY COLUMN `Step Count` DOUBLE;

DESCRIBE smartwatch_health_data_staging2;

-- Checking NUMBER ROW (sleep dur, blood oxygen, heart rate)
DELIMITER $$
CREATE PROCEDURE see_not_number_row()
BEGIN
	SELECT DISTINCT `Sleep Duration (hours)`
	FROM smartwatch_health_data_staging2
	WHERE `Sleep Duration (hours)`
		NOT REGEXP '^[0-9]+(\.[0-9]+)?$';
	SELECT DISTINCT `Blood Oxygen Level (%)`
	FROM smartwatch_health_data_staging2
	WHERE `Blood Oxygen Level (%)`
		NOT REGEXP '^[0-9]+(\.[0-9]+)?$';
	SELECT DISTINCT `Heart Rate (BPM)`
	FROM smartwatch_health_data_staging2
	WHERE `Heart Rate (BPM)`
		NOT REGEXP '^[0-9]+(\.[0-9]+)?$';
	SELECT DISTINCT `User ID`
	FROM smartwatch_health_data_staging2
	WHERE `User ID`
		NOT REGEXP '^[0-9]+(\.[0-9]+)?$';
END $$
DELIMITER ;

CALL see_not_number_row();

UPDATE smartwatch_health_data_staging2
SET `Heart Rate (BPM)` = NULL
WHERE `Heart Rate (BPM)` NOT REGEXP '^[0-9]+(\.[0-9]+)?$';

UPDATE smartwatch_health_data_staging2
SET `Sleep Duration (hours)` = NULL
WHERE `Sleep Duration (hours)` NOT REGEXP '^[0-9]+(\.[0-9]+)?$';

-- See user id 
SELECT *
FROM smartwatch_health_data_staging2
WHERE `User ID` = ''
;

-- EDA
# Seeing data group by user ID (IGNORING blank user id)
SELECT `User ID`, 
ROUND(AVG(`Step Count`), 3) AS avg_step, 
ROUND(AVG(`Sleep Duration (hours)`), 3) AS avg_sleep_hours, 
ROUND(AVG(`Stress Level`), 3) AS stress_lvl, 
ROUND(AVG(`Blood Oxygen Level (%)`), 3) AS avg_blood_oxygen_percentage
FROM smartwatch_health_data_staging2
GROUP BY `User ID`
HAVING `User ID` != ''; 

# Seeing max and min step taken
SELECT ROUND(MAX(`Step Count`), 3) AS max_step, ROUND(MIN(`Step Count`), 3)
FROM smartwatch_health_data_staging2
WHERE `User ID` != '';

# Seeing max and min blood oxygen level
SELECT ROUND(MAX(`Blood Oxygen Level (%)`), 3) AS max_percent_oxy_lvl, ROUND(MIN(`Blood Oxygen Level (%)`), 3) AS min_percent_oxy_lvl
FROM smartwatch_health_data_staging2
WHERE `User ID` != '';

# Classify number of user id according to the activity level
SELECT COUNT(`User ID`) AS num_of_user, COUNT(`Activity Level`) AS num_of_user_in_activity_lvl, `Activity Level`
FROM smartwatch_health_data_staging2
WHERE `User ID` != ''
GROUP BY `Activity Level`
;

# If we assume that we only need rows with user ID in it
CREATE TABLE smartwatch_health_data_staging3
LIKE smartwatch_health_data_staging2;

SELECT *
FROM smartwatch_health_data_staging3;

INSERT smartwatch_health_data_staging3
SELECT *
FROM smartwatch_health_data_staging2;

DELETE FROM smartwatch_health_data_staging3
WHERE `User ID` = '';