-- =========================================================================================================================
-- Lecture 03/25/2026: Week 10 & 11 : ETL, Part 5 & 6
-- In class exercise narrative ETL part 2: dealing with new facts and changing dimensions
-- =========================================================================================================================

/* -- add columns "ExtractionTimestamp" and "f_loaded" to the fact table
ALTER TABLE RevenueFactTable
ADD COLUMN ExtractionTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN f_loaded BOOLEAN DEFAULT FALSE; */

-- version used by the Professor in class
-- add columns "ExtractionTimestamp" and "f_loaded" to the fact table
ALTER TABLE valsanv_ZAGIMORE_DS.RevenueFactTable
ADD COLUMN ExtractionTimestamp TIMESTAMP,
ADD COLUMN f_loaded BOOLEAN;

-- update the "ExtractionTimestamp" and "f_loaded" columns in the fact table for existing rows
UPDATE valsanv_ZAGIMORE_DS.RevenueFactTable
SET f_loaded = TRUE;

-- update the "ExtractionTimestamp" column in the fact table for existing rows
UPDATE valsanv_ZAGIMORE_DS.RevenueFactTable
SET ExtractionTimestamp = NOW() - INTERVAL (7) DAY;

-- Creating new instances of operational data: new sales transaction

-- Create one new sales transaction record in the salestransaction table of the ZAGIMORE  operational database.
INSERT INTO valsanv_ZAGIMORE.salestransaction (tid, tdate, customerid, storeid)
VALUES ("N001", '2026-03-25', "8-9-000", "S7");

-- Create two new records in the sold_via table for that new transaction, showing purchases of two products 
INSERT INTO valsanv_ZAGIMORE.soldvia (productid, tid, noofitems)
VALUES ("1X1", "N001", 3), ("1X2", "N001", 5);

-- =========================================================================================================================
-- Lecture 03/30/2026: Week 10 & 11 : ETL, Part 5 & 6
-- In class exercise narrative ETL part 2: dealing with new facts and changing dimensions - Continued
-- =========================================================================================================================

-- Creating new instances of operational data: new rental transaction
INSERT INTO valsanv_ZAGIMORE.rentaltransaction (tid, tdate, customerid, storeid) VALUES ("N002", '2026-03-25', "8-9-000", "S3");
INSERT INTO valsanv_ZAGIMORE.rentvia (productid, tid, rentaltype, duration) VALUES ("1X1", "N002", "D", 5);
INSERT INTO valsanv_ZAGIMORE.rentvia (productid, tid, rentaltype, duration) VALUES ("2X2", "N002", "W", 5);

/* -- Check the data in the valsanv_ZAGIMORE_DS.RevenueFactTable table for the Daily refresh of fact table, sales txns and rental txns
-- we're modifying and using the same query we used for initial load of the intermediate fact table. This time we have to filter out the records that are already in the fact table. We'll do that using the ExtractionTimestamp column
SELECT sv.noofitems * p.productprice AS DollarAmount, "Sale" AS RevenueSource, sv.tid, p.productid, s.storeid, s.tdate AS FullDate, s.customerid
FROM valsanv_ZAGIMORE.soldvia as sv, valsanv_ZAGIMORE.product p, valsanv_ZAGIMORE.salestransaction s
WHERE sv.productid = p.productid 
AND sv.tid = s.tid
AND s.tdate > (SELECT MAX(ExtractionTimestamp) FROM valsanv_ZAGIMORE_DS.RevenueFactTable) -- filter out the records that are already in the fact table
UNION
SELECT rv.duration * r.productpricedaily AS DollarAmount, "Rental_Daily" AS RevenueSource, rv.tid, r.productid, rt.storeid, rt.tdate AS FullDate, rt.customerid
FROM valsanv_ZAGIMORE.rentvia as rv, valsanv_ZAGIMORE.rentalProducts as r, valsanv_ZAGIMORE.rentaltransaction rt
WHERE rv.productid = r.productid 
AND rv.tid = rt.tid
AND rv.rentaltype = "D"
AND rt.tdate > (SELECT MAX(ExtractionTimestamp) FROM valsanv_ZAGIMORE_DS.RevenueFactTable) -- filter out the records that are already in the fact table
UNION
SELECT rv.duration * r.productpriceweekly AS DollarAmount, "Rental_Weekly" AS RevenueSource, rv.tid, r.productid, rt.storeid, rt.tdate AS FullDate, rt.customerid
FROM valsanv_ZAGIMORE.rentvia as rv, valsanv_ZAGIMORE.rentalProducts as r, valsanv_ZAGIMORE.rentaltransaction rt
WHERE rv.productid = r.productid 
AND rv.tid = rt.tid
AND rv.rentaltype = "W"
AND rt.tdate > (SELECT MAX(ExtractionTimestamp) FROM valsanv_ZAGIMORE_DS.RevenueFactTable) -- filter out the records that are already in the fact table */
-- We don't have to execute this select query once we automate the ETL process. This was just to check the data ourselves.

-- Now we can "update/refresh" our valsanv_ZAGIMORE_DS.IntermediateFactTable with only the new facts
DROP TABLE IF EXISTS valsanv_ZAGIMORE_DS.IntermediateFactTable;
-- Create a new valsanv_ZAGIMORE_DS.IntermediateFactTable
CREATE TABLE IF NOT EXISTS valsanv_ZAGIMORE_DS.IntermediateFactTable AS
-- Using the same SELECT query we used above to check the data
SELECT sv.noofitems * p.productprice AS DollarAmount, "Sale" AS RevenueSource, sv.tid, p.productid, s.storeid, s.tdate AS FullDate, s.customerid
FROM valsanv_ZAGIMORE.soldvia as sv, valsanv_ZAGIMORE.product p, valsanv_ZAGIMORE.salestransaction s
WHERE sv.productid = p.productid 
AND sv.tid = s.tid
AND s.tdate > (SELECT MAX(ExtractionTimestamp) FROM valsanv_ZAGIMORE_DS.RevenueFactTable) -- filter out the records that are already in the fact table
UNION
SELECT rv.duration * r.productpricedaily AS DollarAmount, "Rental_Daily" AS RevenueSource, rv.tid, r.productid, rt.storeid, rt.tdate AS FullDate, rt.customerid
FROM valsanv_ZAGIMORE.rentvia as rv, valsanv_ZAGIMORE.rentalProducts as r, valsanv_ZAGIMORE.rentaltransaction rt
WHERE rv.productid = r.productid 
AND rv.tid = rt.tid
AND rv.rentaltype = "D"
AND rt.tdate > (SELECT MAX(ExtractionTimestamp) FROM valsanv_ZAGIMORE_DS.RevenueFactTable) -- filter out the records that are already in the fact table
UNION
SELECT rv.duration * r.productpriceweekly AS DollarAmount, "Rental_Weekly" AS RevenueSource, rv.tid, r.productid, rt.storeid, rt.tdate AS FullDate, rt.customerid
FROM valsanv_ZAGIMORE.rentvia as rv, valsanv_ZAGIMORE.rentalProducts as r, valsanv_ZAGIMORE.rentaltransaction rt
WHERE rv.productid = r.productid 
AND rv.tid = rt.tid
AND rv.rentaltype = "W"
AND rt.tdate > (SELECT MAX(ExtractionTimestamp) FROM valsanv_ZAGIMORE_DS.RevenueFactTable); -- filter out the records that are already in the fact table

