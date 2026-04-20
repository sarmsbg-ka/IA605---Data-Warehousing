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
DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.daily_fact_refresh;
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
DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.late_arriving_fact_refresh;
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

-- 3 Changes in the Customer Table
UPDATE `customer` SET `customerzip` = '66666' WHERE `customer`.`customerid` = '2-3-444';
UPDATE `customer` SET `customername` = 'Norah' WHERE `customer`.`customerid` = '5-6-777';
UPDATE `customer` SET `customername` = 'Margaret', `customerzip` = '47411' WHERE `customer`.`customerid` = '8-9-000';

-- STEP 1: Insert new active row for changed customers (compare against CurrentStatus = TRUE only)
-- Pre-check: preview which customers will get a new row before running the INSERT
SELECT cd.CustomerKey, cd.CustomerID, cd.CustomerName, cd.CustomerZip, cd.DateValidFrom, cd.DateValidUntil, cd.CurrentStatus
FROM valsanv_ZAGIMORE.customer c, valsanv_ZAGIMORE_DS.CustomerDimension cd
WHERE c.customerid = cd.CustomerID
AND cd.CurrentStatus = TRUE
AND (c.customername != cd.CustomerName OR c.customerzip != cd.CustomerZip);

-- Insert the new active row first so the self-join in Step 2 can detect the old row
INSERT INTO valsanv_ZAGIMORE_DS.CustomerDimension (CustomerID, CustomerName, CustomerZip, ExtractionTimestamp, cd_loaded, DateValidFrom, DateValidUntil, CurrentStatus)
SELECT c.customerid, c.customername, c.customerzip, NOW(), FALSE, DATE(NOW()), '2035-01-01', TRUE
FROM valsanv_ZAGIMORE.customer c, valsanv_ZAGIMORE_DS.CustomerDimension cd
WHERE c.customerid = cd.CustomerID
AND cd.CurrentStatus = TRUE
AND (c.customername != cd.CustomerName OR c.customerzip != cd.CustomerZip);

-- STEP 2: Expire the old row via a self-join on CustomerKey
-- cd1 is the old row (lower auto-increment CustomerKey), cd2 is the new row just inserted above
-- WHY CustomerKey AND NOT DateValidFrom: DateValidFrom is date-only, so if a customer is loaded
-- and changed on the same calendar day both rows share the same date and the condition
-- cd1.DateValidFrom < cd2.DateValidFrom evaluates to FALSE -- old row never gets expired.
-- CustomerKey is auto-increment and strictly increases, so it reliably identifies the older row
-- regardless of when the change happens.
UPDATE valsanv_ZAGIMORE_DS.CustomerDimension cd1, valsanv_ZAGIMORE_DS.CustomerDimension cd2
SET cd1.DateValidUntil = DATE(NOW()) - INTERVAL 1 DAY, cd1.CurrentStatus = FALSE, cd1.cd_loaded = FALSE
WHERE cd1.CustomerID = cd2.CustomerID
AND cd1.CustomerKey < cd2.CustomerKey                                         -- cd1 is the older row (lower auto-increment key)
AND cd1.CurrentStatus = TRUE;

-- Loading the Customer Dimension in DW with all the changed rows and new rows from Customer Dimension in DS
REPLACE INTO valsanv_ZAGIMORE_DW.CustomerDimension (CustomerKey, CustomerID, CustomerName, CustomerZip, DateValidFrom, DateValidUntil, CurrentStatus)
SELECT CustomerKey, CustomerID, CustomerName, CustomerZip, DateValidFrom, DateValidUntil, CurrentStatus
FROM valsanv_ZAGIMORE_DS.CustomerDimension
WHERE cd_loaded = FALSE;

-- N.B.:
/* 
The above code block will not work in our verson of MySQL, it responds with the following error:

MySQL said:

#1451 - Cannot delete or update a parent row: a foreign key constraint fails (`valsanv_ZAGIMORE_DW`.`OneWayProductCategoryAggregate`, CONSTRAINT `OneWayProductCategoryAggregate_ibfk_1` FOREIGN KEY (`CustomerKey`) REFERENCES `CustomerDimension` (`CustomerKey`)) 

The error message above only mentions one foreign key constraint, but in fact we have 3 tables referencing CustomerKey from the
CustomerDimension table. They are 1) RevenueFactTable, 2) OneWayProductCategoryAggregate and 3) OneWayRegionAggregate. Because of how 
our version of MySQL works, we need to drop these foreign key references before we can make changes to the CustomerDimension table in DW.

So, we'll do it this way:
1) Drop the foreign key reference from the RevenueFactTable, OneWayProductCategoryAggregate and OneWayRegionAggregate tables
2) Make the changes to the CustomerDimension table in DW by running the above "REPLACE INTO" code block
3) Add back the foreign key references

Note that this is why in many production environments, we don't actually enforce foreign key constraints even in DW. They exist 
implicitly, but we don't enforce them. The ETL process in a production environment is that effiecient, so that there is no need to enforce them -- NOTHING CAN GO WRONG. But here, for pedagogical reasons, we enforce them.
*/

-- DO NOT RUN DAILY AND LATE FACT REFRESH WITHOUT ADJUSTING THE PROCEDURES FOR TYPE-2 CHANGES

-- =========================================================================================================================
-- Lecture 04/13/2026: Week 10 & 11 : ETL, Part 5 & 6
-- In class exercise narrative ETL part 2: dealing with new facts and changing dimensions - Continued
-- =========================================================================================================================

-- Customer row count check
DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.customer_row_count_check;

DELIMITER $$$
CREATE PROCEDURE valsanv_ZAGIMORE_DS.customer_row_count_check()
BEGIN
    SELECT COUNT(*), "SourceCustomerCount" 
    FROM valsanv_ZAGIMORE.customer
    UNION
    SELECT COUNT(*), "DS_CustomerCount" 
    FROM valsanv_ZAGIMORE_DS.CustomerDimension
    WHERE CurrentStatus = TRUE
END$$$

DELIMITER ;

-- update the code for valsanv_ZAGIMORE_DS.customer_dimension_refresh() to account for the Type-2 changes

-- 1) Drop the foreign key reference from the RevenueFactTable, OneWayProductCategoryAggregate and OneWayRegionAggregate tables
ALTER TABLE valsanv_ZAGIMORE_DW.RevenueFactTable
DROP Foreign Key RevenueFactTable_ibfk_4; -- get the value from the "Constraint properties" under the "Relation view" tab of the corrensponding table in the DW

ALTER TABLE valsanv_ZAGIMORE_DW.OneWayProductCategoryAggregate
DROP Foreign Key OneWayProductCategoryAggregate_ibfk_1;

ALTER TABLE valsanv_ZAGIMORE_DW.OneWayRegionAggregate
DROP Foreign Key OneWayRegionAggregate_ibfk_1;

-- 2) Make the changes to the CustomerDimension table in DW by running the above "REPLACE INTO" code block
-- Loading the Customer Dimension in DW with all the changed rows and new rows from Customer Dimension in DS
REPLACE INTO valsanv_ZAGIMORE_DW.CustomerDimension (CustomerKey, CustomerID, CustomerName, CustomerZip, DateValidFrom, DateValidUntil, CurrentStatus)
SELECT CustomerKey, CustomerID, CustomerName, CustomerZip, DateValidFrom, DateValidUntil, CurrentStatus
FROM valsanv_ZAGIMORE_DS.CustomerDimension
WHERE cd_loaded = FALSE;

-- 3) Add back the foreign key references
ALTER TABLE valsanv_ZAGIMORE_DW.RevenueFactTable
ADD CONSTRAINT RevenueFactTable_ibfk_4
FOREIGN KEY (CustomerKey) REFERENCES valsanv_ZAGIMORE_DW.CustomerDimension(CustomerKey);

ALTER TABLE valsanv_ZAGIMORE_DW.OneWayProductCategoryAggregate
ADD CONSTRAINT OneWayProductCategoryAggregate_ibfk_1
FOREIGN KEY (CustomerKey) REFERENCES valsanv_ZAGIMORE_DW.CustomerDimension(CustomerKey);

ALTER TABLE valsanv_ZAGIMORE_DW.OneWayRegionAggregate
ADD CONSTRAINT OneWayRegionAggregate_ibfk_1
FOREIGN KEY (CustomerKey) REFERENCES valsanv_ZAGIMORE_DW.CustomerDimension(CustomerKey);

-- 4) Update the cd_loaded column in the CustomerDimension table in DS
UPDATE valsanv_ZAGIMORE_DS.CustomerDimension
SET cd_loaded = TRUE
WHERE cd_loaded = FALSE;

-- Now we can wrap all the CustomerDimension type-2 changes into a single stored procedure
-- procedure for Customer Dimension Type-2 changes refresh
DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.customer_dimension_type2_refresh_ver1;

DELIMITER $$$

