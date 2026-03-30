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

-- 1-2. Creating new instances of operational data: new sales transaction

-- Create one new sales transaction record in the salestransaction table of the ZAGIMORE  operational database.
INSERT INTO valsanv_ZAGIMORE.salestransaction (tid, tdate, customerid, storeid)
VALUES ("N001", '2026-03-25', "8-9-000", "S7");

-- Create two new records in the sold_via table for that new transaction, showing purchases of two products 
INSERT INTO valsanv_ZAGIMORE.soldvia (productid, tid, noofitems)
VALUES ("1X1", "N001", 3), ("1X2", "N001", 5);

-- =========================================================================================================================
-- Lecture 03/25/2026: Week 10 & 11 : ETL, Part 5 & 6
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
-- Here we're using a modified version of the  we used for initial mapping of rows from intermediate fact table into the fact table
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