/* Noticed that the collation of the RevenueSource column in the valsanv_ZAGIMORE_DS.IntermediateFactTable is utf8mb4_general_ci. Let's fix that. We need to change the collation of the RevenueSource column in the IntermediateFactTable to match the collation of the other columns, which is utf8mb4_0900_ai_ci 
We'll also adjust the data type of the RevenueSource column from VARCHAR(13) to VARCHAR(25). When we didn't specify a collation and the data type, the default collation was utf8mb4_general_ci and the data type was VARCHAR(13) derived from the length of the longest string in the column (Rental_Weekly) 
With this we match the collattion and data type of the RevenueSource column in the IntermediateFactTable with the collation and data type of the RevenueSource column in the RevenueFactTable. */
ALTER TABLE valsanv_ZAGIMORE_DS.IntermediateFactTable
MODIFY COLUMN RevenueSource VARCHAR(25) COLLATE utf8mb4_0900_ai_ci NOT NULL;

-- Now we'll populate the valsanv_ZAGIMORE_DS.RevenueFactTable with the new data from valsanv_ZAGIMORE_DS.IntermediateFactTable
-- Here we're using a modified version of the query we used for initial mapping of rows from intermediate fact table into the fact table
INSERT INTO valsanv_ZAGIMORE_DS.RevenueFactTable(DollarAmount, RevenueSource, TID, CustomerKey, StoreKey, CalendarKey, ProductKey, ExtractionTimestamp, f_loaded) -- added two columns "ExtractionTimestamp" and "f_loaded"
SELECT i.DollarAmount, i.RevenueSource, i.tid, cd.CustomerKey, sd.StoreKey, cad.CalendarKey, pd.ProductKey, NOW(), FALSE -- set f_loaded to FALSE. We can use FALSE or 0 to indicate that the data is not yet loaded
FROM valsanv_ZAGIMORE_DS.IntermediateFactTable AS i, valsanv_ZAGIMORE_DS.CustomerDimension AS cd, valsanv_ZAGIMORE_DS.StoreDimension AS sd, valsanv_ZAGIMORE_DS.CalendarDimension AS cad, valsanv_ZAGIMORE_DS.ProductDimension AS pd
WHERE cd.CustomerID = i.customerid
AND sd.StoreID = i.storeid
AND cad.FullDate = i.FullDate
AND pd.ProductID = i.productid
AND i.RevenueSource = "Sale" 
AND pd.ProductType = "S" -- we have same product IDs under two different product types
UNION
SELECT i.DollarAmount, i.RevenueSource, i.tid, cd.CustomerKey, sd.StoreKey, cad.CalendarKey, pd.ProductKey, NOW(), 0 -- set f_loaded to FALSE. We can use FALSE or 0 to indicate that the data is not yet loaded
FROM valsanv_ZAGIMORE_DS.IntermediateFactTable AS i, valsanv_ZAGIMORE_DS.CustomerDimension AS cd, valsanv_ZAGIMORE_DS.StoreDimension AS sd, valsanv_ZAGIMORE_DS.CalendarDimension AS cad, valsanv_ZAGIMORE_DS.ProductDimension AS pd
WHERE cd.CustomerID = i.customerid
AND sd.StoreID = i.storeid
AND cad.FullDate = i.FullDate
AND pd.ProductID = i.productid
AND i.RevenueSource IN ("Rental_Weekly", "Rental_Daily") 
AND pd.ProductType = "R"; -- we have same product IDs under two different product types


-- Load the new facts from valsanv_ZAGIMORE_DS.RevenueFactTable into valsanv_ZAGIMORE_DW.RevenueFactTable
INSERT INTO valsanv_ZAGIMORE_DW.RevenueFactTable (DollarAmount, RevenueSource, TID, ProductKey, StoreKey, CalendarKey, CustomerKey)
SELECT DollarAmount, RevenueSource, TID, ProductKey, StoreKey, CalendarKey, CustomerKey
FROM valsanv_ZAGIMORE_DS.RevenueFactTable
WHERE f_loaded = FALSE;
-- Update the f_loaded column in valsanv_ZAGIMORE_DS.RevenueFactTable to TRUE or 1 for the newly loaded facts to indicate that they have been loaded
UPDATE valsanv_ZAGIMORE_DS.RevenueFactTable
SET f_loaded = TRUE
WHERE f_loaded = FALSE;
-- Now we can drop our valsanv_ZAGIMORE_DS.IntermediateFactTable. This is just a temporary table, which we won't keep in a production environment
DROP TABLE IF EXISTS valsanv_ZAGIMORE_DS.IntermediateFactTable;

-- Why don't we truncate the valsanv_ZAGIMORE_DS.RevenueFactTable table after adding the new facts?
-- Because we want to keep the history of the ETL process. We want to keep a predefined number of days of the data in the table
-- Specifically, we want to handle late arrival of new data

-- =========================================================================================================================
-- Lecture 04/01/2026: Week 10 & 11 : ETL, Part 5 & 6
-- In class exercise narrative ETL part 2: dealing with new facts and changing dimensions - Continued
-- =========================================================================================================================

-- Create a procedure for daily fact refresh
DELIMITER $$$
CREATE PROCEDURE valsanv_ZAGIMORE_DS.daily_fact_refresh()
BEGIN
-- Now we can "update/refresh" our valsanv_ZAGIMORE_DS.IntermediateFactTable with only the new facts
DROP TABLE IF EXISTS valsanv_ZAGIMORE_DS.IntermediateFactTable;
-- Create a new valsanv_ZAGIMORE_DS.IntermediateFactTable
CREATE TABLE IF NOT EXISTS valsanv_ZAGIMORE_DS.IntermediateFactTable AS
-- Using the same SELECT query we used above to check the data
SELECT sv.noofitems * p.productprice AS DollarAmount, "Sale" AS RevenueSource, sv.tid, p.productid, s.storeid, s.tdate AS FullDate, s.customerid
FROM valsanv_ZAGIMORE.soldvia as sv, valsanv_ZAGIMORE.product p, valsanv_ZAGIMORE.salestransaction s
WHERE sv.productid = p.productid 
AND sv.tid = s.tid
AND s.tdate > (SELECT MAX(ExtractionTimestamp) FROM valsanv_ZAGIMORE_DS.RevenueFactTable) -- filter out the records that are already in the fact table
UNION
SELECT rv.duration * r.productpricedaily AS DollarAmount, "Rental_Daily" AS RevenueSource, rv.tid, r.productid, rt.storeid, rt.tdate AS FullDate, rt.customerid
FROM valsanv_ZAGIMORE.rentvia as rv, valsanv_ZAGIMORE.rentalProducts as r, valsanv_ZAGIMORE.rentaltransaction rt
WHERE rv.productid = r.productid 
AND rv.tid = rt.tid
AND rv.rentaltype = "D"
AND rt.tdate > (SELECT MAX(ExtractionTimestamp) FROM valsanv_ZAGIMORE_DS.RevenueFactTable) -- filter out the records that are already in the fact table
UNION
SELECT rv.duration * r.productpriceweekly AS DollarAmount, "Rental_Weekly" AS RevenueSource, rv.tid, r.productid, rt.storeid, rt.tdate AS FullDate, rt.customerid
FROM valsanv_ZAGIMORE.rentvia as rv, valsanv_ZAGIMORE.rentalProducts as r, valsanv_ZAGIMORE.rentaltransaction rt
WHERE rv.productid = r.productid 
AND rv.tid = rt.tid
AND rv.rentaltype = "W"
AND rt.tdate > (SELECT MAX(ExtractionTimestamp) FROM valsanv_ZAGIMORE_DS.RevenueFactTable); -- filter out the records that are already in the fact table