CREATE PROCEDURE valsanv_ZAGIMORE_DS.customer_dimension_type2_refresh_ver1()
BEGIN

    -- -------------------------------------------------------
    -- STEP 1: Expire the active DS row for changed customers
    -- -------------------------------------------------------
    -- For each customer whose name or zip now differs from the operational DB,
    -- close out their current row: set DateValidUntil to yesterday, flip
    -- CurrentStatus to FALSE, and mark cd_loaded = FALSE so the DW sync
    -- picks it up in Step 3.
    --
    -- WHY "AND cd.CurrentStatus = TRUE":
    --   Without this filter, historical rows (old name/zip still stored from
    --   prior SCD changes) would keep matching the WHERE clause on every run,
    --   causing the procedure to insert a new row every time it is called even
    --   when nothing actually changed. Filtering to only the active row makes
    --   the procedure idempotent (safe to run multiple times).
    UPDATE valsanv_ZAGIMORE.customer c, valsanv_ZAGIMORE_DS.CustomerDimension cd
    SET cd.DateValidUntil = DATE(NOW()) - INTERVAL 1 DAY, cd.CurrentStatus = FALSE, cd_loaded = FALSE
    WHERE c.customerid = cd.CustomerID
    AND cd.CurrentStatus = TRUE                                               -- only touch the live row, not historical ones
    AND (c.customername != cd.CustomerName OR c.customerzip != cd.CustomerZip);

    -- -------------------------------------------------------
    -- STEP 2: Insert new active DS row for changed customers
    -- -------------------------------------------------------
    -- After Step 1, any changed customer has NO row with CurrentStatus = TRUE.
    -- We insert a fresh row with today as DateValidFrom and a far-future
    -- DateValidUntil, representing the new "current" version of that customer.
    --
    -- HOW THE EXISTS / NOT EXISTS PATTERN WORKS:
    --   EXISTS(...)      → keeps only customers already in the dimension
    --                      (brand-new customers are handled by customer_dimension_refresh, not here)
    --   NOT EXISTS(... AND CurrentStatus = TRUE)
    --                    → keeps only customers with NO active row, i.e., those
    --                      whose row was just expired in Step 1
    --
    -- WHY "SELECT 1" inside EXISTS:
    --   EXISTS only checks whether the subquery returns at least one row; it
    --   never uses the actual value. Writing SELECT 1 (instead of SELECT *)
    --   signals that we only care about existence, not the data itself.
    INSERT INTO valsanv_ZAGIMORE_DS.CustomerDimension (CustomerID, CustomerName, CustomerZip, ExtractionTimestamp, cd_loaded, DateValidFrom, DateValidUntil, CurrentStatus)
    SELECT c.customerid, c.customername, c.customerzip, NOW(), FALSE, DATE(NOW()), '2035-01-01', TRUE
    FROM valsanv_ZAGIMORE.customer c
    WHERE EXISTS (
        SELECT 1 FROM valsanv_ZAGIMORE_DS.CustomerDimension cd
        WHERE cd.CustomerID = c.customerid          -- customer already exists in the dimension
    )
    AND NOT EXISTS (
        SELECT 1 FROM valsanv_ZAGIMORE_DS.CustomerDimension cd
        WHERE cd.CustomerID = c.customerid AND cd.CurrentStatus = TRUE  -- but has no active row (just expired)
    );

    -- -------------------------------------------------------
    -- STEP 3: Sync changed rows from DS into the DW
    -- -------------------------------------------------------
    -- Foreign keys on RevenueFactTable, OneWayProductCategoryAggregate, and
    -- OneWayRegionAggregate all point to DW.CustomerDimension. MySQL won't let
    -- us modify a referenced row while those constraints are active, so we
    -- drop them before the sync and re-add them after.
    --
    -- WHY REPLACE INTO (not INSERT):
    --   The expired old rows already exist in the DW with their CustomerKey.
    --   REPLACE INTO updates them in place (sets CurrentStatus = FALSE,
    --   DateValidUntil = yesterday) instead of inserting duplicates.
    --   The new active rows are brand-new CustomerKeys, so REPLACE INTO
    --   inserts them normally.

    -- 1) Drop FK constraints so we can modify CustomerDimension rows in the DW
    ALTER TABLE valsanv_ZAGIMORE_DW.RevenueFactTable
    DROP Foreign Key RevenueFactTable_ibfk_4;           -- FK value from: DW table → Relation view → Constraint properties

    ALTER TABLE valsanv_ZAGIMORE_DW.OneWayProductCategoryAggregate
    DROP Foreign Key OneWayProductCategoryAggregate_ibfk_1;

    ALTER TABLE valsanv_ZAGIMORE_DW.OneWayRegionAggregate
    DROP Foreign Key OneWayRegionAggregate_ibfk_1;

    -- 2) Push all unloaded DS rows (cd_loaded = FALSE) into the DW
    --    This covers both the expired old rows and the new active rows from Steps 1 & 2
    REPLACE INTO valsanv_ZAGIMORE_DW.CustomerDimension (CustomerKey, CustomerID, CustomerName, CustomerZip, DateValidFrom, DateValidUntil, CurrentStatus)
    SELECT CustomerKey, CustomerID, CustomerName, CustomerZip, DateValidFrom, DateValidUntil, CurrentStatus
    FROM valsanv_ZAGIMORE_DS.CustomerDimension
    WHERE cd_loaded = FALSE;

    -- 3) Restore the FK constraints
    ALTER TABLE valsanv_ZAGIMORE_DW.RevenueFactTable
    ADD CONSTRAINT RevenueFactTable_ibfk_4
    FOREIGN KEY (CustomerKey) REFERENCES valsanv_ZAGIMORE_DW.CustomerDimension(CustomerKey);

    ALTER TABLE valsanv_ZAGIMORE_DW.OneWayProductCategoryAggregate
    ADD CONSTRAINT OneWayProductCategoryAggregate_ibfk_1
    FOREIGN KEY (CustomerKey) REFERENCES valsanv_ZAGIMORE_DW.CustomerDimension(CustomerKey);

    ALTER TABLE valsanv_ZAGIMORE_DW.OneWayRegionAggregate
    ADD CONSTRAINT OneWayRegionAggregate_ibfk_1
    FOREIGN KEY (CustomerKey) REFERENCES valsanv_ZAGIMORE_DW.CustomerDimension(CustomerKey);

    -- -------------------------------------------------------
    -- STEP 4: Mark all synced DS rows as loaded
    -- -------------------------------------------------------
    -- Flip cd_loaded = TRUE for every row we just pushed to the DW,
    -- so they are not re-processed on the next ETL run.
    UPDATE valsanv_ZAGIMORE_DS.CustomerDimension
    SET cd_loaded = TRUE
    WHERE cd_loaded = FALSE;

END$$$

DELIMITER ;


-- =========================================================================================================================
-- Alternative Type-2 Customer Dimension refresh procedure using the peer's approach (vemular_S26).
-- Key difference from _ver1: INSERT the new row FIRST, then expire the old row via a self-join.
-- Both versions are idempotent and produce the same result; the logic order is reversed.
-- =========================================================================================================================

DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.customer_dimension_type2_refresh_ver2;

DELIMITER $$$

