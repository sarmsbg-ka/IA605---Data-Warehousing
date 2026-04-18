-- These codes were written to assist a few of my peers who were facing issues with the ETL process.

-- DELETE
SELECT *
FROM DailyStoreSnapshot
WHERE CalendarKey = 4832;

-- DELETE
SELECT *
FROM OneWayProductCategoryAggregate
WHERE CalendarKey = 4832;

-- DELETE
SELECT *
FROM OneWayRegionAggregate
WHERE CalendarKey = 4832;

-- DELETE
SELECT *
FROM RevenueFactTable
WHERE CalendarKey = 4832;

-- DELETE
SELECT *
FROM IntermediateFactTable
WHERE FullDate = '2026-03-25';

-- update the "ExtractionTimestamp" and "f_loaded" columns in the fact table for existing rows
UPDATE dubek_ZAGIMORE_DS.RevenueFactTable
SET f_loaded = TRUE;

-- update the "ExtractionTimestamp" column in the fact table for existing rows
UPDATE dubek_ZAGIMORE_DS.RevenueFactTable
SET ExtractionTimestamp = '2026-03-18 16:10:27';


SELECT *
FROM dubek_ZAGIMORE_DS.RevenueFactTable
WHERE ExtractionTimestamp = '2026-04-01 17:13:38';

-- update the "ExtractionTimestamp" column in the fact table for existing rows
UPDATE dubek_ZAGIMORE_DS.RevenueFactTable
SET ExtractionTimestamp = '2026-03-30 19:27:58'
WHERE ExtractionTimestamp = '2026-04-01 17:13:38';


SELECT *
FROM RevenueFactTable
WHERE TID like 'N%';

-- DELETE
SELECT *
FROM RevenueFactTable
WHERE TID IN ("N013", "N014");

SELECT * FROM `CustomerDimension` ORDER BY `CustomerDimension`.`CustomerID`, `CustomerDimension`.`CustomerKey` ASC;

UPDATE `CustomerDimension` SET `DateValidUntil` = '2026-04-17', `CurrentStatus` = '0' WHERE `CustomerDimension`.`CustomerKey` = 17; 
UPDATE `CustomerDimension` SET `DateValidUntil` = '2026-04-17', `CurrentStatus` = '0' WHERE `CustomerDimension`.`CustomerKey` = 18; 
UPDATE `CustomerDimension` SET `DateValidUntil` = '2026-04-17', `CurrentStatus` = '0' WHERE `CustomerDimension`.`CustomerKey` = 19;

-- =========================================================================================================================
-- Lecture 04/14/2026: Naveen
-- Type-2 Changes for Customer Dimension
-- =========================================================================================================================

-- List of attributes in the Customer Dimension considered for Type-2 Changes
-- CustomerName
-- CustomerZip

ALTER TABLE valsanv_ZAGIMORE_DS.CustomerDimension
ADD DateValidFrom Date,
ADD DateValidUntil Date,
ADD CurrentStatus BOOLEAN;

UPDATE valsanv_ZAGIMORE_DS.CustomerDimension
SET DateValidFrom = '2013-01-01', DateValidUntil = '2035-01-01', CurrentStatus = TRUE;

INSERT INTO valsanv_ZAGIMORE_DS.CustomerDimension (CustomerID, CustomerName, CustomerZip, ExtractionTimestamp, cd_loaded, DateValidFrom, DateValidUntil, CurrentStatus)
SELECT c.customerid, c.customername, c.customerzip, NOW(), FALSE, DATE(NOW()), '2035-01-01', TRUE
FROM valsanv_ZAGIMORE.customer c, valsanv_ZAGIMORE_DS.CustomerDimension cd
WHERE c.customerid = cd.CustomerID
AND cd.CurrentStatus = TRUE
AND (c.customername != cd.CustomerName OR c.customerzip != cd.CustomerZip);

-- track the update made on the customer table in ZAGIMORE, like
-- UPDATE `customer` SET `customerzip` = '66666' WHERE `customer`.`customerid` = '2-3-444';
-- track one record each for change in name, zip, and both

-- check the updated values in the Customer Dimension
SELECT cd.CustomerKey, cd.CustomerID, cd.CustomerName, cd.CustomerZip, cd.DateValidFrom, cd.DateValidUntil, cd.CurrentStatus
FROM valsanv_ZAGIMORE.customer c, valsanv_ZAGIMORE_DS.CustomerDimension cd
WHERE c.customerid = cd.CustomerID
AND cd.CurrentStatus = TRUE
AND (c.customername != cd.CustomerName OR c.customerzip != cd.CustomerZip);

-- now perform the insert
-- if we use DATE(NOW()) instead of NOW() then the date will be truncated to the date part only

-- Loading the Customer Dimension in DW with all the changed rows and new rows from Customer Dimension in DS
REPLACE INTO valsanv_ZAGIMORE_DW.CustomerDimension (CustomerKey, CustomerID, CustomerName, CustomerZip, DateValidFrom, DateValidUntil, CurrentStatus)
SELECT cd.CustomerKey, cd.CustomerID, cd.CustomerName, cd.CustomerZip, cd.DateValidFrom, cd.DateValidUntil, cd.CurrentStatus
FROM valsanv_ZAGIMORE_DS.CustomerDimension cd;

SELECT cd1.CustomerKey, cd1.CustomerID, cd1.DateValidFrom, cd1.DateValidUntil, cd1.CurrentStatus, cd2.CustomerKey, cd2.CustomerID, cd2.DateValidFrom, cd2.DateValidUntil, cd2.CurrentStatus
FROM valsanv_ZAGIMORE_DS.CustomerDimension cd1, valsanv_ZAGIMORE_DS.CustomerDimension cd2
WHERE cd1.CustomerID = cd2.CustomerID
AND cd1.DateValidFrom < cd2.DateValidFrom
AND cd1.CurrentStatus = TRUE;