/* Noticed that the collation of the RevenueSource column in the valsanv_ZAGIMORE_DS.IntermediateFactTable is utf8mb4_general_ci. Let's fix that. We need to change the collation of the RevenueSource column in the IntermediateFactTable to match the collation of the other columns, which is utf8mb4_0900_ai_ci 
We'll also adjust the data type of the RevenueSource column from VARCHAR(13) to VARCHAR(25). When we didn't specify a collation and the data type, the default collation was utf8mb4_general_ci and the data type was VARCHAR(13) derived from the length of the longest string in the column (Rental_Weekly) 
With this we match the collattion and data type of the RevenueSource column in the IntermediateFactTable with the collation and data type of the RevenueSource column in the RevenueFactTable. */
ALTER TABLE valsanv_ZAGIMORE_DS.IntermediateFactTable
MODIFY COLUMN RevenueSource VARCHAR(25) COLLATE utf8mb4_0900_ai_ci NOT NULL;

-- Now we'll populate the valsanv_ZAGIMORE_DS.RevenueFactTable with the new data from valsanv_ZAGIMORE_DS.IntermediateFactTable
-- Here we're using a modified version of the query we used for initial mapping of rows from intermediate fact table into the fact table
INSERT INTO valsanv_ZAGIMORE_DS.RevenueFactTable(DollarAmount, RevenueSource, TID, CustomerKey, StoreKey, CalendarKey, ProductKey, ExtractionTimestamp, f_loaded) -- added two columns "ExtractionTimestamp" and "f_loaded"
SELECT i.DollarAmount, i.RevenueSource, i.tid, cd.CustomerKey, sd.StoreKey, cad.CalendarKey, pd.ProductKey, NOW(), FALSE -- set f_loaded to FALSE. We can use FALSE or 0 to indicate that the data is not yet loaded
FROM valsanv_ZAGIMORE_DS.IntermediateFactTable AS i, valsanv_ZAGIMORE_DS.CustomerDimension AS cd, valsanv_ZAGIMORE_DS.StoreDimension AS sd, valsanv_ZAGIMORE_DS.CalendarDimension AS cad, valsanv_ZAGIMORE_DS.ProductDimension AS pd
WHERE cd.CustomerID = i.customerid
AND sd.StoreID = i.storeid
AND cad.FullDate = i.FullDate
AND pd.ProductID = i.productid
AND i.RevenueSource = "Sale" 
AND pd.ProductType = "S" -- we have same product IDs under two different product types
UNION
SELECT i.DollarAmount, i.RevenueSource, i.tid, cd.CustomerKey, sd.StoreKey, cad.CalendarKey, pd.ProductKey, NOW(), 0 -- set f_loaded to FALSE. We can use FALSE or 0 to indicate that the data is not yet loaded
FROM valsanv_ZAGIMORE_DS.IntermediateFactTable AS i, valsanv_ZAGIMORE_DS.CustomerDimension AS cd, valsanv_ZAGIMORE_DS.StoreDimension AS sd, valsanv_ZAGIMORE_DS.CalendarDimension AS cad, valsanv_ZAGIMORE_DS.ProductDimension AS pd
WHERE cd.CustomerID = i.customerid
AND sd.StoreID = i.storeid
AND cad.FullDate = i.FullDate
AND pd.ProductID = i.productid
AND i.RevenueSource IN ("Rental_Weekly", "Rental_Daily") 
AND pd.ProductType = "R"; -- we have same product IDs under two different product types


-- Load the new facts from valsanv_ZAGIMORE_DS.RevenueFactTable into valsanv_ZAGIMORE_DW.RevenueFactTable
INSERT INTO valsanv_ZAGIMORE_DW.RevenueFactTable (DollarAmount, RevenueSource, TID, ProductKey, StoreKey, CalendarKey, CustomerKey)
SELECT DollarAmount, RevenueSource, TID, ProductKey, StoreKey, CalendarKey, CustomerKey
FROM valsanv_ZAGIMORE_DS.RevenueFactTable
WHERE f_loaded = FALSE;
-- Update the f_loaded column in valsanv_ZAGIMORE_DS.RevenueFactTable to TRUE or 1 for the newly loaded facts to indicate that they have been loaded
UPDATE valsanv_ZAGIMORE_DS.RevenueFactTable
SET f_loaded = TRUE
WHERE f_loaded = FALSE;
-- Now we can drop our valsanv_ZAGIMORE_DS.IntermediateFactTable. This is just a temporary table, which we won't keep in a production environment
DROP TABLE IF EXISTS valsanv_ZAGIMORE_DS.IntermediateFactTable;

END $$$
DELIMITER ;
-- after we execute this code in database, we'll see a new procedure is created. Now onwards, we'll use that procedure to perform the da

-- Let's insert some more new data into the ZAGIMORE operational database and test the ETL procedure
-- Creating new instances of operational data: new sales transaction
-- Create one new sales transaction record in the salestransaction table of the ZAGIMORE  operational database.
INSERT INTO valsanv_ZAGIMORE.salestransaction (tid, tdate, customerid, storeid)
VALUES ("N003", '2026-04-01', "8-9-000", "S7");

-- Create two new records in the sold_via table for that new transaction, showing purchases of two products 
INSERT INTO valsanv_ZAGIMORE.soldvia (productid, tid, noofitems)
VALUES ("1X1", "N003", 3), ("1X2", "N003", 5);

-- Creating new instances of operational data: new rental transaction
INSERT INTO valsanv_ZAGIMORE.rentaltransaction (tid, tdate, customerid, storeid) VALUES ("N004", '2026-04-01', "8-9-000", "S3");
INSERT INTO valsanv_ZAGIMORE.rentvia (productid, tid, rentaltype, duration) VALUES ("1X1", "N004", "D", 5);
INSERT INTO valsanv_ZAGIMORE.rentvia (productid, tid, rentaltype, duration) VALUES ("2X2", "N004", "W", 5);

-- Calling the ETL procedure
CALL valsanv_ZAGIMORE_DS.daily_fact_refresh();

-- Let's insert some more new data into the ZAGIMORE operational database and test the ETL procedure
-- Creating new instances of operational data: new sales transaction
-- Create one new sales transaction record in the salestransaction table of the ZAGIMORE  operational database.
INSERT INTO valsanv_ZAGIMORE.salestransaction (tid, tdate, customerid, storeid)
VALUES ("N005", '2026-04-01', "8-9-000", "S7");

-- Create two new records in the sold_via table for that new transaction, showing purchases of two products 
INSERT INTO valsanv_ZAGIMORE.soldvia (productid, tid, noofitems)
VALUES ("1X1", "N005", 3), ("1X2", "N005", 5);