CREATE PROCEDURE valsanv_ZAGIMORE_DS.customer_dimension_type2_refresh_ver2()
BEGIN

    -- -------------------------------------------------------
    -- STEP 1: Insert new active DS row for changed customers
    -- -------------------------------------------------------
    -- Join the operational customer table against the DS dimension, restricted to
    -- CurrentStatus = TRUE (the live row only). Where name or zip differs, insert
    -- a fresh row with today as DateValidFrom and a far-future DateValidUntil.
    --
    -- WHY INSERT BEFORE EXPIRE (opposite of _ver1):
    --   We need the new row to exist first so that Step 2's self-join can detect
    --   the old row by comparing DateValidFrom dates (cd1.DateValidFrom < cd2.DateValidFrom).
    --   Without the new row, the self-join has nothing to compare against.
    --
    -- WHY "AND cd.CurrentStatus = TRUE" prevents duplicate inserts on re-run:
    --   On a second run with no new changes, the operational DB matches the current
    --   active row exactly, so the WHERE clause finds no mismatches → nothing inserted.
    INSERT INTO valsanv_ZAGIMORE_DS.CustomerDimension (CustomerID, CustomerName, CustomerZip, ExtractionTimestamp, cd_loaded, DateValidFrom, DateValidUntil, CurrentStatus)
    SELECT c.customerid, c.customername, c.customerzip, NOW(), FALSE, DATE(NOW()), '2035-01-01', TRUE
    FROM valsanv_ZAGIMORE.customer c, valsanv_ZAGIMORE_DS.CustomerDimension cd
    WHERE c.customerid = cd.CustomerID
    AND cd.CurrentStatus = TRUE                                               -- compare only against the live row
    AND (c.customername != cd.CustomerName OR c.customerzip != cd.CustomerZip);

    -- -------------------------------------------------------
    -- STEP 2: Expire the old DS row via a self-join
    -- -------------------------------------------------------
    -- Now that the new row exists, find pairs of rows for the same customer where
    -- cd1 is the older version and cd1 is still marked as active. Close out cd1
    -- by setting DateValidUntil to yesterday, flipping CurrentStatus to FALSE,
    -- and marking cd_loaded = FALSE so the DW sync in Step 3 picks it up.
    --
    -- HOW THE SELF-JOIN WORKS:
    --   We join CustomerDimension to itself on CustomerID. cd1 is the old row,
    --   cd2 is the new row just inserted in Step 1. We compare CustomerKey to
    --   identify which row is older. Without Step 1 having run first, cd2 would
    --   not exist and nothing would match.
    --
    -- WHY CustomerKey AND NOT DateValidFrom:
    --   CustomerKey is an auto-increment surrogate key — every new row always gets
    --   a strictly higher value than any existing row, regardless of the date.
    --   DateValidFrom is date-only (no time), so if a customer is first loaded and
    --   then changed on the same calendar day, both the old and new rows would have
    --   the same DateValidFrom. In that case cd1.DateValidFrom < cd2.DateValidFrom
    --   evaluates to FALSE and the old row never gets expired — a silent bug.
    --   CustomerKey has no such same-day collision risk.
    UPDATE valsanv_ZAGIMORE_DS.CustomerDimension cd1, valsanv_ZAGIMORE_DS.CustomerDimension cd2
    SET cd1.DateValidUntil = DATE(NOW()) - INTERVAL 1 DAY, cd1.CurrentStatus = FALSE, cd1.cd_loaded = FALSE
    WHERE cd1.CustomerID = cd2.CustomerID
    AND cd1.CustomerKey < cd2.CustomerKey                                     -- cd1 is the older row (lower auto-increment key)
    AND cd1.CurrentStatus = TRUE;                                             -- only close out still-active rows

    -- -------------------------------------------------------
    -- STEP 3: Sync changed rows from DS into the DW
    -- -------------------------------------------------------
    -- Drop FK constraints, push unloaded DS rows to DW via REPLACE INTO,
    -- then restore the constraints. Same pattern as _ver1.

    -- 1) Drop FK constraints so we can modify CustomerDimension rows in the DW
    ALTER TABLE valsanv_ZAGIMORE_DW.RevenueFactTable
    DROP Foreign Key RevenueFactTable_ibfk_4;

    ALTER TABLE valsanv_ZAGIMORE_DW.OneWayProductCategoryAggregate
    DROP Foreign Key OneWayProductCategoryAggregate_ibfk_1;

    ALTER TABLE valsanv_ZAGIMORE_DW.OneWayRegionAggregate
    DROP Foreign Key OneWayRegionAggregate_ibfk_1;

    -- 2) Push all unloaded DS rows (expired old rows + new active rows) into the DW
    REPLACE INTO valsanv_ZAGIMORE_DW.CustomerDimension (CustomerKey, CustomerID, CustomerName, CustomerZip, DateValidFrom, DateValidUntil, CurrentStatus)
    SELECT CustomerKey, CustomerID, CustomerName, CustomerZip, DateValidFrom, DateValidUntil, CurrentStatus
    FROM valsanv_ZAGIMORE_DS.CustomerDimension
    WHERE cd_loaded = FALSE;

    -- 3) Restore the FK constraints
    ALTER TABLE valsanv_ZAGIMORE_DW.RevenueFactTable
    ADD CONSTRAINT RevenueFactTable_ibfk_4
    FOREIGN KEY (CustomerKey) REFERENCES valsanv_ZAGIMORE_DW.CustomerDimension(CustomerKey);

    ALTER TABLE valsanv_ZAGIMORE_DW.OneWayProductCategoryAggregate
    ADD CONSTRAINT OneWayProductCategoryAggregate_ibfk_1
    FOREIGN KEY (CustomerKey) REFERENCES valsanv_ZAGIMORE_DW.CustomerDimension(CustomerKey);

    ALTER TABLE valsanv_ZAGIMORE_DW.OneWayRegionAggregate
    ADD CONSTRAINT OneWayRegionAggregate_ibfk_1
    FOREIGN KEY (CustomerKey) REFERENCES valsanv_ZAGIMORE_DW.CustomerDimension(CustomerKey);

    -- -------------------------------------------------------
    -- STEP 4: Mark all synced DS rows as loaded
    -- -------------------------------------------------------
    UPDATE valsanv_ZAGIMORE_DS.CustomerDimension
    SET cd_loaded = TRUE
    WHERE cd_loaded = FALSE;

END$$$

DELIMITER ;


-- =========================================================================================================================
-- Lecture 04/15/2026: Week 10 & 11 : ETL, Part 5 & 6
-- In class exercise narrative ETL part 2: dealing with new facts and changing dimensions - Continued
-- =========================================================================================================================

-- Lecture on use of AI in ETL development or just coding in general.
/* Professor Boris Jukic: "In the coming years, your job is going to be more about reviewing code written by AI instead of writing the code yourself. That means you have to be on top of your game. You must be able to read and understand what the AI is doing, and that means you have to be able to write the code yourself." */

-- =========================================================================================================================
-- Self: 04-17-2026
-- =========================================================================================================================

-- Appending new dimension values to the Store Dimension table in the next ETL cycle.
-- Following the same pattern used for ProductDimension and CustomerDimension.

-- Add control columns "ExtractionTimestamp" and "sd_loaded" to the DS StoreDimension
ALTER TABLE valsanv_ZAGIMORE_DS.StoreDimension
ADD COLUMN ExtractionTimestamp TIMESTAMP,
ADD COLUMN sd_loaded BOOLEAN;

-- Mark all existing rows as already loaded into the DW
UPDATE valsanv_ZAGIMORE_DS.StoreDimension
SET sd_loaded = TRUE;

-- Set ExtractionTimestamp for existing rows to simulate a past load
UPDATE valsanv_ZAGIMORE_DS.StoreDimension
SET ExtractionTimestamp = NOW() - INTERVAL (14) DAY;

-- Create two new stores in the operational DB to test the refresh
INSERT INTO valsanv_ZAGIMORE.store (storeid, storezip, regionid)
VALUES ("S15", "13210", "N");

INSERT INTO valsanv_ZAGIMORE.store (storeid, storezip, regionid)
VALUES ("S16", "10001", "C");

-- Store Dimension refresh code: extract new stores from operational DB and load into DS
-- We join with the region table to denormalize RegionID and RegionName into StoreDimension
INSERT INTO valsanv_ZAGIMORE_DS.StoreDimension (StoreID, StoreZip, RegionID, RegionName, ExtractionTimestamp, sd_loaded)
SELECT s.storeid, s.storezip, r.regionid, r.regionname, NOW(), FALSE
FROM valsanv_ZAGIMORE.store s
JOIN valsanv_ZAGIMORE.region r ON s.regionid = r.regionid
WHERE s.storeid NOT IN (SELECT DISTINCT StoreID FROM valsanv_ZAGIMORE_DS.StoreDimension);

-- Load new stores (sd_loaded = FALSE) from DS into the DW StoreDimension
INSERT INTO valsanv_ZAGIMORE_DW.StoreDimension (StoreKey, StoreID, StoreZip, RegionID, RegionName)
SELECT StoreKey, StoreID, StoreZip, RegionID, RegionName
FROM valsanv_ZAGIMORE_DS.StoreDimension
WHERE sd_loaded = FALSE;

-- Mark the newly loaded rows as loaded
UPDATE valsanv_ZAGIMORE_DS.StoreDimension
SET sd_loaded = TRUE
WHERE sd_loaded = FALSE;

-- Creating a procedure for Store Dimension refresh
DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.store_dimension_refresh;

DELIMITER $$$

CREATE PROCEDURE valsanv_ZAGIMORE_DS.store_dimension_refresh()
BEGIN
    -- Insert new stores from the operational DB that are not yet in the DS StoreDimension
    INSERT INTO valsanv_ZAGIMORE_DS.StoreDimension (StoreID, StoreZip, RegionID, RegionName, ExtractionTimestamp, sd_loaded)
    SELECT s.storeid, s.storezip, r.regionid, r.regionname, NOW(), FALSE
    FROM valsanv_ZAGIMORE.store s
    JOIN valsanv_ZAGIMORE.region r ON s.regionid = r.regionid
    WHERE s.storeid NOT IN (SELECT DISTINCT StoreID FROM valsanv_ZAGIMORE_DS.StoreDimension);

    -- Load new stores (sd_loaded = FALSE) from DS into the DW StoreDimension
    INSERT INTO valsanv_ZAGIMORE_DW.StoreDimension (StoreKey, StoreID, StoreZip, RegionID, RegionName)
    SELECT StoreKey, StoreID, StoreZip, RegionID, RegionName
    FROM valsanv_ZAGIMORE_DS.StoreDimension
    WHERE sd_loaded = FALSE;

    -- Mark the newly loaded rows as loaded
    UPDATE valsanv_ZAGIMORE_DS.StoreDimension
    SET sd_loaded = TRUE
    WHERE sd_loaded = FALSE;
END$$$

DELIMITER ;

-- Create two more new stores in the operational DB to test the procedure
INSERT INTO valsanv_ZAGIMORE.store (storeid, storezip, regionid)
VALUES ("S17", "90210", "I");

INSERT INTO valsanv_ZAGIMORE.store (storeid, storezip, regionid)
VALUES ("S18", "60601", "C");

-- Calling the procedure
CALL valsanv_ZAGIMORE_DS.store_dimension_refresh();

-- Sanity check for store_dimension_refresh
-- Validates that row counts are consistent across the operational DB, DS, and DW for StoreDimension.
-- =========================================================================================================================

DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.sp_validate_store_dimension;

DELIMITER $$$

