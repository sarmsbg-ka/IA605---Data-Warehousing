-- -- Week 10 & 11 : ETL, Part 5&6 In class exercise narrative ETL part 2: dealing with new facts and changing dimensions

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