-- Creating new instances of operational data: new rental transaction
INSERT INTO valsanv_ZAGIMORE.rentaltransaction (tid, tdate, customerid, storeid) VALUES ("N006", '2026-04-01', "8-9-000", "S3");
INSERT INTO valsanv_ZAGIMORE.rentvia (productid, tid, rentaltype, duration) VALUES ("1X1", "N006", "D", 5);
INSERT INTO valsanv_ZAGIMORE.rentvia (productid, tid, rentaltype, duration) VALUES ("2X2", "N006", "W", 5);

-- Creating procedure late_arriving_fact_refresh()
DELIMITER $$$
CREATE PROCEDURE valsanv_ZAGIMORE_DS.late_arriving_fact_refresh()
BEGIN
-- Now we can "update/refresh" our valsanv_ZAGIMORE_DS.IntermediateFactTable with only the new facts
DROP TABLE IF EXISTS valsanv_ZAGIMORE_DS.IntermediateFactTable;
-- Create a new valsanv_ZAGIMORE_DS.IntermediateFactTable
CREATE TABLE IF NOT EXISTS valsanv_ZAGIMORE_DS.IntermediateFactTable AS
-- Using the same SELECT query we used above to check the data
SELECT sv.noofitems * p.productprice AS DollarAmount, "Sale" AS RevenueSource, sv.tid, p.productid, s.storeid, s.tdate AS FullDate, s.customerid
FROM valsanv_ZAGIMORE.soldvia as sv, valsanv_ZAGIMORE.product p, valsanv_ZAGIMORE.salestransaction s
WHERE sv.productid = p.productid 
AND sv.tid = s.tid
AND s.tid NOT IN (SELECT DISTINCT tid FROM valsanv_ZAGIMORE_DS.RevenueFactTable) -- NOTE: now we're filtering using the tid column instead of the tdate column
UNION
SELECT rv.duration * r.productpricedaily AS DollarAmount, "Rental_Daily" AS RevenueSource, rv.tid, r.productid, rt.storeid, rt.tdate AS FullDate, rt.customerid
FROM valsanv_ZAGIMORE.rentvia as rv, valsanv_ZAGIMORE.rentalProducts as r, valsanv_ZAGIMORE.rentaltransaction rt
WHERE rv.productid = r.productid 
AND rv.tid = rt.tid
AND rv.rentaltype = "D"
AND rt.tid NOT IN (SELECT DISTINCT tid FROM valsanv_ZAGIMORE_DS.RevenueFactTable) -- filter out the records that are already in the fact table
UNION
SELECT rv.duration * r.productpriceweekly AS DollarAmount, "Rental_Weekly" AS RevenueSource, rv.tid, r.productid, rt.storeid, rt.tdate AS FullDate, rt.customerid
FROM valsanv_ZAGIMORE.rentvia as rv, valsanv_ZAGIMORE.rentalProducts as r, valsanv_ZAGIMORE.rentaltransaction rt
WHERE rv.productid = r.productid 
AND rv.tid = rt.tid
AND rv.rentaltype = "W"
AND rt.tid NOT IN (SELECT DISTINCT tid FROM valsanv_ZAGIMORE_DS.RevenueFactTable); -- filter out the records that are already in the fact table

/* Noticed that the collation of the RevenueSource column in the valsanv_ZAGIMORE_DS.IntermediateFactTable is utf8mb4_general_ci. Let's fix that. We need to change the collation of the RevenueSource column in the IntermediateFactTable to match the collation of the other columns, which is utf8mb4_0900_ai_ci 
We'll also adjust the data type of the RevenueSource column from VARCHAR(13) to VARCHAR(25). When we didn't specify a collation and the data type, the default collation was utf8mb4_general_ci and the data type was VARCHAR(13) derived from the length of the longest string in the column (Rental_Weekly) 
With this we match the collattion and data type of the RevenueSource column in the IntermediateFactTable with the collation and data type of the RevenueSource column in the RevenueFactTable. */
ALTER TABLE valsanv_ZAGIMORE_DS.IntermediateFactTable
MODIFY COLUMN RevenueSource VARCHAR(25) COLLATE utf8mb4_0900_ai_ci NOT NULL;

-- Now we'll populate the valsanv_ZAGIMORE_DS.RevenueFactTable with the new data from valsanv_ZAGIMORE_DS.IntermediateFactTable
-- Here we're using a modified version of the query we used for initial mapping of rows from intermediate fact table into the fact table
INSERT INTO valsanv_ZAGIMORE_DS.RevenueFactTable(DollarAmount, RevenueSource, TID, CustomerKey, StoreKey, CalendarKey, ProductKey, ExtractionTimestamp, f_loaded) -- added two columns "ExtractionTimestamp" and "f_loaded"
SELECT i.DollarAmount, i.RevenueSource, i.tid, cd.CustomerKey, sd.StoreKey, cad.CalendarKey, pd.ProductKey, NOW(), FALSE -- set f_loaded to FALSE. We can use FALSE or 0 to indicate that the data is not yet loaded
FROM valsanv_ZAGIMORE_DS.IntermediateFactTable AS i, valsanv_ZAGIMORE_DS.CustomerDimension AS cd, valsanv_ZAGIMORE_DS.StoreDimension AS sd, valsanv_ZAGIMORE_DS.CalendarDimension AS cad, valsanv_ZAGIMORE_DS.ProductDimension AS pd
WHERE cd.CustomerID = i.customerid
AND sd.StoreID = i.storeid
AND cad.FullDate = i.FullDate
AND pd.ProductID = i.productid
AND i.RevenueSource = "Sale" 
AND pd.ProductType = "S" -- we have same product IDs under two different product types
UNION
SELECT i.DollarAmount, i.RevenueSource, i.tid, cd.CustomerKey, sd.StoreKey, cad.CalendarKey, pd.ProductKey, NOW(), 0 -- set f_loaded to FALSE. We can use FALSE or 0 to indicate that the data is not yet loaded
FROM valsanv_ZAGIMORE_DS.IntermediateFactTable AS i, valsanv_ZAGIMORE_DS.CustomerDimension AS cd, valsanv_ZAGIMORE_DS.StoreDimension AS sd, valsanv_ZAGIMORE_DS.CalendarDimension AS cad, valsanv_ZAGIMORE_DS.ProductDimension AS pd
WHERE cd.CustomerID = i.customerid
AND sd.StoreID = i.storeid
AND cad.FullDate = i.FullDate
AND pd.ProductID = i.productid
AND i.RevenueSource IN ("Rental_Weekly", "Rental_Daily") 
AND pd.ProductType = "R"; -- we have same product IDs under two different product types