CREATE PROCEDURE valsanv_ZAGIMORE_DS.sp_validate_store_dimension()
BEGIN
    DECLARE src_count INT DEFAULT 0;
    DECLARE ds_count INT DEFAULT 0;
    DECLARE dw_count INT DEFAULT 0;

    SELECT COUNT(*) INTO src_count
    FROM valsanv_ZAGIMORE.store;

    SELECT COUNT(*) INTO ds_count
    FROM valsanv_ZAGIMORE_DS.StoreDimension;

    SELECT COUNT(*) INTO dw_count
    FROM valsanv_ZAGIMORE_DW.StoreDimension;

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
CALL valsanv_ZAGIMORE_DS.sp_validate_store_dimension();

-- =========================================================================================================================
-- Drop ProductPriceMonthly from DS ProductDimension for consistency with DW (which no longer has this column)
ALTER TABLE valsanv_ZAGIMORE_DS.ProductDimension
DROP COLUMN ProductPriceMonthly;

-- =========================================================================================================================
-- Handling Type-2 Changes for Product Dimension
-- =========================================================================================================================

-- Adding 3 Type-2 change tracking columns to the Product Dimension in DS and setting their initial values
ALTER TABLE valsanv_ZAGIMORE_DS.ProductDimension
ADD DateValidFrom DATE,
ADD DateValidUntil DATE,
ADD CurrentStatus BOOLEAN;

UPDATE valsanv_ZAGIMORE_DS.ProductDimension
SET DateValidFrom = '2013-01-01', DateValidUntil = '2035-01-01', CurrentStatus = TRUE;

-- Adding 3 Type-2 change tracking columns to the Product Dimension in DW and setting their initial values
ALTER TABLE valsanv_ZAGIMORE_DW.ProductDimension
ADD DateValidFrom DATE,
ADD DateValidUntil DATE,
ADD CurrentStatus BOOLEAN;

UPDATE valsanv_ZAGIMORE_DW.ProductDimension
SET DateValidFrom = '2013-01-01', DateValidUntil = '2035-01-01', CurrentStatus = TRUE;

-- Simulate changes: update a sale product and a rental product in the operational DB
UPDATE valsanv_ZAGIMORE.product
SET productname = 'Test Product Updated', productprice = 300.00
WHERE productid = '1Y1';

UPDATE valsanv_ZAGIMORE.rentalProducts
SET productname = 'Test Rental Updated', productpricedaily = 30.00, productpriceweekly = 120.00
WHERE productid = '1Z1';

-- Check: spot the products whose tracked attributes have changed vs the current DS version
SELECT pd.ProductKey, pd.ProductID, pd.ProductType, pd.ProductName, pd.ProductSalePrice, pd.DateValidFrom, pd.DateValidUntil, pd.CurrentStatus
FROM valsanv_ZAGIMORE.product p
JOIN valsanv_ZAGIMORE.vendor v ON p.vendorid = v.vendorid
JOIN valsanv_ZAGIMORE_DS.ProductDimension pd ON p.productid = pd.ProductID AND pd.ProductType = "S" AND pd.CurrentStatus = TRUE
WHERE (p.productname != pd.ProductName OR p.productprice != pd.ProductSalePrice OR p.vendorid != pd.VendorID OR v.vendorname != pd.VendorName)
UNION
SELECT pd.ProductKey, pd.ProductID, pd.ProductType, pd.ProductName, pd.ProductPriceDaily, pd.DateValidFrom, pd.DateValidUntil, pd.CurrentStatus
FROM valsanv_ZAGIMORE.rentalProducts r
JOIN valsanv_ZAGIMORE.vendor v ON r.vendorid = v.vendorid
JOIN valsanv_ZAGIMORE_DS.ProductDimension pd ON r.productid = pd.ProductID AND pd.ProductType = "R" AND pd.CurrentStatus = TRUE
WHERE (r.productname != pd.ProductName OR r.productpricedaily != pd.ProductPriceDaily OR r.productpriceweekly != pd.ProductPriceWeekly OR r.vendorid != pd.VendorID OR v.vendorname != pd.VendorName);

-- Expire the old rows in DS ProductDimension for changed sale products
UPDATE valsanv_ZAGIMORE.product p
JOIN valsanv_ZAGIMORE.vendor v ON p.vendorid = v.vendorid
JOIN valsanv_ZAGIMORE_DS.ProductDimension pd ON p.productid = pd.ProductID AND pd.ProductType = "S" AND pd.CurrentStatus = TRUE
SET pd.DateValidUntil = DATE(NOW()) - INTERVAL 1 DAY, pd.CurrentStatus = FALSE, pd.pd_loaded = FALSE
WHERE (p.productname != pd.ProductName OR p.productprice != pd.ProductSalePrice OR p.vendorid != pd.VendorID OR v.vendorname != pd.VendorName);

-- Expire the old rows in DS ProductDimension for changed rental products
UPDATE valsanv_ZAGIMORE.rentalProducts r
JOIN valsanv_ZAGIMORE.vendor v ON r.vendorid = v.vendorid
JOIN valsanv_ZAGIMORE_DS.ProductDimension pd ON r.productid = pd.ProductID AND pd.ProductType = "R" AND pd.CurrentStatus = TRUE
SET pd.DateValidUntil = DATE(NOW()) - INTERVAL 1 DAY, pd.CurrentStatus = FALSE, pd.pd_loaded = FALSE
WHERE (r.productname != pd.ProductName OR r.productpricedaily != pd.ProductPriceDaily OR r.productpriceweekly != pd.ProductPriceWeekly OR r.vendorid != pd.VendorID OR v.vendorname != pd.VendorName);

-- Insert new (current) versions of changed products into DS ProductDimension
INSERT INTO valsanv_ZAGIMORE_DS.ProductDimension (ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly, ExtractionTimestamp, pd_loaded, DateValidFrom, DateValidUntil, CurrentStatus)
SELECT p.productid, p.productname, p.vendorid, p.categoryid, v.vendorname, c.categoryname, "S", p.productprice, NULL, NULL, NOW(), FALSE, DATE(NOW()), '2035-01-01', TRUE
FROM valsanv_ZAGIMORE.product p
JOIN valsanv_ZAGIMORE.vendor v ON p.vendorid = v.vendorid
JOIN valsanv_ZAGIMORE.category c ON p.categoryid = c.categoryid
JOIN valsanv_ZAGIMORE_DS.ProductDimension pd ON p.productid = pd.ProductID AND pd.ProductType = "S" AND pd.CurrentStatus = FALSE AND pd.DateValidUntil = DATE(NOW()) - INTERVAL 1 DAY
UNION
SELECT r.productid, r.productname, r.vendorid, r.categoryid, v.vendorname, c.categoryname, "R", NULL, r.productpricedaily, r.productpriceweekly, NOW(), FALSE, DATE(NOW()), '2035-01-01', TRUE
FROM valsanv_ZAGIMORE.rentalProducts r
JOIN valsanv_ZAGIMORE.vendor v ON r.vendorid = v.vendorid
JOIN valsanv_ZAGIMORE.category c ON r.categoryid = c.categoryid
JOIN valsanv_ZAGIMORE_DS.ProductDimension pd ON r.productid = pd.ProductID AND pd.ProductType = "R" AND pd.CurrentStatus = FALSE AND pd.DateValidUntil = DATE(NOW()) - INTERVAL 1 DAY;

-- Sync the DW ProductDimension with all changed rows (expired + new) from DS
-- Note: We need to drop the FK reference from the RevenueFactTable and OneWayRegionAggregate before running REPLACE INTO,
-- because MySQL won't allow updating a referenced PK row while the FK constraint is enforced.
-- 1) Drop the FK reference from the RevenueFactTable
ALTER TABLE valsanv_ZAGIMORE_DW.RevenueFactTable
DROP FOREIGN KEY RevenueFactTable_ibfk_1; -- get the value from the "Constraint properties" under the "Relation view" tab of RevenueFactTable in the DW

ALTER TABLE valsanv_ZAGIMORE_DW.OneWayRegionAggregate
DROP FOREIGN KEY OneWayRegionAggregate_ibfk_4;

-- 2) Sync all changed and new rows from DS to DW using REPLACE INTO
REPLACE INTO valsanv_ZAGIMORE_DW.ProductDimension (ProductKey, ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly, DateValidFrom, DateValidUntil, CurrentStatus)
SELECT ProductKey, ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly, DateValidFrom, DateValidUntil, CurrentStatus
FROM valsanv_ZAGIMORE_DS.ProductDimension
WHERE pd_loaded = FALSE;

-- 3) Add back the FK reference
ALTER TABLE valsanv_ZAGIMORE_DW.RevenueFactTable
ADD CONSTRAINT RevenueFactTable_ibfk_1 -- get the value from the "Constraint properties" under the "Relation view" tab of the corresponding table in the DW
FOREIGN KEY (ProductKey) REFERENCES valsanv_ZAGIMORE_DW.ProductDimension(ProductKey);

ALTER TABLE valsanv_ZAGIMORE_DW.OneWayRegionAggregate
ADD CONSTRAINT OneWayRegionAggregate_ibfk_4
FOREIGN KEY (ProductKey) REFERENCES valsanv_ZAGIMORE_DW.ProductDimension(ProductKey);