UPDATE valsanv_ZAGIMORE_DW.CustomerDimension cd1, valsanv_ZAGIMORE_DW.CustomerDimension cd2
SET cd1.DateValidUntil = DATE(NOW()) - INTERVAL 1 DAY, cd1.CurrentStatus = FALSE
WHERE cd1.CustomerID = cd2.CustomerID
AND cd1.DateValidFrom < cd2.DateValidFrom
AND cd1.CurrentStatus = TRUE;

-- In the particular version of MySQL, we need to drop the foreign key before we can make changes to the table

ALTER TABLE valsanv_ZAGIMORE_DW.RevenueFactTable
DROP Foreign Key RevenueFactTable_ibfk_4; -- get value from the DW structure

ALTER TABLE valsanv_ZAGIMORE_DW.OneWayProductCategoryAggregate
DROP Foreign Key OneWayProductCategoryAggregate_ibfk_1;

-- Loading the Customer Dimension in DW with all the changed rows and new rows from Customer Dimension in DS
REPLACE INTO valsanv_ZAGIMORE_DW.CustomerDimension (CustomerKey, CustomerID, CustomerName, CustomerZip, DateValidFrom, DateValidUntil, CurrentStatus)
SELECT cd.CustomerKey, cd.CustomerID, cd.CustomerName, cd.CustomerZip, cd.DateValidFrom, cd.DateValidUntil, cd.CurrentStatus
FROM valsanv_ZAGIMORE_DS.CustomerDimension cd;

ALTER TABLE valsanv_ZAGIMORE_DW.RevenueFactTable
ADD CONSTRAINT RevenueFactTable_ibfk_4 -- get value from the DW structure
FOREIGN KEY (CustomerKey) REFERENCES valsanv_ZAGIMORE_DW.CustomerDimension(CustomerKey);

ALTER TABLE valsanv_ZAGIMORE_DW.OneWayProductCategoryAggregate
ADD CONSTRAINT OneWayProductCategoryAggregate_ibfk_1
FOREIGN KEY (CustomerKey) REFERENCES valsanv_ZAGIMORE_DW.CustomerDimension(CustomerKey);

UPDATE valsanv_ZAGIMORE_DS.CustomerDimension
SET cd_loaded = TRUE
WHERE cd_loaded = FALSE;

-- Procedure to implement Customer Dimension Type-2 Changes
DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.customer_type2_refresh;

DELIMITER $$$

CREATE PROCEDURE valsanv_ZAGIMORE_DS.customer_type2_refresh()
BEGIN
-- write the code blocks here
END $$$

DELIMITER ;

-- Rithvik's code
CREATE PROCEDURE Customer_type2_refresh()
BEGIN
INSERT Into vemular_S26_ZAGIMORE_DS.Customer_Dimension(CustomerID,CustomerName,CustomerZip,Extraction_time_stamp,C_Loaded,DVF,DVU,CurrentStatus)
SELECT c.customerid,c.customername,c.customerzip,NOW(),False,NOW(),"2030-01-01",TRUE
From vemular_S26_ZAGIMORE.customer c, vemular_S26_ZAGIMORE_DS.Customer_Dimension cd
WHERE c.customerid=cd.CustomerID AND (c.customername<>cd.CustomerName OR c.customerzip<>cd.CustomerZip);
UPDATE vemular_S26_ZAGIMORE_DS.Customer_Dimension cd1,vemular_S26_ZAGIMORE_DS.Customer_Dimension cd2
SET cd1.DVU=DATE(NOW())-INTERVAL 1 DAY, cd1.CurrentStatus=FALSE
WHERE cd1.CustomerID=cd2.CustomerID AND cd1.DVF<cd2.DVF AND cd1.CurrentStatus=TRUE;
ALTER TABLE vemular_S26_ZAGIMORE_DW.Revenue_Fact
DROP FOREIGN KEY Revenue_Fact_ibfk_2;
ALTER TABLE vemular_S26_ZAGIMORE_DW.One_Way_Revenue_AGG_BY_Productcat
DROP FOREIGN KEY One_Way_Revenue_AGG_BY_Productcat_ibfk_1;
REPLACE INTO vemular_S26_ZAGIMORE_DW.Customer_Dimension(CustomerKey,CustomerID,CustomerName,CustomerZip,DVF,DVU,CurrentStatus)
SELECT CustomerKey,CustomerID,CustomerName,CustomerZip,DVF,DVU,CurrentStatus
FROM vemular_S26_ZAGIMORE_DS.Customer_Dimension;
ALTER TABLE vemular_S26_ZAGIMORE_DW.Revenue_Fact
ADD CONSTRAINT Revenue_Fact_ibfk_2
FOREIGN KEY (CustomerKey) REFERENCES vemular_S26_ZAGIMORE_DW.Customer_Dimension(CustomerKey);
ALTER TABLE vemular_S26_ZAGIMORE_DW.One_Way_Revenue_AGG_BY_Productcat
ADD CONSTRAINT One_Way_Revenue_AGG_BY_Productcat_ibfk_1
FOREIGN KEY (CustomerKey) REFERENCES vemular_S26_ZAGIMORE_DW.Customer_Dimension(CustomerKey);
UPDATE vemular_S26_ZAGIMORE_DS.Customer_Dimension
SET C_Loaded=TRUE
WHERE C_Loaded=FALSE;
END;