-- Load the new facts from valsanv_ZAGIMORE_DS.RevenueFactTable into valsanv_ZAGIMORE_DW.RevenueFactTable
INSERT INTO valsanv_ZAGIMORE_DW.RevenueFactTable (DollarAmount, RevenueSource, TID, ProductKey, StoreKey, CalendarKey, CustomerKey)
SELECT DollarAmount, RevenueSource, TID, ProductKey, StoreKey, CalendarKey, CustomerKey
FROM valsanv_ZAGIMORE_DS.RevenueFactTable
WHERE f_loaded = FALSE;
-- Update the f_loaded column in valsanv_ZAGIMORE_DS.RevenueFactTable to TRUE or 1 for the newly loaded facts to indicate that they have been loaded
UPDATE valsanv_ZAGIMORE_DS.RevenueFactTable
SET f_loaded = TRUE
WHERE f_loaded = FALSE;
-- Now we can drop our valsanv_ZAGIMORE_DS.IntermediateFactTable. This is just a temporary table, which we won't keep in a production environment
DROP TABLE IF EXISTS valsanv_ZAGIMORE_DS.IntermediateFactTable;
END $$$
DELIMITER ;

-- Calling the procedure
CALL valsanv_ZAGIMORE_DS.late_arriving_fact_refresh();

-- Sanity Check: t
SELECT COUNT(*)
FROM valsanv_ZAGIMORE.soldvia
UNION
SELECT COUNT(*)
FROM valsanv_ZAGIMORE.rentvia
UNION
SELECT COUNT(*)
FROM valsanv_ZAGIMORE_DS.RevenueFactTable
UNION
SELECT COUNT(*)
FROM valsanv_ZAGIMORE_DW.RevenueFactTable;


-- Let's insert some more new data into the ZAGIMORE operational database and test the ETL procedure
-- Creating new instances of operational data: new sales transaction
-- Create one new sales transaction record in the salestransaction table of the ZAGIMORE  operational database.
INSERT INTO valsanv_ZAGIMORE.salestransaction (tid, tdate, customerid, storeid)
VALUES ("N007", '2026-04-04', "8-9-000", "S7");

-- Create two new records in the sold_via table for that new transaction, showing purchases of two products 
INSERT INTO valsanv_ZAGIMORE.soldvia (productid, tid, noofitems)
VALUES ("1X1", "N007", 3), ("1X2", "N007", 5);

-- Creating new instances of operational data: new rental transaction
INSERT INTO valsanv_ZAGIMORE.rentaltransaction (tid, tdate, customerid, storeid) VALUES ("N008", '2026-04-04', "8-9-000", "S3");
INSERT INTO valsanv_ZAGIMORE.rentvia (productid, tid, rentaltype, duration) VALUES ("1X1", "N008", "D", 5);
INSERT INTO valsanv_ZAGIMORE.rentvia (productid, tid, rentaltype, duration) VALUES ("2X2", "N008", "W", 5);

-- Self: 04-05-2026
-- Modifying the sanity check query and making it a stored procedure. This will make it easier to perform the sanity check on a regular basis and confirm that the row counts are consistent.
DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.sp_validate_row_counts;

DELIMITER $$$

CREATE PROCEDURE valsanv_ZAGIMORE_DS.sp_validate_row_counts()
BEGIN
    SELECT 'soldvia' AS table_name, COUNT(*) AS row_count
    FROM valsanv_ZAGIMORE.soldvia

    UNION ALL

    SELECT 'rentvia', COUNT(*)
    FROM valsanv_ZAGIMORE.rentvia

    UNION ALL

    SELECT 'DS_RevenueFactTable', COUNT(*)
    FROM valsanv_ZAGIMORE_DS.RevenueFactTable

    UNION ALL

    SELECT 'DW_RevenueFactTable', COUNT(*)
    FROM valsanv_ZAGIMORE_DW.RevenueFactTable;
END$$$

DELIMITER ;

-- Create a stored procedure to validate the row counts in the source and destination tables
-- Note: This is an enhanced version of sp_validate_row_counts. The logic for both these stored procedures is valid only if RevenueFactTable is supposed to contain exactly one row for every row in soldvia and in rentvia tables. If our fact table grain is different, then row counts may not match even when the load is correct.
DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.sp_validate_row_counts_enhanced;

DELIMITER $$$

CREATE PROCEDURE valsanv_ZAGIMORE_DS.sp_validate_row_counts_enhanced()
BEGIN
    DECLARE soldvia_count INT DEFAULT 0;
    DECLARE rentvia_count INT DEFAULT 0;
    DECLARE src_count INT DEFAULT 0;
    DECLARE ds_count INT DEFAULT 0;
    DECLARE dw_count INT DEFAULT 0;

    SELECT COUNT(*) INTO soldvia_count
    FROM valsanv_ZAGIMORE.soldvia;

    SELECT COUNT(*) INTO rentvia_count
    FROM valsanv_ZAGIMORE.rentvia;

    SET src_count = soldvia_count + rentvia_count;

    SELECT COUNT(*) INTO ds_count
    FROM valsanv_ZAGIMORE_DS.RevenueFactTable;

    SELECT COUNT(*) INTO dw_count
    FROM valsanv_ZAGIMORE_DW.RevenueFactTable;

    SELECT 
        soldvia_count AS soldvia_rows,
        rentvia_count AS rentvia_rows,
        src_count AS source_total,
        ds_count AS ds_total,
        dw_count AS dw_total,
        (src_count - ds_count) AS source_minus_ds,
        (ds_count - dw_count) AS ds_minus_dw,
        CASE
            WHEN src_count = ds_count AND ds_count = dw_count THEN 'PASS'
            ELSE 'FAIL'
        END AS validation_status;
END$$$

DELIMITER ;

-- =========================================================================================================================
-- Lecture 04/06/2026: Week 10 & 11 : ETL, Part 5 & 6
-- In class exercise narrative ETL part 2: dealing with new facts and changing dimensions - Continued
-- =========================================================================================================================

-- Let's insert some more new data into the ZAGIMORE operational database and test the daily_fact_refresh ETL procedure
-- Creating new instances of operational data: new sales transaction
-- Create one new sales transaction record in the salestransaction table of the ZAGIMORE  operational database.
INSERT INTO valsanv_ZAGIMORE.salestransaction (tid, tdate, customerid, storeid)
VALUES ("N009", '2026-04-06', "8-9-000", "S7");

-- Create two new records in the sold_via table for that new transaction, showing purchases of two products 
INSERT INTO valsanv_ZAGIMORE.soldvia (productid, tid, noofitems)
VALUES ("1X1", "N009", 3), ("1X2", "N009", 5);

-- Creating new instances of operational data: new rental transaction
INSERT INTO valsanv_ZAGIMORE.rentaltransaction (tid, tdate, customerid, storeid) VALUES ("N010", '2026-04-06', "8-9-000", "S3");
INSERT INTO valsanv_ZAGIMORE.rentvia (productid, tid, rentaltype, duration) VALUES ("1X1", "N010", "D", 5);
INSERT INTO valsanv_ZAGIMORE.rentvia (productid, tid, rentaltype, duration) VALUES ("2X2", "N010", "W", 5);

-- Call the daily_fact_refresh ETL procedure
CALL valsanv_ZAGIMORE_DS.daily_fact_refresh();
-- Note: verify the results using the stored procedure sp_validate_row_counts_enhanced or sp_validate_row_counts

-- Let's insert some more new data into the ZAGIMORE operational database and test the late_arriving_fact_refresh ETL procedure
-- Creating new instances of operational data: new sales transaction
-- Create one new sales transaction record in the salestransaction table of the ZAGIMORE  operational database.
INSERT INTO valsanv_ZAGIMORE.salestransaction (tid, tdate, customerid, storeid)
VALUES ("N011", '2026-04-04', "8-9-000", "S7");