-- 4) Mark the synced rows as loaded in DS
UPDATE valsanv_ZAGIMORE_DS.ProductDimension
SET pd_loaded = TRUE
WHERE pd_loaded = FALSE;

-- Now wrap the Type-2 product dimension changes into a stored procedure
DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.product_dimension_type2_refresh;

DELIMITER $$$

CREATE PROCEDURE valsanv_ZAGIMORE_DS.product_dimension_type2_refresh()
BEGIN
    -- Step 1: Insert new (current) versions for changed sale and rental products
    -- Detect changes by comparing source to the current DS row (CurrentStatus = TRUE)
    INSERT INTO valsanv_ZAGIMORE_DS.ProductDimension (ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly, ExtractionTimestamp, pd_loaded, DateValidFrom, DateValidUntil, CurrentStatus)
    SELECT p.productid, p.productname, p.vendorid, p.categoryid, v.vendorname, c.categoryname, "S", p.productprice, NULL, NULL, NOW(), FALSE, DATE(NOW()), '2035-01-01', TRUE
    FROM valsanv_ZAGIMORE.product p
    JOIN valsanv_ZAGIMORE.vendor v ON p.vendorid = v.vendorid
    JOIN valsanv_ZAGIMORE.category c ON p.categoryid = c.categoryid
    JOIN valsanv_ZAGIMORE_DS.ProductDimension pd ON p.productid = pd.ProductID AND pd.ProductType = "S" AND pd.CurrentStatus = TRUE
    WHERE (p.productname != pd.ProductName OR p.productprice != pd.ProductSalePrice OR p.vendorid != pd.VendorID OR v.vendorname != pd.VendorName)
    UNION
    SELECT r.productid, r.productname, r.vendorid, r.categoryid, v.vendorname, c.categoryname, "R", NULL, r.productpricedaily, r.productpriceweekly, NOW(), FALSE, DATE(NOW()), '2035-01-01', TRUE
    FROM valsanv_ZAGIMORE.rentalProducts r
    JOIN valsanv_ZAGIMORE.vendor v ON r.vendorid = v.vendorid
    JOIN valsanv_ZAGIMORE.category c ON r.categoryid = c.categoryid
    JOIN valsanv_ZAGIMORE_DS.ProductDimension pd ON r.productid = pd.ProductID AND pd.ProductType = "R" AND pd.CurrentStatus = TRUE
    WHERE (r.productname != pd.ProductName OR r.productpricedaily != pd.ProductPriceDaily OR r.productpriceweekly != pd.ProductPriceWeekly OR r.vendorid != pd.VendorID OR v.vendorname != pd.VendorName);

    -- Step 2: Expire old rows using a self-join on ProductDimension
    -- A row is old if another row exists for the same ProductID + ProductType with a later DateValidFrom
    UPDATE valsanv_ZAGIMORE_DS.ProductDimension pd1
    JOIN valsanv_ZAGIMORE_DS.ProductDimension pd2
        ON pd1.ProductID = pd2.ProductID AND pd1.ProductType = pd2.ProductType AND pd1.DateValidFrom < pd2.DateValidFrom
    SET pd1.DateValidUntil = DATE(NOW()) - INTERVAL 1 DAY, pd1.CurrentStatus = FALSE, pd1.pd_loaded = FALSE
    WHERE pd1.CurrentStatus = TRUE;

    -- 1) Drop FK references to ProductDimension from RevenueFactTable and OneWayRegionAggregate
    ALTER TABLE valsanv_ZAGIMORE_DW.RevenueFactTable
    DROP FOREIGN KEY RevenueFactTable_ibfk_1; -- get the value from the "Constraint properties" under the "Relation view" tab of the corresponding table in the DW

    ALTER TABLE valsanv_ZAGIMORE_DW.OneWayRegionAggregate
    DROP FOREIGN KEY OneWayRegionAggregate_ibfk_4;

    -- 2) Sync all changed and new rows from DS to DW
    REPLACE INTO valsanv_ZAGIMORE_DW.ProductDimension (ProductKey, ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly, DateValidFrom, DateValidUntil, CurrentStatus)
    SELECT ProductKey, ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly, DateValidFrom, DateValidUntil, CurrentStatus
    FROM valsanv_ZAGIMORE_DS.ProductDimension
    WHERE pd_loaded = FALSE;

    -- 3) Add back the FK reference
    ALTER TABLE valsanv_ZAGIMORE_DW.RevenueFactTable
    ADD CONSTRAINT RevenueFactTable_ibfk_1
    FOREIGN KEY (ProductKey) REFERENCES valsanv_ZAGIMORE_DW.ProductDimension(ProductKey);

    ALTER TABLE valsanv_ZAGIMORE_DW.OneWayRegionAggregate
    ADD CONSTRAINT OneWayRegionAggregate_ibfk_4
    FOREIGN KEY (ProductKey) REFERENCES valsanv_ZAGIMORE_DW.ProductDimension(ProductKey);

    -- 4) Mark the synced rows as loaded in DS
    UPDATE valsanv_ZAGIMORE_DS.ProductDimension
    SET pd_loaded = TRUE
    WHERE pd_loaded = FALSE;

END$$$

DELIMITER ;

-- Simulate more product changes to test the procedure
UPDATE valsanv_ZAGIMORE.product
SET productname = 'Test Product 02 Updated', productprice = 320.00
WHERE productid = '1Y2';

UPDATE valsanv_ZAGIMORE.rentalProducts
SET productpricedaily = 35.00
WHERE productid = '1Z2';

-- Calling the procedure
CALL valsanv_ZAGIMORE_DS.product_dimension_type2_refresh();

-- =========================================================================================================================
-- Updated versions of product_dimension_refresh() and customer_dimension_refresh()
-- Now that Type-2 columns (DateValidFrom, DateValidUntil, CurrentStatus) exist in both DS and DW,
-- new records inserted by these procedures must also have those columns populated.
-- =========================================================================================================================

-- Updated product_dimension_refresh: sets Type-2 columns for brand new products on first insert
DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.product_dimension_refresh;

DELIMITER $$$

CREATE PROCEDURE valsanv_ZAGIMORE_DS.product_dimension_refresh()
BEGIN
    -- Insert new sale and rental products from the operational DB that are not yet in DS ProductDimension
    -- Type-2 columns are set here so new products are consistent with existing rows
    INSERT INTO valsanv_ZAGIMORE_DS.ProductDimension (ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly, ExtractionTimestamp, pd_loaded, DateValidFrom, DateValidUntil, CurrentStatus)
    SELECT p.productid, p.productname, p.vendorid, p.categoryid, v.vendorname, c.categoryname, "S", p.productprice, NULL, NULL, NOW(), FALSE, DATE(NOW()), '2035-01-01', TRUE
    FROM valsanv_ZAGIMORE.product p
    JOIN valsanv_ZAGIMORE.vendor v ON p.vendorid = v.vendorid
    JOIN valsanv_ZAGIMORE.category c ON p.categoryid = c.categoryid
    WHERE p.productid NOT IN (SELECT DISTINCT ProductID FROM valsanv_ZAGIMORE_DS.ProductDimension WHERE ProductType = "S")
    UNION
    SELECT r.productid, r.productname, r.vendorid, r.categoryid, v.vendorname, c.categoryname, "R", NULL, r.productpricedaily, r.productpriceweekly, NOW(), FALSE, DATE(NOW()), '2035-01-01', TRUE
    FROM valsanv_ZAGIMORE.rentalProducts r
    JOIN valsanv_ZAGIMORE.vendor v ON r.vendorid = v.vendorid
    JOIN valsanv_ZAGIMORE.category c ON r.categoryid = c.categoryid
    WHERE r.productid NOT IN (SELECT DISTINCT ProductID FROM valsanv_ZAGIMORE_DS.ProductDimension WHERE ProductType = "R");

    -- Load new products (pd_loaded = FALSE) from DS into the DW ProductDimension
    INSERT INTO valsanv_ZAGIMORE_DW.ProductDimension (ProductKey, ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly, DateValidFrom, DateValidUntil, CurrentStatus)
    SELECT ProductKey, ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly, DateValidFrom, DateValidUntil, CurrentStatus
    FROM valsanv_ZAGIMORE_DS.ProductDimension
    WHERE pd_loaded = FALSE;

    -- Mark the newly loaded rows as loaded
    UPDATE valsanv_ZAGIMORE_DS.ProductDimension
    SET pd_loaded = TRUE
    WHERE pd_loaded = FALSE;
END$$$

DELIMITER ;

-- Updated customer_dimension_refresh: sets Type-2 columns for brand new customers on first insert
DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.customer_dimension_refresh;

DELIMITER $$$