-- Create two new records in the sold_via table for that new transaction, showing purchases of two products 
INSERT INTO valsanv_ZAGIMORE.soldvia (productid, tid, noofitems)
VALUES ("1X1", "N011", 3), ("1X2", "N011", 5);

-- Creating new instances of operational data: new rental transaction
INSERT INTO valsanv_ZAGIMORE.rentaltransaction (tid, tdate, customerid, storeid) VALUES ("N012", '2026-04-04', "8-9-000", "S3");
INSERT INTO valsanv_ZAGIMORE.rentvia (productid, tid, rentaltype, duration) VALUES ("1X1", "N012", "D", 5);
INSERT INTO valsanv_ZAGIMORE.rentvia (productid, tid, rentaltype, duration) VALUES ("2X2", "N012", "W", 5);

-- Calling the late_arriving_fact_refresh ETL procedure
CALL valsanv_ZAGIMORE_DS.late_arriving_fact_refresh();
-- Note: verify the results using the stored procedure sp_validate_row_counts_enhanced or sp_validate_row_counts

-- 3. Appending  new dimension values to the the product dimension table in the next ETL cycle.
-- =========================================================================================================================

-- add columns "ExtractionTimestamp" and "pd_loaded" to the ProductDimension
ALTER TABLE valsanv_ZAGIMORE_DS.ProductDimension
ADD COLUMN ExtractionTimestamp TIMESTAMP,
ADD COLUMN pd_loaded BOOLEAN;

-- update the "pd_loaded" column in the ProductDimension for existing rows
UPDATE valsanv_ZAGIMORE_DS.ProductDimension
SET pd_loaded = TRUE;

-- update the "ExtractionTimestamp" column in the ProductDimension for existing rows
UPDATE valsanv_ZAGIMORE_DS.ProductDimension
SET ExtractionTimestamp = NOW() - INTERVAL (7) DAY;

-- 3-2. Create one more product in the product table of the ZAGIMORE operational database.
-- new product
INSERT INTO valsanv_ZAGIMORE.product ( productid, productname, productprice, vendorid, categoryid ) 
VALUES ( "1Y1", "Test Product", 250.00, "PG", "CL" );
-- new rental product
INSERT INTO valsanv_ZAGIMORE.rentalProducts ( productid, productname, productpricedaily, productpriceweekly, vendorid, categoryid ) 
VALUES ( "1Z1", "Test Rental Product", 25.00, 100.00, "PG", "CL" );

-- 03 - Product Dimension refresh code for both sale and rental products
INSERT INTO valsanv_ZAGIMORE_DS.ProductDimension (ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly, ExtractionTimestamp, pd_loaded)
SELECT p.productid, p.productname, p.vendorid, p.categoryid, v.vendorname, c.categoryname, "S", p.productprice, NULL, NULL, NOW(), FALSE
FROM valsanv_ZAGIMORE.product p
JOIN valsanv_ZAGIMORE.vendor v ON p.vendorid = v.vendorid
JOIN valsanv_ZAGIMORE.category c ON p.categoryid = c.categoryid
WHERE p.productid NOT IN (SELECT DISTINCT ProductID FROM valsanv_ZAGIMORE_DS.ProductDimension WHERE ProductType = "S") -- NOTE: now we're filtering using the tid column instead of the tdate column
UNION -- UNION keyword is used to combine the results of two queries into a single result set
SELECT r.productid, r.productname, r.vendorid, r.categoryid, v.vendorname, c.categoryname, "R", NULL, r.productpricedaily, r.productpriceweekly, NOW(), FALSE
FROM valsanv_ZAGIMORE.rentalProducts r
JOIN valsanv_ZAGIMORE.vendor v ON r.vendorid = v.vendorid
JOIN valsanv_ZAGIMORE.category c ON r.categoryid = c.categoryid
WHERE r.productid NOT IN (SELECT DISTINCT ProductID FROM valsanv_ZAGIMORE_DS.ProductDimension WHERE ProductType = "R");

-- Loading new instances of Products from DS to DW
INSERT INTO valsanv_ZAGIMORE_DW.ProductDimension (ProductKey, ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly)
SELECT ProductKey, ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly
FROM valsanv_ZAGIMORE_DS.ProductDimension
WHERE pd_loaded = FALSE;
-- Updating the "pd_loaded" column in the ProductDimension to show that the data has been loaded
UPDATE valsanv_ZAGIMORE_DS.ProductDimension
SET pd_loaded = TRUE
WHERE pd_loaded = FALSE;

-- new product
INSERT INTO valsanv_ZAGIMORE.product ( productid, productname, productprice, vendorid, categoryid ) 
VALUES ( "1Y2", "Test Product 02", 250.00, "PG", "CL" );
-- new rental product
INSERT INTO valsanv_ZAGIMORE.rentalProducts ( productid, productname, productpricedaily, productpriceweekly, vendorid, categoryid ) 
VALUES ( "1Z2", "Test Rental Product 02", 25.00, 100.00, "PG", "CL" );

-- Creating a procedure for Product refresh
DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.product_dimension_refresh;
DELIMITER $$$
CREATE PROCEDURE valsanv_ZAGIMORE_DS.product_dimension_refresh()
BEGIN
    -- 03 - Product Dimension refresh code for both sale and rental products
    INSERT INTO valsanv_ZAGIMORE_DS.ProductDimension (ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly, ExtractionTimestamp, pd_loaded)
    SELECT p.productid, p.productname, p.vendorid, p.categoryid, v.vendorname, c.categoryname, "S", p.productprice, NULL, NULL, NOW(), FALSE
    FROM valsanv_ZAGIMORE.product p
    JOIN valsanv_ZAGIMORE.vendor v ON p.vendorid = v.vendorid
    JOIN valsanv_ZAGIMORE.category c ON p.categoryid = c.categoryid
    WHERE p.productid NOT IN (SELECT DISTINCT ProductID FROM valsanv_ZAGIMORE_DS.ProductDimension WHERE ProductType = "S") -- NOTE: now we're filtering using the tid column instead of the tdate column
    UNION -- UNION keyword is used to combine the results of two queries into a single result set
    SELECT r.productid, r.productname, r.vendorid, r.categoryid, v.vendorname, c.categoryname, "R", NULL, r.productpricedaily, r.productpriceweekly, NOW(), FALSE
    FROM valsanv_ZAGIMORE.rentalProducts r
    JOIN valsanv_ZAGIMORE.vendor v ON r.vendorid = v.vendorid
    JOIN valsanv_ZAGIMORE.category c ON r.categoryid = c.categoryid
    WHERE r.productid NOT IN (SELECT DISTINCT ProductID FROM valsanv_ZAGIMORE_DS.ProductDimension WHERE ProductType = "R");

    -- Loading new instances of Products from DS to DW
    INSERT INTO valsanv_ZAGIMORE_DW.ProductDimension (ProductKey, ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly)
    SELECT ProductKey, ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly
    FROM valsanv_ZAGIMORE_DS.ProductDimension
    WHERE pd_loaded = FALSE;

    UPDATE valsanv_ZAGIMORE_DS.ProductDimension
    SET pd_loaded = TRUE
    WHERE pd_loaded = FALSE;