CREATE PROCEDURE valsanv_ZAGIMORE_DS.customer_dimension_refresh()
BEGIN
    -- Insert new customers from the operational DB that are not yet in DS CustomerDimension
    -- Type-2 columns are set here so new customers are consistent with existing rows
    INSERT INTO valsanv_ZAGIMORE_DS.CustomerDimension (CustomerID, CustomerName, CustomerZip, ExtractionTimestamp, cd_loaded, DateValidFrom, DateValidUntil, CurrentStatus)
    SELECT c.customerid, c.customername, c.customerzip, NOW(), FALSE, DATE(NOW()), '2035-01-01', TRUE
    FROM valsanv_ZAGIMORE.customer c
    WHERE c.customerid NOT IN (SELECT DISTINCT CustomerID FROM valsanv_ZAGIMORE_DS.CustomerDimension);

    -- Load new customers (cd_loaded = FALSE) from DS into the DW CustomerDimension
    INSERT INTO valsanv_ZAGIMORE_DW.CustomerDimension (CustomerKey, CustomerID, CustomerName, CustomerZip, DateValidFrom, DateValidUntil, CurrentStatus)
    SELECT CustomerKey, CustomerID, CustomerName, CustomerZip, DateValidFrom, DateValidUntil, CurrentStatus
    FROM valsanv_ZAGIMORE_DS.CustomerDimension
    WHERE cd_loaded = FALSE;

    -- Mark the newly loaded rows as loaded
    UPDATE valsanv_ZAGIMORE_DS.CustomerDimension
    SET cd_loaded = TRUE
    WHERE cd_loaded = FALSE;
END$$$

DELIMITER ;

-- =========================================================================================================================
-- Updated validation procedures to account for Type-2 change tracking
-- Now that ProductDimension and CustomerDimension have historical (expired) rows, counts must be
-- filtered to CurrentStatus = TRUE to correctly compare against the source operational DB.
-- =========================================================================================================================

-- Updated sp_validate_product_dimension: filters DS and DW counts to current rows only
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

    -- Count current (non-expired) sale and rental products in the DS ProductDimension
    SELECT COUNT(*) INTO ds_sale_count
    FROM valsanv_ZAGIMORE_DS.ProductDimension
    WHERE ProductType = 'S' AND CurrentStatus = TRUE;

    SELECT COUNT(*) INTO ds_rental_count
    FROM valsanv_ZAGIMORE_DS.ProductDimension
    WHERE ProductType = 'R' AND CurrentStatus = TRUE;

    SET ds_total = ds_sale_count + ds_rental_count;

    -- Count current (non-expired) sale and rental products in the DW ProductDimension
    SELECT COUNT(*) INTO dw_sale_count
    FROM valsanv_ZAGIMORE_DW.ProductDimension
    WHERE ProductType = 'S' AND CurrentStatus = TRUE;

    SELECT COUNT(*) INTO dw_rental_count
    FROM valsanv_ZAGIMORE_DW.ProductDimension
    WHERE ProductType = 'R' AND CurrentStatus = TRUE;

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

-- =========================================================================================================================

-- Updated sp_validate_customer_dimension: filters DS and DW counts to current rows only
DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.sp_validate_customer_dimension;

DELIMITER $$$

CREATE PROCEDURE valsanv_ZAGIMORE_DS.sp_validate_customer_dimension()
BEGIN
    DECLARE src_count INT DEFAULT 0;
    DECLARE ds_count INT DEFAULT 0;
    DECLARE dw_count INT DEFAULT 0;

    SELECT COUNT(*) INTO src_count
    FROM valsanv_ZAGIMORE.customer;

    -- Count only current (non-expired) rows in DS CustomerDimension
    SELECT COUNT(*) INTO ds_count
    FROM valsanv_ZAGIMORE_DS.CustomerDimension
    WHERE CurrentStatus = TRUE;

    -- Count only current (non-expired) rows in DW CustomerDimension
    SELECT COUNT(*) INTO dw_count
    FROM valsanv_ZAGIMORE_DW.CustomerDimension
    WHERE CurrentStatus = TRUE;

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

-- Calling the updated procedures to verify
CALL valsanv_ZAGIMORE_DS.sp_validate_product_dimension();
CALL valsanv_ZAGIMORE_DS.sp_validate_customer_dimension();

-- =========================================================================================================================
-- Note: Type-2 change tracking is intentionally not implemented for StoreDimension.
/* 
    Stores are stable operational entities — changes to attributes like StoreZip or RegionID are rare
    and do not carry analytical significance that would require preserving historical versions.
*/
-- =========================================================================================================================

-- =========================================================================================================================
-- Updated daily_fact_refresh and late_arriving_fact_refresh to account for Type-2 SCD
-- BUG: the original procedures joined CustomerDimension and ProductDimension on ID only,
-- which matches ALL versions of a customer/product (current + expired historical rows).
-- FIX: add i.FullDate BETWEEN DateValidFrom AND DateValidUntil to each dimension join,
-- so each fact is linked to the dimension row that was valid at transaction time.
-- StoreDimension and CalendarDimension are unchanged — no Type-2 on either.
-- =========================================================================================================================

DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.daily_fact_refresh;

DELIMITER $$$

CREATE PROCEDURE valsanv_ZAGIMORE_DS.daily_fact_refresh()
BEGIN
    DROP TABLE IF EXISTS valsanv_ZAGIMORE_DS.IntermediateFactTable;

    CREATE TABLE IF NOT EXISTS valsanv_ZAGIMORE_DS.IntermediateFactTable AS
    SELECT sv.noofitems * p.productprice AS DollarAmount, "Sale" AS RevenueSource, sv.tid, p.productid, s.storeid, s.tdate AS FullDate, s.customerid
    FROM valsanv_ZAGIMORE.soldvia as sv, valsanv_ZAGIMORE.product p, valsanv_ZAGIMORE.salestransaction s
    WHERE sv.productid = p.productid
    AND sv.tid = s.tid
    AND s.tdate > (SELECT MAX(ExtractionTimestamp) FROM valsanv_ZAGIMORE_DS.RevenueFactTable)
    UNION
    SELECT rv.duration * r.productpricedaily AS DollarAmount, "Rental_Daily" AS RevenueSource, rv.tid, r.productid, rt.storeid, rt.tdate AS FullDate, rt.customerid
    FROM valsanv_ZAGIMORE.rentvia as rv, valsanv_ZAGIMORE.rentalProducts as r, valsanv_ZAGIMORE.rentaltransaction rt
    WHERE rv.productid = r.productid
    AND rv.tid = rt.tid
    AND rv.rentaltype = "D"
    AND rt.tdate > (SELECT MAX(ExtractionTimestamp) FROM valsanv_ZAGIMORE_DS.RevenueFactTable)
    UNION
    SELECT rv.duration * r.productpriceweekly AS DollarAmount, "Rental_Weekly" AS RevenueSource, rv.tid, r.productid, rt.storeid, rt.tdate AS FullDate, rt.customerid
    FROM valsanv_ZAGIMORE.rentvia as rv, valsanv_ZAGIMORE.rentalProducts as r, valsanv_ZAGIMORE.rentaltransaction rt
    WHERE rv.productid = r.productid
    AND rv.tid = rt.tid
    AND rv.rentaltype = "W"
    AND rt.tdate > (SELECT MAX(ExtractionTimestamp) FROM valsanv_ZAGIMORE_DS.RevenueFactTable);

    ALTER TABLE valsanv_ZAGIMORE_DS.IntermediateFactTable
    MODIFY COLUMN RevenueSource VARCHAR(25) COLLATE utf8mb4_0900_ai_ci NOT NULL;

    INSERT INTO valsanv_ZAGIMORE_DS.RevenueFactTable(DollarAmount, RevenueSource, TID, CustomerKey, StoreKey, CalendarKey, ProductKey, ExtractionTimestamp, f_loaded)
    SELECT i.DollarAmount, i.RevenueSource, i.tid, cd.CustomerKey, sd.StoreKey, cad.CalendarKey, pd.ProductKey, NOW(), FALSE
    FROM valsanv_ZAGIMORE_DS.IntermediateFactTable AS i
    JOIN valsanv_ZAGIMORE_DS.CustomerDimension AS cd ON cd.CustomerID = i.customerid
        AND i.FullDate BETWEEN cd.DateValidFrom AND cd.DateValidUntil  -- Type-2 fix: match the customer row valid at transaction time, not all versions
    JOIN valsanv_ZAGIMORE_DS.StoreDimension AS sd ON sd.StoreID = i.storeid
    JOIN valsanv_ZAGIMORE_DS.CalendarDimension AS cad ON cad.FullDate = i.FullDate
    JOIN valsanv_ZAGIMORE_DS.ProductDimension AS pd ON pd.ProductID = i.productid
        AND pd.ProductType = "S"
        AND i.FullDate BETWEEN pd.DateValidFrom AND pd.DateValidUntil  -- Type-2 fix: match the product row valid at transaction time, not all versions
    WHERE i.RevenueSource = "Sale"
    UNION
    SELECT i.DollarAmount, i.RevenueSource, i.tid, cd.CustomerKey, sd.StoreKey, cad.CalendarKey, pd.ProductKey, NOW(), FALSE
    FROM valsanv_ZAGIMORE_DS.IntermediateFactTable AS i
    JOIN valsanv_ZAGIMORE_DS.CustomerDimension AS cd ON cd.CustomerID = i.customerid
        AND i.FullDate BETWEEN cd.DateValidFrom AND cd.DateValidUntil  -- Type-2 fix: match the customer row valid at transaction time, not all versions
    JOIN valsanv_ZAGIMORE_DS.StoreDimension AS sd ON sd.StoreID = i.storeid
    JOIN valsanv_ZAGIMORE_DS.CalendarDimension AS cad ON cad.FullDate = i.FullDate
    JOIN valsanv_ZAGIMORE_DS.ProductDimension AS pd ON pd.ProductID = i.productid
        AND pd.ProductType = "R"
        AND i.FullDate BETWEEN pd.DateValidFrom AND pd.DateValidUntil  -- Type-2 fix: match the product row valid at transaction time, not all versions
    WHERE i.RevenueSource IN ("Rental_Weekly", "Rental_Daily");

    INSERT INTO valsanv_ZAGIMORE_DW.RevenueFactTable (DollarAmount, RevenueSource, TID, ProductKey, StoreKey, CalendarKey, CustomerKey)
    SELECT DollarAmount, RevenueSource, TID, ProductKey, StoreKey, CalendarKey, CustomerKey
    FROM valsanv_ZAGIMORE_DS.RevenueFactTable
    WHERE f_loaded = FALSE;

    UPDATE valsanv_ZAGIMORE_DS.RevenueFactTable
    SET f_loaded = TRUE
    WHERE f_loaded = FALSE;

    DROP TABLE IF EXISTS valsanv_ZAGIMORE_DS.IntermediateFactTable;