END$$$
DELIMITER ;

-- Calling the procedure
CALL valsanv_ZAGIMORE_DS.product_dimension_refresh();

-- new product
INSERT INTO valsanv_ZAGIMORE.product ( productid, productname, productprice, vendorid, categoryid ) 
VALUES ( "1Y3", "Test Product 03", 250.00, "PG", "CL" );
-- new rental product
INSERT INTO valsanv_ZAGIMORE.rentalProducts ( productid, productname, productpricedaily, productpriceweekly, vendorid, categoryid ) 
VALUES ( "1Z3", "Test Rental Product 03", 25.00, 100.00, "PG", "CL" );

-- Calling the procedure
CALL valsanv_ZAGIMORE_DS.product_dimension_refresh();

-- Self: 04-06-2026
-- Sanity check for product_dimension_refresh
-- Validates that row counts are consistent across the operational DB, DS, and DW for ProductDimension.
-- Note: This check is valid only when the grain of ProductDimension is one row per product per product type
-- (i.e., a product that exists as both Sale and Rental will appear as two rows in ProductDimension).
-- =========================================================================================================================

-- Creating the procedure
DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.sp_validate_product_dimension;

DELIMITER $$$

CREATE PROCEDURE valsanv_ZAGIMORE_DS.sp_validate_product_dimension()
BEGIN
    DECLARE sale_src_count INT DEFAULT 0;
    DECLARE rental_src_count INT DEFAULT 0;
    DECLARE src_total INT DEFAULT 0;
    DECLARE ds_sale_count INT DEFAULT 0;
    DECLARE ds_rental_count INT DEFAULT 0;
    DECLARE ds_total INT DEFAULT 0;
    DECLARE dw_sale_count INT DEFAULT 0;
    DECLARE dw_rental_count INT DEFAULT 0;
    DECLARE dw_total INT DEFAULT 0;

    -- Count sale and rental products in the operational DB
    SELECT COUNT(*) INTO sale_src_count
    FROM valsanv_ZAGIMORE.product;

    SELECT COUNT(*) INTO rental_src_count
    FROM valsanv_ZAGIMORE.rentalProducts;

    SET src_total = sale_src_count + rental_src_count;

    -- Count sale and rental products in the DS ProductDimension
    SELECT COUNT(*) INTO ds_sale_count
    FROM valsanv_ZAGIMORE_DS.ProductDimension
    WHERE ProductType = 'S';

    SELECT COUNT(*) INTO ds_rental_count
    FROM valsanv_ZAGIMORE_DS.ProductDimension
    WHERE ProductType = 'R';

    SET ds_total = ds_sale_count + ds_rental_count;

    -- Count sale and rental products in the DW ProductDimension
    SELECT COUNT(*) INTO dw_sale_count
    FROM valsanv_ZAGIMORE_DW.ProductDimension
    WHERE ProductType = 'S';

    SELECT COUNT(*) INTO dw_rental_count
    FROM valsanv_ZAGIMORE_DW.ProductDimension
    WHERE ProductType = 'R';

    SET dw_total = dw_sale_count + dw_rental_count;

    SELECT
        sale_src_count      AS src_sale_rows,
        rental_src_count    AS src_rental_rows,
        src_total           AS src_total,
        ds_sale_count       AS ds_sale_rows,
        ds_rental_count     AS ds_rental_rows,
        ds_total            AS ds_total,
        dw_sale_count       AS dw_sale_rows,
        dw_rental_count     AS dw_rental_rows,
        dw_total            AS dw_total,
        (src_total - ds_total)  AS source_minus_ds,
        (ds_total - dw_total)   AS ds_minus_dw,
        CASE
            WHEN src_total = ds_total AND ds_total = dw_total THEN 'PASS'
            ELSE 'FAIL'
        END AS validation_status;
END$$$

DELIMITER ;

-- Calling the procedure sp_validate_product_dimension to validate the data consistency for ProductDimension
CALL valsanv_ZAGIMORE_DS.sp_validate_product_dimension();

-- new product
INSERT INTO valsanv_ZAGIMORE.product ( productid, productname, productprice, vendorid, categoryid ) 
VALUES ( "1Y4", "Test Product 04", 250.00, "PG", "CL" );
-- new rental product
INSERT INTO valsanv_ZAGIMORE.rentalProducts ( productid, productname, productpricedaily, productpriceweekly, vendorid, categoryid ) 
VALUES ( "1Z4", "Test Rental Product 04", 25.00, 100.00, "PG", "CL" );

-- Note: Calling the procedure sp_validate_product_dimension right after the new data is inserted resulted in a FAIL status. Once the procedure product_dimension_refresh is called, the data consistency is restored as verified by sp_validate_product_dimension with PASS status

-- Homework: due on Wednesday, 04-08-2026
-- Create the ETL procedure for CustomerDimension refresh
-- =========================================================================================================================

-- Add control columns to DS CustomerDimension (mirrors the pattern used for ProductDimension and RevenueFactTable)
ALTER TABLE valsanv_ZAGIMORE_DS.CustomerDimension
ADD COLUMN ExtractionTimestamp TIMESTAMP,
ADD COLUMN cd_loaded BOOLEAN;

-- Mark all existing rows as already loaded into the DW
UPDATE valsanv_ZAGIMORE_DS.CustomerDimension
SET cd_loaded = TRUE;

-- Set ExtractionTimestamp for existing rows to simulate a past load
UPDATE valsanv_ZAGIMORE_DS.CustomerDimension
SET ExtractionTimestamp = NOW() - INTERVAL (14) DAY;

-- Creating a procedure for Customer Dimension refresh
DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.customer_dimension_refresh;

DELIMITER $$$

CREATE PROCEDURE valsanv_ZAGIMORE_DS.customer_dimension_refresh()
BEGIN
    -- Insert new customers from the operational DB that are not yet in the DS CustomerDimension
    INSERT INTO valsanv_ZAGIMORE_DS.CustomerDimension (CustomerID, CustomerName, CustomerZip, ExtractionTimestamp, cd_loaded)
    SELECT c.customerid, c.customername, c.customerzip, NOW(), FALSE
    FROM valsanv_ZAGIMORE.customer c
    WHERE c.customerid NOT IN (SELECT DISTINCT CustomerID FROM valsanv_ZAGIMORE_DS.CustomerDimension);

    -- Load new customers (cd_loaded = FALSE) from DS into the DW CustomerDimension
    INSERT INTO valsanv_ZAGIMORE_DW.CustomerDimension (CustomerKey, CustomerID, CustomerName, CustomerZip)
    SELECT CustomerKey, CustomerID, CustomerName, CustomerZip
    FROM valsanv_ZAGIMORE_DS.CustomerDimension
    WHERE cd_loaded = FALSE;

    -- Mark the newly loaded rows as loaded
    UPDATE valsanv_ZAGIMORE_DS.CustomerDimension
    SET cd_loaded = TRUE
    WHERE cd_loaded = FALSE;
END$$$

DELIMITER ;

-- Insert a new customer into the operational DB to test the procedure
INSERT INTO valsanv_ZAGIMORE.customer (customerid, customername, customerzip)
VALUES ("9-1-001", "Customer 001", "55499");