END$$$

DELIMITER ;

-- =========================================================================================================================

DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.late_arriving_fact_refresh;

DELIMITER $$$

CREATE PROCEDURE valsanv_ZAGIMORE_DS.late_arriving_fact_refresh()
BEGIN
    DROP TABLE IF EXISTS valsanv_ZAGIMORE_DS.IntermediateFactTable;

    CREATE TABLE IF NOT EXISTS valsanv_ZAGIMORE_DS.IntermediateFactTable AS
    SELECT sv.noofitems * p.productprice AS DollarAmount, "Sale" AS RevenueSource, sv.tid, p.productid, s.storeid, s.tdate AS FullDate, s.customerid
    FROM valsanv_ZAGIMORE.soldvia as sv, valsanv_ZAGIMORE.product p, valsanv_ZAGIMORE.salestransaction s
    WHERE sv.productid = p.productid
    AND sv.tid = s.tid
    AND s.tid NOT IN (SELECT DISTINCT tid FROM valsanv_ZAGIMORE_DS.RevenueFactTable)
    UNION
    SELECT rv.duration * r.productpricedaily AS DollarAmount, "Rental_Daily" AS RevenueSource, rv.tid, r.productid, rt.storeid, rt.tdate AS FullDate, rt.customerid
    FROM valsanv_ZAGIMORE.rentvia as rv, valsanv_ZAGIMORE.rentalProducts as r, valsanv_ZAGIMORE.rentaltransaction rt
    WHERE rv.productid = r.productid
    AND rv.tid = rt.tid
    AND rv.rentaltype = "D"
    AND rt.tid NOT IN (SELECT DISTINCT tid FROM valsanv_ZAGIMORE_DS.RevenueFactTable)
    UNION
    SELECT rv.duration * r.productpriceweekly AS DollarAmount, "Rental_Weekly" AS RevenueSource, rv.tid, r.productid, rt.storeid, rt.tdate AS FullDate, rt.customerid
    FROM valsanv_ZAGIMORE.rentvia as rv, valsanv_ZAGIMORE.rentalProducts as r, valsanv_ZAGIMORE.rentaltransaction rt
    WHERE rv.productid = r.productid
    AND rv.tid = rt.tid
    AND rv.rentaltype = "W"
    AND rt.tid NOT IN (SELECT DISTINCT tid FROM valsanv_ZAGIMORE_DS.RevenueFactTable);

    ALTER TABLE valsanv_ZAGIMORE_DS.IntermediateFactTable
    MODIFY COLUMN RevenueSource VARCHAR(25) COLLATE utf8mb4_0900_ai_ci NOT NULL;

    INSERT INTO valsanv_ZAGIMORE_DS.RevenueFactTable(DollarAmount, RevenueSource, TID, CustomerKey, StoreKey, CalendarKey, ProductKey, ExtractionTimestamp, f_loaded)
    SELECT i.DollarAmount, i.RevenueSource, i.tid, cd.CustomerKey, sd.StoreKey, cad.CalendarKey, pd.ProductKey, NOW(), FALSE
    FROM valsanv_ZAGIMORE_DS.IntermediateFactTable AS i
    JOIN valsanv_ZAGIMORE_DS.CustomerDimension AS cd ON cd.CustomerID = i.customerid
        AND i.FullDate BETWEEN cd.DateValidFrom AND cd.DateValidUntil  -- Type-2 fix: match the customer row valid at transaction time, not all versions
    JOIN valsanv_ZAGIMORE_DS.StoreDimension AS sd ON sd.StoreID = i.storeid
    JOIN valsanv_ZAGIMORE_DS.CalendarDimension AS cad ON cad.FullDate = i.FullDate
    JOIN valsanv_ZAGIMORE_DS.ProductDimension AS pd ON pd.ProductID = i.productid
        AND pd.ProductType = "S"
        AND i.FullDate BETWEEN pd.DateValidFrom AND pd.DateValidUntil  -- Type-2 fix: match the product row valid at transaction time, not all versions
    WHERE i.RevenueSource = "Sale"
    UNION
    SELECT i.DollarAmount, i.RevenueSource, i.tid, cd.CustomerKey, sd.StoreKey, cad.CalendarKey, pd.ProductKey, NOW(), FALSE
    FROM valsanv_ZAGIMORE_DS.IntermediateFactTable AS i
    JOIN valsanv_ZAGIMORE_DS.CustomerDimension AS cd ON cd.CustomerID = i.customerid
        AND i.FullDate BETWEEN cd.DateValidFrom AND cd.DateValidUntil  -- Type-2 fix: match the customer row valid at transaction time, not all versions
    JOIN valsanv_ZAGIMORE_DS.StoreDimension AS sd ON sd.StoreID = i.storeid
    JOIN valsanv_ZAGIMORE_DS.CalendarDimension AS cad ON cad.FullDate = i.FullDate
    JOIN valsanv_ZAGIMORE_DS.ProductDimension AS pd ON pd.ProductID = i.productid
        AND pd.ProductType = "R"
        AND i.FullDate BETWEEN pd.DateValidFrom AND pd.DateValidUntil  -- Type-2 fix: match the product row valid at transaction time, not all versions
    WHERE i.RevenueSource IN ("Rental_Weekly", "Rental_Daily");

    INSERT INTO valsanv_ZAGIMORE_DW.RevenueFactTable (DollarAmount, RevenueSource, TID, ProductKey, StoreKey, CalendarKey, CustomerKey)
    SELECT DollarAmount, RevenueSource, TID, ProductKey, StoreKey, CalendarKey, CustomerKey
    FROM valsanv_ZAGIMORE_DS.RevenueFactTable
    WHERE f_loaded = FALSE;

    UPDATE valsanv_ZAGIMORE_DS.RevenueFactTable
    SET f_loaded = TRUE
    WHERE f_loaded = FALSE;

    DROP TABLE IF EXISTS valsanv_ZAGIMORE_DS.IntermediateFactTable;
END$$$

DELIMITER ;

-- =========================================================================================================================
-- Self: 04-17-2026 - Bug fix: updated customer_dimension_type2_refresh and wrote two versions of updated procedures
-- =========================================================================================================================

-- Let's insert some more new data into the ZAGIMORE operational database and test the the different stored procedures for the ETL

-- daily_fact_refresh
-- Creating new instances of operational data: new sales transaction
-- Create one new sales transaction record in the salestransaction table of the ZAGIMORE  operational database.
INSERT INTO valsanv_ZAGIMORE.salestransaction (tid, tdate, customerid, storeid)
VALUES ("N013", '2026-04-17', "8-9-000", "S7");

-- Create two new records in the sold_via table for that new transaction, showing purchases of two products 
INSERT INTO valsanv_ZAGIMORE.soldvia (productid, tid, noofitems)
VALUES ("1X1", "N013", 3), ("1X2", "N013", 5);

-- Creating new instances of operational data: new rental transaction
INSERT INTO valsanv_ZAGIMORE.rentaltransaction (tid, tdate, customerid, storeid) VALUES ("N014", '2026-04-17', "8-9-000", "S3");
INSERT INTO valsanv_ZAGIMORE.rentvia (productid, tid, rentaltype, duration) VALUES ("1X1", "N014", "D", 5);
INSERT INTO valsanv_ZAGIMORE.rentvia (productid, tid, rentaltype, duration) VALUES ("2X2", "N014", "W", 5);

-- then run validate > refresh > validate

-- late_arriving_fact_refresh
-- Creating new instances of operational data: new sales transaction
-- Create one new sales transaction record in the salestransaction table of the ZAGIMORE  operational database.
INSERT INTO valsanv_ZAGIMORE.salestransaction (tid, tdate, customerid, storeid)
VALUES ("N015", '2026-04-15', "8-9-000", "S7");

-- Create two new records in the sold_via table for that new transaction, showing purchases of two products 
INSERT INTO valsanv_ZAGIMORE.soldvia (productid, tid, noofitems)
VALUES ("1X1", "N015", 3), ("1X2", "N015", 5);

-- Creating new instances of operational data: new rental transaction
INSERT INTO valsanv_ZAGIMORE.rentaltransaction (tid, tdate, customerid, storeid) VALUES ("N016", '2026-04-15', "8-9-000", "S3");
INSERT INTO valsanv_ZAGIMORE.rentvia (productid, tid, rentaltype, duration) VALUES ("1X1", "N016", "D", 5);
INSERT INTO valsanv_ZAGIMORE.rentvia (productid, tid, rentaltype, duration) VALUES ("2X2", "N016", "W", 5);

-- then run validate > refresh > validate

-- customer_dimension_refresh
-- Insert a new customer into the operational DB to test the procedure
INSERT INTO valsanv_ZAGIMORE.customer (customerid, customername, customerzip)
VALUES ("9-1-003", "Customer 003", "55499");

-- then run validate > refresh > validate

-- product_dimension_refresh
-- new product
INSERT INTO valsanv_ZAGIMORE.product ( productid, productname, productprice, vendorid, categoryid ) 
VALUES ( "1Y6", "Test Product 06", 250.00, "PG", "CL" );
-- new rental product
INSERT INTO valsanv_ZAGIMORE.rentalProducts ( productid, productname, productpricedaily, productpriceweekly, vendorid, categoryid ) 
VALUES ( "1Z6", "Test Rental Product 06", 25.00, 100.00, "PG", "CL" );

-- then run validate > refresh > validate

-- store_dimension_refresh
-- Create two new stores in the operational DB to test the refresh
INSERT INTO valsanv_ZAGIMORE.store (storeid, storezip, regionid)
VALUES ("S19", "13110", "N");

INSERT INTO valsanv_ZAGIMORE.store (storeid, storezip, regionid)
VALUES ("S20", "10101", "C");

-- then run validate > refresh > validate

-- customer_dimension_type2_refresh_ver1
-- 3 Changes in the Customer Table
UPDATE `customer` SET `customername` = 'Customer 101' WHERE `customer`.`customerid` = '9-1-001';
UPDATE `customer` SET `customerzip` = '55500' WHERE `customer`.`customerid` = '9-1-002';
UPDATE `customer` SET `customername` = 'Customer 103', `customerzip` = '55500' WHERE `customer`.`customerid` = '9-1-003';

-- then run validate > refresh > validate

-- customer_dimension_type2_refresh_ver2
-- 3 Changes in the Customer Table
UPDATE `customer` SET `customername` = 'Customer 111' WHERE `customer`.`customerid` = '9-1-001';
UPDATE `customer` SET `customerzip` = '55501' WHERE `customer`.`customerid` = '9-1-002';
UPDATE `customer` SET `customername` = 'Customer 113', `customerzip` = '55501' WHERE `customer`.`customerid` = '9-1-003';

-- 3 Changes in the Customer Table
UPDATE `customer` SET `customername` = 'Customer 121' WHERE `customer`.`customerid` = '9-1-001';
UPDATE `customer` SET `customerzip` = '55502' WHERE `customer`.`customerid` = '9-1-002';
UPDATE `customer` SET `customername` = 'Customer 123', `customerzip` = '55502' WHERE `customer`.`customerid` = '9-1-003';

-- 3 Changes in the Customer Table
UPDATE `customer` SET `customername` = 'Customer 131' WHERE `customer`.`customerid` = '9-1-001';
UPDATE `customer` SET `customerzip` = '55503' WHERE `customer`.`customerid` = '9-1-002';
UPDATE `customer` SET `customername` = 'Customer 133', `customerzip` = '55503' WHERE `customer`.`customerid` = '9-1-003';

-- 3 Changes in the Customer Table
UPDATE `customer` SET `customername` = 'Customer 141' WHERE `customer`.`customerid` = '9-1-001';
UPDATE `customer` SET `customerzip` = '55504' WHERE `customer`.`customerid` = '9-1-002';
UPDATE `customer` SET `customername` = 'Customer 143', `customerzip` = '55504' WHERE `customer`.`customerid` = '9-1-003';

-- then run validate > refresh > validate

-- product_dimension_type2_refresh
-- Simulate changes: update a sale product and a rental product in the operational DB
UPDATE valsanv_ZAGIMORE.product
SET productname = 'Test Product 03 Updated', productprice = 300.00
WHERE productid = '1Y3';

UPDATE valsanv_ZAGIMORE.rentalProducts
SET productname = 'Test Rental Updated 03', productpricedaily = 30.00, productpriceweekly = 120.00
WHERE productid = '1Z3';

-- then run validate > refresh > validate

-- =========================================================================================================================
-- Self: 04-20-2026 - new stored procedures for checking whether type-2 refresh is needed in customer and product dimensions
-- =========================================================================================================================

-- Customer Type-2 check procedure
/* This checks whether any current customer row in DS differs from the source system and therefore needs a Type 2 refresh. */
DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.sp_check_customer_type2_needed;

DELIMITER $$$

CREATE PROCEDURE valsanv_ZAGIMORE_DS.sp_check_customer_type2_needed()
BEGIN
    DECLARE change_count INT DEFAULT 0;

    SELECT COUNT(*)
    INTO change_count
    FROM valsanv_ZAGIMORE.customer c
    JOIN valsanv_ZAGIMORE_DS.CustomerDimension cd
        ON c.customerid = cd.CustomerID
    WHERE cd.CurrentStatus = TRUE
      AND (
            c.customername <> cd.CustomerName
         OR c.customerzip  <> cd.CustomerZip
      );

    SELECT
        'CustomerDimension' AS dimension_name,
        change_count AS rows_needing_type2_refresh,
        CASE
            WHEN change_count > 0 THEN 'YES'
            ELSE 'NO'
        END AS type2_refresh_needed;
END$$$

DELIMITER ;

-- =========================================================================================================================

-- Product Type-2 check procedure
/* This checks whether any current product row in DS differs from the source system and therefore needs a Type 2 refresh.
Because we have two operational product sources, this procedure checks both:
    sale products from product with ProductType = 'S'
    rental products from rentalProducts with ProductType = 'R' */
DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.sp_check_product_type2_needed;

DELIMITER $$$

CREATE PROCEDURE valsanv_ZAGIMORE_DS.sp_check_product_type2_needed()
BEGIN
    DECLARE sale_change_count INT DEFAULT 0;
    DECLARE rental_change_count INT DEFAULT 0;
    DECLARE total_change_count INT DEFAULT 0;

    -- Check sale products
    SELECT COUNT(*)
    INTO sale_change_count
    FROM valsanv_ZAGIMORE.product p
    JOIN valsanv_ZAGIMORE.vendor v
        ON p.vendorid = v.vendorid
    JOIN valsanv_ZAGIMORE.category c
        ON p.categoryid = c.categoryid
    JOIN valsanv_ZAGIMORE_DS.ProductDimension pd
        ON p.productid = pd.ProductID
    WHERE pd.CurrentStatus = TRUE
      AND pd.ProductType = 'S'
      AND (
            p.productname <> pd.ProductName
         OR p.vendorid    <> pd.VendorID
         OR p.categoryid  <> pd.CategoryID
         OR v.vendorname  <> pd.VendorName
         OR c.categoryname <> pd.CategoryName
         OR p.productprice <> pd.ProductSalePrice
      );

    -- Check rental products
    SELECT COUNT(*)
    INTO rental_change_count
    FROM valsanv_ZAGIMORE.rentalProducts r
    JOIN valsanv_ZAGIMORE.vendor v
        ON r.vendorid = v.vendorid
    JOIN valsanv_ZAGIMORE.category c
        ON r.categoryid = c.categoryid
    JOIN valsanv_ZAGIMORE_DS.ProductDimension pd
        ON r.productid = pd.ProductID
    WHERE pd.CurrentStatus = TRUE
      AND pd.ProductType = 'R'
      AND (
            r.productname        <> pd.ProductName
         OR r.vendorid           <> pd.VendorID
         OR r.categoryid         <> pd.CategoryID
         OR v.vendorname         <> pd.VendorName
         OR c.categoryname       <> pd.CategoryName
         OR r.productpricedaily  <> pd.ProductPriceDaily
         OR r.productpriceweekly <> pd.ProductPriceWeekly
      );

    SET total_change_count = sale_change_count + rental_change_count;

    SELECT
        'ProductDimension' AS dimension_name,
        sale_change_count AS sale_rows_needing_type2_refresh,
        rental_change_count AS rental_rows_needing_type2_refresh,
        total_change_count AS total_rows_needing_type2_refresh,
        CASE
            WHEN total_change_count > 0 THEN 'YES'
            ELSE 'NO'
        END AS type2_refresh_needed;
END$$$

DELIMITER ;

-- =========================================================================================================================

-- Code for combined daily refresh procedure -- for automated refresh
DROP PROCEDURE IF EXISTS valsanv_ZAGIMORE_DS.daily_refresh;

DELIMITER $$$

CREATE PROCEDURE valsanv_ZAGIMORE_DS.daily_refresh()
BEGIN
    CALL valsanv_ZAGIMORE_DS.product_dimension_refresh();
    CALL valsanv_ZAGIMORE_DS.customer_dimension_refresh();
    CALL valsanv_ZAGIMORE_DS.store_dimension_refresh();
    CALL valsanv_ZAGIMORE_DS.customer_dimension_type2_refresh_ver2();
    CALL valsanv_ZAGIMORE_DS.daily_fact_refresh();
END$$$

DELIMITER ;

-- =========================================================================================================================