-- Calling the procedure
CALL valsanv_ZAGIMORE_DS.customer_dimension_refresh();

-- Sanity check for customer_dimension_refresh
-- Validates that row counts are consistent across the operational DB, DS, and DW for CustomerDimension.
-- =========================================================================================================================

DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.sp_validate_customer_dimension;

DELIMITER $$$

CREATE PROCEDURE valsanv_ZAGIMORE_DS.sp_validate_customer_dimension()
BEGIN
    DECLARE src_count INT DEFAULT 0;
    DECLARE ds_count INT DEFAULT 0;
    DECLARE dw_count INT DEFAULT 0;

    SELECT COUNT(*) INTO src_count
    FROM valsanv_ZAGIMORE.customer;

    SELECT COUNT(*) INTO ds_count
    FROM valsanv_ZAGIMORE_DS.CustomerDimension;

    SELECT COUNT(*) INTO dw_count
    FROM valsanv_ZAGIMORE_DW.CustomerDimension;

    SELECT
        src_count               AS src_rows,
        ds_count                AS ds_rows,
        dw_count                AS dw_rows,
        (src_count - ds_count)  AS source_minus_ds,
        (ds_count - dw_count)   AS ds_minus_dw,
        CASE
            WHEN src_count = ds_count AND ds_count = dw_count THEN 'PASS'
            ELSE 'FAIL'
        END AS validation_status;
END$$$

DELIMITER ;

-- Calling the procedure
CALL valsanv_ZAGIMORE_DS.sp_validate_customer_dimension();

-- Insert a new customer into the operational DB to test the procedure
INSERT INTO valsanv_ZAGIMORE.customer (customerid, customername, customerzip)
VALUES ("9-1-002", "Customer 002", "55499");

-- Calling the procedure
CALL valsanv_ZAGIMORE_DS.sp_validate_customer_dimension();

-- Calling the procedure
CALL valsanv_ZAGIMORE_DS.customer_dimension_refresh();

-- =========================================================================================================================
-- Lecture 04/08/2026: Week 10 & 11 : ETL, Part 5 & 6
-- In class exercise narrative ETL part 2: dealing with new facts and changing dimensions - Continued
-- =========================================================================================================================

-- new product
INSERT INTO valsanv_ZAGIMORE.product ( productid, productname, productprice, vendorid, categoryid ) 
VALUES ( "1Y5", "Test Product 05", 250.00, "PG", "CL" );
-- new rental product
INSERT INTO valsanv_ZAGIMORE.rentalProducts ( productid, productname, productpricedaily, productpriceweekly, vendorid, categoryid ) 
VALUES ( "1Z5", "Test Rental Product 05", 25.00, 100.00, "PG", "CL" );

-- Handling Type-2 Changes for Customer Dimension
-- Adding 3 Type-2 change tracking columns to the Customer Dimension in DS and setting their initial values
ALTER TABLE valsanv_ZAGIMORE_DS.CustomerDimension
ADD DateValidFrom Date,
ADD DateValidUntil Date,
ADD CurrentStatus BOOLEAN;

UPDATE valsanv_ZAGIMORE_DS.CustomerDimension
SET DateValidFrom = '2013-01-01', DateValidUntil = '2035-01-01', CurrentStatus = TRUE;

-- Adding 3 Type-2 change tracking columns to the Customer Dimension in DW and setting their initial values
ALTER TABLE valsanv_ZAGIMORE_DW.CustomerDimension
ADD DateValidFrom Date,
ADD DateValidUntil Date,
ADD CurrentStatus BOOLEAN;

UPDATE valsanv_ZAGIMORE_DW.CustomerDimension
SET DateValidFrom = '2013-01-01', DateValidUntil = '2035-01-01', CurrentStatus = TRUE;

UPDATE `customer` SET `customerzip` = '66666' WHERE `customer`.`customerid` = '2-3-444';

-- Check: Updating existing rows in the Product Dimension whose name or zipcode (or both) has changed by setting their DateValidUntil to yesterday's date and CurrentStatus to FALSE
SELECT cd.CustomerKey, cd.CustomerID, cd.CustomerName, cd.CustomerZip, cd.DateValidFrom, cd.DateValidUntil, cd.CurrentStatus
FROM valsanv_ZAGIMORE.customer c, valsanv_ZAGIMORE_DS.CustomerDimension cd
WHERE c.customerid = cd.CustomerID
AND (c.customername != cd.CustomerName OR c.customerzip != cd.CustomerZip);

-- Updating existing rows in the Customer Dimension whose name or zipcode (or both) has changed by setting their DateValidUntil to yesterday's date and CurrentStatus to FALSE
UPDATE valsanv_ZAGIMORE.customer c, valsanv_ZAGIMORE_DS.CustomerDimension cd
SET cd.DateValidUntil = NOW() - INTERVAL 1 DAY, cd.CurrentStatus = FALSE, cd_loaded = FALSE
WHERE c.customerid = cd.CustomerID
AND (c.customername != cd.CustomerName OR c.customerzip != cd.CustomerZip);


SELECT cd.CustomerKey, cd.CustomerID, cd.CustomerName, cd.CustomerZip, cd.DateValidFrom, cd.DateValidUntil, cd.CurrentStatus
FROM valsanv_ZAGIMORE.customer c, valsanv_ZAGIMORE_DS.CustomerDimension cd
WHERE c.customerid = cd.CustomerID
AND (c.customername != cd.CustomerName OR c.customerzip != cd.CustomerZip);

-- Inserting new rows in the Customer Dimension for those customers whose name, zipcode or both changed
INSERT INTO valsanv_ZAGIMORE_DS.CustomerDimension (CustomerID, CustomerName, CustomerZip, ExtractionTimestamp, cd_loaded, DateValidFrom, DateValidUntil, CurrentStatus)
SELECT c.customerid, c.customername, c.customerzip, NOW(), FALSE, NOW(), '2035-01-01', TRUE
FROM valsanv_ZAGIMORE.customer c, valsanv_ZAGIMORE_DS.CustomerDimension cd
WHERE c.customerid = cd.CustomerID
AND (c.customername != cd.CustomerName OR c.customerzip != cd.CustomerZip);

-- Loading the Customer Dimension in DW with all the changed rows and new rows from Customer Dimension in DS
REPLACE INTO valsanv_ZAGIMORE_DW.CustomerDimension (CustomerKey, CustomerID, CustomerName, CustomerZip, DateValidFrom, DateValidUntil, CurrentStatus)
SELECT CustomerKey, CustomerID, CustomerName, CustomerZip, DateValidFrom, DateValidUntil, CurrentStatus
FROM valsanv_ZAGIMORE_DS.CustomerDimension
WHERE cd_loaded = FALSE;

-- Drop foreign key - perform insert, then add back the foreign key
/* ALTER TABLE valsanv_ZAGIMORE_DW.CustomerDimension DROP FOREIGN KEY CustomerDimension_ibfk_1;
REPLACE INTO valsanv_ZAGIMORE_DW.CustomerDimension (CustomerKey, CustomerID, CustomerName, CustomerZip, DateValidFrom, DateValidUntil, CurrentStatus) */