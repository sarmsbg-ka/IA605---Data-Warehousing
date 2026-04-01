-- =========================================================================================================================
-- Lecture 02/23/2026:
-- ========================================================================================================================= 

-- CALENDAR DIMENSION POPULATION
-- Patricia's code for calendar population shared in class
DELIMITER $$
-- create procedure
CREATE PROCEDURE populate_calendar()
BEGIN
  DECLARE i INT DEFAULT 0;   
  DECLARE FullDate DATE DEFAULT '2013-01-01'; -- initialize the date to desired start date
-- create a loop
myloop: LOOP
    
    INSERT INTO CalendarDimension(FullDate) SELECT DATE_ADD(FullDate, INTERVAL i DAY);
    -- increment the date by 1 day
    SET i=i+1;
    IF i=8000 then
            LEAVE myloop;
    END IF;
END LOOP myloop;

END;


/* Note: these steps must be performed before the procedures are executed:
1. Create a new column CalendarWeekDay in the CalendarDimension table
2. Allow NULL values in the MonthYear, CalendarYear, and CalendarWeekDay columns
3. SET CalendarKey to AUTO_INCREMENT */


-- Update procedure for calendar dimension to populate MonthYear and CalendarYear columns
-- Slightly modified from Patricia's class code
DELIMITER $$
CREATE PROCEDURE updateCalendar() -- CREATE OR REPLACE PROCEDURE updateCalendar() DOESN'T WORK IN MYSQL (Clarkson)
BEGIN
    UPDATE CalendarDimension
    SET MonthYear = CONCAT(LPAD(MONTH(FullDate), 2, '0'), YEAR(FullDate)),
        CalendarYear = YEAR(FullDate), CalendarWeekDay = DAYNAME(FullDate);
END;



-- CUSTOMER DIMENSION POPULATION
-- Populate the CustomerDimension table with data from the valsanv_ZAGIMORE.customer table

-- First, let's check the data in the valsanv_ZAGIMORE.customer table to ensure we have the correct columns and data types
SELECT c.customerid, c.customername, c.customerzip
FROM valsanv_ZAGIMORE.customer c;

-- SET CustomerKey to AUTO_INCREMENT
-- Now we can insert this data into the CustomerDimension table in the ZAGIMORE_DS database
INSERT INTO valsanv_ZAGIMORE_DS.CustomerDimension (CustomerID, CustomerName, CustomerZip)
SELECT c.customerid, c.customername, c.customerzip
FROM valsanv_ZAGIMORE.customer c;

-- If we need to clear the CustomerDimension table before repopulating it, we can use the following command:
-- NOTE: This will delete all the data in the CustomerDimension table, so use with caution!
-- This will reset the auto-increment counter to 1 as well, which is often desirable when repopulating a dimension table.
TRUNCATE valsanv_ZAGIMORE_DS.CustomerDimension; -- Clear the CustomerDimension table before repopulating it



-- STORE DIMENSION POPULATION
-- Code for extracting data from store and region tables in ZAGIMORE into the StoreDimension table in the ZAGIMORE_DS database

-- First, let's check the data in the valsanv_ZAGIMORE.store and valsanv_ZAGIMORE.region tables to ensure we have the correct columns and data types
SELECT 	s.storeid,	s.storezip,	s.regionid,	r.regionname	-- regionid can be r.regionid or s.regionid since they are the same, but we will use s.regionid to avoid confusion
FROM valsanv_ZAGIMORE.region r
JOIN valsanv_ZAGIMORE.store s ON r.RegionID = s.RegionID;

-- SET StoreKey to AUTO_INCREMENT
-- Now we can insert this data into the StoreDimension table in the ZAGIMORE_DS database
INSERT INTO valsanv_ZAGIMORE_DS.StoreDimension (StoreID, StoreZip, RegionID, RegionName)
SELECT 	s.storeid,	s.storezip,	s.regionid,	r.regionname	-- regionid can be r.regionid or s.regionid since they are the same, but we will use s.regionid to avoid confusion
FROM valsanv_ZAGIMORE.region r
JOIN valsanv_ZAGIMORE.store s ON r.RegionID = s.RegionID;



-- PRODUCT DIMENSION POPULATION
-- Code for extracting data from product, vendor and category tables in ZAGIMORE into the ProductDimension table in the ZAGIMORE_DS database

-- 01 - Extracting data for products with product type "Sale"
-- First, let's check the data in the valsanv_ZAGIMORE.product, valsanv_ZAGIMORE.vendor and valsanv_ZAGIMORE.category tables to ensure we have the correct columns and data types
-- Also let's implement a different JOIN syntax to practice different ways of writing JOINs in SQL
SELECT p.productid, p.productname, p.vendorid, p.categoryid, v.vendorname, c.categoryname, "S", p.productprice, NULL, NULL, NULL -- "S" for "Sale" since we don't have a product type column in the product table, but we can assume all products are for sale. NULL values for the price columns since we don't have that data in the product table, but we can populate those columns later if needed.
FROM valsanv_ZAGIMORE.product p, valsanv_ZAGIMORE.vendor v, valsanv_ZAGIMORE.category c
WHERE p.categoryid=c.categoryid
AND p.vendorid=v.vendorid

--Now we can insert this data into the ProductDimension table in the ZAGIMORE_DS database
-- Here we will use the JOIN syntax instead of the WHERE clause to practice different ways of writing JOINs in SQL
INSERT INTO valsanv_ZAGIMORE_DS.ProductDimension (ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly, ProductPriceMonthly)
SELECT p.productid, p.productname, p.vendorid, p.categoryid, v.vendorname, c.categoryname, "S", p.productprice, NULL, NULL, NULL
FROM valsanv_ZAGIMORE.product p
JOIN valsanv_ZAGIMORE.vendor v ON p.vendorid = v.vendorid
JOIN valsanv_ZAGIMORE.category c ON p.categoryid = c.categoryid;

-- Now for the rental product type
-- 02 - Extracting data for products with product type "Rental"
SELECT r.productid, r.productname, r.vendorid, r.categoryid, v.vendorname, c.categoryname, "R", NULL, r.productpricedaily, r.productpriceweekly, NULL -- "R" for "Rental" since we don't have a product type column in the rental product table, but we can assume all rental products are for rent. NULL values for the ProductSalePrice and ProductPriceMonthly columns since we don't have that data in the rental product table, but we can populate those columns later if needed.
FROM valsanv_ZAGIMORE.rentalProducts r
JOIN valsanv_ZAGIMORE.vendor v ON r.vendorid = v.vendorid
JOIN valsanv_ZAGIMORE.category c ON r.categoryid = c.categoryid;

-- Now we can insert this data into the ProductDimension table in the ZAGIMORE_DS database
INSERT INTO valsanv_ZAGIMORE_DS.ProductDimension (ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly, ProductPriceMonthly)
SELECT r.productid, r.productname, r.vendorid, r.categoryid, v.vendorname, c.categoryname, "R", NULL, r.productpricedaily, r.productpriceweekly, NULL
FROM valsanv_ZAGIMORE.rentalProducts r
JOIN valsanv_ZAGIMORE.vendor v ON r.vendorid = v.vendorid
JOIN valsanv_ZAGIMORE.category c ON r.categoryid = c.categoryid;

TRUNCATE valsanv_ZAGIMORE_DS.ProductDimension; -- Clear the ProductDimension table before repopulating it
-- Using separate INSERT statements for sale and rental products were causing issues in auto increment fields, so we will use UNION keyword to combine the results of two queries into a single result set

-- SET ProductKey to AUTO_INCREMENT, and add a new column ProductPriceMonthly
-- Now let's use a combined query to extract data for both sale and rental products and insert into the ProductDimension table in the ZAGIMORE_DS database
-- 03 - Extracting data for both sale and rental products
INSERT INTO valsanv_ZAGIMORE_DS.ProductDimension (ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly, ProductPriceMonthly)
SELECT p.productid, p.productname, p.vendorid, p.categoryid, v.vendorname, c.categoryname, "S", p.productprice, NULL, NULL, NULL
FROM valsanv_ZAGIMORE.product p
JOIN valsanv_ZAGIMORE.vendor v ON p.vendorid = v.vendorid
JOIN valsanv_ZAGIMORE.category c ON p.categoryid = c.categoryid
UNION -- UNION keyword is used to combine the results of two queries into a single result set
SELECT r.productid, r.productname, r.vendorid, r.categoryid, v.vendorname, c.categoryname, "R", NULL, r.productpricedaily, r.productpriceweekly, NULL
FROM valsanv_ZAGIMORE.rentalProducts r
JOIN valsanv_ZAGIMORE.vendor v ON r.vendorid = v.vendorid
JOIN valsanv_ZAGIMORE.category c ON r.categoryid = c.categoryid;
-- Note: The UNION operator removes duplicate rows from the result set. If we want to include duplicate rows, we can use the UNION ALL operator instead.
-- This works only if the columns in both SELECT statements are in the same order and have the same data types, which is the case here since we are selecting the same columns from both tables.

-- =========================================================================================================================
-- Lecture 03/02/2026: FACT TABLE POPULATION
-- ========================================================================================================================= 

-- Extracting data from the sales table in ZAGIMORE into the sales_fact table in the ZAGIMORE_DS database
-- First, let's check the data in the valsanv_ZAGIMORE.sales table to ensure we have the correct columns and data types

-- Extracting the data from ZAGIMORE into the intermediate fact table in the ZAGIMORE_DS database
-- 01 - Extracting the revenue data for sales transactions
SELECT sv.noofitems * p.productprice AS DollarAmount, "Sale" AS RevenueSource, sv.tid, p.productid, s.storeid, s.tdate AS FullDate, s.customerid
FROM valsanv_ZAGIMORE.soldvia as sv, valsanv_ZAGIMORE.product p, valsanv_ZAGIMORE.salestransaction s
WHERE sv.productid = p.productid AND sv.tid = s.tid

-- 02 - Extracting the revenue data for rental transactions for daily rentals
SELECT rv.duration * r.productpricedaily AS DollarAmount, "Rental_Daily" AS RevenueSource, rv.tid, r.productid, rt.storeid, rt.tdate, rt.customerid
FROM valsanv_ZAGIMORE.rentvia as rv, valsanv_ZAGIMORE.rentalProducts as r, valsanv_ZAGIMORE.rentaltransaction rt
WHERE rv.productid = r.productid AND rv.tid = rt.tid
AND rv.rentaltype = "D"

-- 03 - Extracting the revenue data for rental transactions for weekly rentals
SELECT rv.duration * r.productpriceweekly AS DollarAmount, "Rental_Weekly" AS RevenueSource, rv.tid, r.productid, rt.storeid, rt.tdate, rt.customerid
FROM valsanv_ZAGIMORE.rentvia as rv, valsanv_ZAGIMORE.rentalProducts as r, valsanv_ZAGIMORE.rentaltransaction rt
WHERE rv.productid = r.productid AND rv.tid = rt.tid
AND rv.rentaltype = "W"

-- 04 - Extracting the revenue for all transactions
CREATE TABLE IF NOT EXISTS IntermediateFactTable AS 
SELECT sv.noofitems * p.productprice AS DollarAmount, "Sale" AS RevenueSource, sv.tid, p.productid, s.storeid, s.tdate AS FullDate, s.customerid
FROM valsanv_ZAGIMORE.soldvia as sv, valsanv_ZAGIMORE.product p, valsanv_ZAGIMORE.salestransaction s
WHERE sv.productid = p.productid AND sv.tid = s.tid
UNION
SELECT rv.duration * r.productpricedaily AS DollarAmount, "Rental_Daily" AS RevenueSource, rv.tid, r.productid, rt.storeid, rt.tdate AS FullDate, rt.customerid
FROM valsanv_ZAGIMORE.rentvia as rv, valsanv_ZAGIMORE.rentalProducts as r, valsanv_ZAGIMORE.rentaltransaction rt
WHERE rv.productid = r.productid AND rv.tid = rt.tid
AND rv.rentaltype = "D"
UNION
SELECT rv.duration * r.productpriceweekly AS DollarAmount, "Rental_Weekly" AS RevenueSource, rv.tid, r.productid, rt.storeid, rt.tdate AS FullDate, rt.customerid
FROM valsanv_ZAGIMORE.rentvia as rv, valsanv_ZAGIMORE.rentalProducts as r, valsanv_ZAGIMORE.rentaltransaction rt
WHERE rv.productid = r.productid AND rv.tid = rt.tid
AND rv.rentaltype = "W"

-- =========================================================================================================================
-- Lecture 03/04/2026: FACT TABLE POPULATION Continued
-- ========================================================================================================================= 

-- Mapping rows from intermediate fact table into the fact table
-- INSERT INTO RevenueFactTable(DollarAmount, RevenueSource, TID, ProductKey, StoreKey, CalendarKey, CustomerKey)
SELECT i.DollarAmount, i.RevenueSource, i.tid, cd.CustomerKey, sd.StoreKey, cad.CalendarKey, pd.ProductKey 
FROM IntermediateFactTable AS i, CustomerDimension AS cd, StoreDimension AS sd, CalendarDimension AS cad, ProductDimension AS pd
WHERE cd.CustomerID = i.customerid
AND sd.StoreID = i.storeid
AND cad.FullDate = i.FullDate
AND pd.ProductID = i.productid
AND ((i.RevenueSource = "Sale" AND pd.ProductType = "S")
OR (i.RevenueSource IN ("Rental_Weekly", "Rental_Daily") AND pd.ProductType = "R")) -- we have same product IDs under two different product types

-- NOTE:
/*
To compare the two mapping queries mentioned -- the one above and the one below:
The WHERE conditions here are logically equivalent to splitting the query into two SELECTs (one for Sale/S, one for Rental/R) and combining them.
This single SELECT will return all rows that match those conditions, including any duplicates produced by joins or duplicated data. 
*/

-- Mapping rows from intermediate fact table into the fact table
INSERT INTO RevenueFactTable(DollarAmount, RevenueSource, TID, CustomerKey, StoreKey, CalendarKey, ProductKey)
SELECT i.DollarAmount, i.RevenueSource, i.tid, cd.CustomerKey, sd.StoreKey, cad.CalendarKey, pd.ProductKey 
FROM IntermediateFactTable AS i, CustomerDimension AS cd, StoreDimension AS sd, CalendarDimension AS cad, ProductDimension AS pd
WHERE cd.CustomerID = i.customerid
AND sd.StoreID = i.storeid
AND cad.FullDate = i.FullDate
AND pd.ProductID = i.productid
AND i.RevenueSource = "Sale" AND pd.ProductType = "S" -- we have same product IDs under two different product types
UNION
SELECT i.DollarAmount, i.RevenueSource, i.tid, cd.CustomerKey, sd.StoreKey, cad.CalendarKey, pd.ProductKey 
FROM IntermediateFactTable AS i, CustomerDimension AS cd, StoreDimension AS sd, CalendarDimension AS cad, ProductDimension AS pd
WHERE cd.CustomerID = i.customerid
AND sd.StoreID = i.storeid
AND cad.FullDate = i.FullDate
AND pd.ProductID = i.productid
AND i.RevenueSource IN ("Rental_Weekly", "Rental_Daily") AND pd.ProductType = "R" -- we have same product IDs under two different product types
/* These two SELECTs implement the same filter logic as the single-query version, just split by RevenueSource/ProductType.
Using UNION combines the two result sets and removes any rows that are completely identical across both branches (all selected columns), which can help avoid inserting duplicate fact rows created by overlapping conditions.
UNION is slightly more resource‑intensive than a single SELECT (or UNION ALL) because it must perform a distinct step to remove duplicate rows. */

-- Loading data from ZAGIMORE_DS into ZAGIMORE_DW
-- 01 - CUSTOMER DIMENSION
INSERT INTO valsanv_ZAGIMORE_DW.CustomerDimension (CustomerKey, CustomerID, CustomerName, CustomerZip)
SELECT CustomerKey, CustomerID, CustomerName, CustomerZip -- use of SELECT * is not recommended in production code since it can lead to unexpected results if the table structure changes (e.g., if new columns are added or existing columns are removed), and it can also have performance implications since it retrieves all columns from the table, even those that are not needed for the specific query. It's generally better to explicitly specify the columns you want to retrieve to ensure that your query returns the expected results and performs efficiently.
FROM valsanv_ZAGIMORE_DS.CustomerDimension;

-- 02 - STORE DIMENSION
INSERT INTO valsanv_ZAGIMORE_DW.StoreDimension (StoreKey, StoreID, StoreZip, RegionID, RegionName)
SELECT StoreKey, StoreID, StoreZip, RegionID, RegionName
FROM valsanv_ZAGIMORE_DS.StoreDimension;

-- 03 - PRODUCT DIMENSION
INSERT INTO valsanv_ZAGIMORE_DW.ProductDimension (ProductKey, ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly)
SELECT ProductKey, ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly
FROM valsanv_ZAGIMORE_DS.ProductDimension;

-- 04 - CALENDAR DIMENSION
INSERT INTO valsanv_ZAGIMORE_DW.CalendarDimension (CalendarKey, FullDate, MonthYear, CalendarYear)
SELECT CalendarKey, FullDate, MonthYear, CalendarYear
FROM valsanv_ZAGIMORE_DS.CalendarDimension;

-- 05 - FACT TABLE
INSERT INTO valsanv_ZAGIMORE_DW.RevenueFactTable (DollarAmount, RevenueSource, TID, ProductKey, StoreKey, CalendarKey, CustomerKey)
SELECT DollarAmount, RevenueSource, TID, ProductKey, StoreKey, CalendarKey, CustomerKey
FROM valsanv_ZAGIMORE_DS.RevenueFactTable;

-- =========================================================================================================================
-- Lecture 03/09/2026: Aggregates & Snapshots
-- =========================================================================================================================

-- AGGREGATES
-- Create a table of daily sales (units sold and revenue generated) to customers in stores aggregated by product category
-- One-way aggregate by ProductCategory

-- Checking/visualizing the RevenueFactTable (ZAGIMORE_DS) data before aggregation; Degenerate dimensions dropped
SELECT SUM(DollarAmount) AS TotalRevenue, CustomerKey, StoreKey, CalendarKey, ProductKey -- we'll replace ProductKey with ProductCategoryKey for aggregation
FROM RevenueFactTable
GROUP BY CustomerKey, StoreKey, CalendarKey, ProductKey;

-- Create ProductCategoryDimension in ZAGIMORE_DS
CREATE Table ProductCategoryDimension
(
  ProductCategoryKey INT NOT NULL AUTO_INCREMENT,
  ProductCategoryID CHAR(2),
  ProductCategoryName VARCHAR(25),
  PRIMARY KEY (ProductCategoryKey)
);

-- Populate ProductCategoryDimension using ProductDimension data in ZAGIMORE_DS
INSERT INTO ProductCategoryDimension (ProductCategoryID, ProductCategoryName)
SELECT DISTINCT CategoryID, CategoryName
FROM ProductDimension;

-- One-way aggregate by Product Category in ZAGIMORE_DS
CREATE TABLE OneWayProductCategoryAggregate AS
SELECT SUM(r.DollarAmount) AS TotalRevenue, r.CustomerKey, r.StoreKey, r.CalendarKey, pcd.ProductCategoryKey
FROM RevenueFactTable r, ProductCategoryDimension pcd, ProductDimension pd
WHERE pd.ProductKey = r.ProductKey 
AND pd.CategoryID = pcd.ProductCategoryID
GROUP BY r.CustomerKey, r.StoreKey, r.CalendarKey, pcd.ProductCategoryKey;

-- Create ProductCategoryDimension in ZAGIMORE_DW
CREATE Table ProductCategoryDimension
(
  ProductCategoryKey INT, -- Notice that ProductCategoryKey is not NOT NULL AUTO_INCREMENT,
  ProductCategoryID CHAR(2),
  ProductCategoryName VARCHAR(25),
  PRIMARY KEY (ProductCategoryKey)
);

-- One-way aggregate by Product Category in ZAGIMORE_DW
CREATE TABLE OneWayProductCategoryAggregate
(TotalRevenue DECIMAL(30,2),
 CustomerKey INT,
 StoreKey INT,
 CalendarKey INT,
 ProductCategoryKey INT,
 PRIMARY KEY (CustomerKey, StoreKey, CalendarKey, ProductCategoryKey)
);

-- =========================================================================================================================
-- Lecture 03/11/2026: Aggregates & Snapshots - Continued
-- =========================================================================================================================

-- Connect the Dimensions and the new Aggregate Fact tables in ZAGIMORE_DW
ALTER TABLE OneWayProductCategoryAggregate
ADD FOREIGN KEY (CustomerKey) REFERENCES CustomerDimension(CustomerKey),
ADD FOREIGN KEY (StoreKey) REFERENCES StoreDimension(StoreKey),
ADD FOREIGN KEY (CalendarKey) REFERENCES CalendarDimension(CalendarKey),
ADD FOREIGN KEY (ProductCategoryKey) REFERENCES ProductCategoryDimension(ProductCategoryKey);

-- alternate syntax used by Professor in class
ALTER TABLE OneWayProductCategoryAggregate
ADD
(
  FOREIGN KEY (CustomerKey) REFERENCES CustomerDimension(CustomerKey),
  FOREIGN KEY (StoreKey) REFERENCES StoreDimension(StoreKey),
  FOREIGN KEY (CalendarKey) REFERENCES CalendarDimension(CalendarKey),
  FOREIGN KEY (ProductCategoryKey) REFERENCES ProductCategoryDimension(ProductCategoryKey)
);
-- Note: Foreign Keys we can add over and over again, but not primary keys. For primary keys, we need to drop and re-create the table??
-- If we hadn't defined the primary key when we created the aggregate fact table, we can define it here.

-- Populate ProductCategoryDimension in ZAGIMORE_DW from ProductCategoryDimension in ZAGIMORE_DS
INSERT INTO valsanv_ZAGIMORE_DW.ProductCategoryDimension (ProductCategoryKey, ProductCategoryID, ProductCategoryName)
SELECT ProductCategoryKey, ProductCategoryID, ProductCategoryName
FROM valsanv_ZAGIMORE_DS.ProductCategoryDimension;

-- Loading/Populate the new OneWayProductCategoryAggregate Fact table in ZAGIMORE_DW from OneWayProductCategoryAggregate in ZAGIMORE_DS
INSERT INTO valsanv_ZAGIMORE_DW.OneWayProductCategoryAggregate (TotalRevenue, CustomerKey, StoreKey, CalendarKey, ProductCategoryKey)
SELECT TotalRevenue, CustomerKey, StoreKey, CalendarKey, ProductCategoryKey
FROM valsanv_ZAGIMORE_DS.OneWayProductCategoryAggregate;

-- SNAPSHOTS
-- Create a daily store snapshot of sales with following facts: revenue generated, total number of transactions and average revenue per day and store.

-- Check data for Daily Store Snapshot in ZAGIMORE_DS
SELECT SUM(DollarAmount) AS TotalRevenue, COUNT(DISTINCT TID) AS TotalNoOfTxns, COUNT(TID) AS TotalNoLineItems, ROUND(SUM(DollarAmount) / COUNT(DISTINCT TID), 2) AS AvgRevenuePerTxn, ROUND(AVG(DollarAmount), 2) AS AvgRevenuePerLineItem, StoreKey, CalendarKey -- this version of MySQL doesn't support using aliases like ROUND(TotalRevenue / TotalNoOfTxns, 2) AS AvgRevenuePerTxn
FROM valsanv_ZAGIMORE_DS.RevenueFactTable
GROUP BY StoreKey, CalendarKey
-- there's ambiguity in the average revenue asked. So we'll create two possible interpretations
-- 1. Average revenue per transaction
-- 2. Average revenue per line item

-- Create DailyStoreSnapshot in ZAGIMORE_DS
CREATE Table DailyStoreSnapshot
(
  TotalRevenue DECIMAL(30,2),
  TotalNoOfTxns INT,
  TotalNoLineItems INT,
  AvgRevenuePerTxn DECIMAL(30,2),
  AvgRevenuePerLineItem DECIMAL(30,2),
  StoreKey INT,
  CalendarKey INT,
  PRIMARY KEY (StoreKey, CalendarKey)
);

-- Populate DailyStoreSnapshot in ZAGIMORE_DS
INSERT INTO valsanv_ZAGIMORE_DS.DailyStoreSnapshot (TotalRevenue, TotalNoOfTxns, TotalNoLineItems, AvgRevenuePerTxn, AvgRevenuePerLineItem, StoreKey, CalendarKey)
SELECT SUM(DollarAmount) AS TotalRevenue, COUNT(DISTINCT TID) AS TotalNoOfTxns, COUNT(TID) AS TotalNoLineItems, ROUND(SUM(DollarAmount) / COUNT(DISTINCT TID), 2) AS AvgRevenuePerTxn, ROUND(AVG(DollarAmount), 2) AS AvgRevenuePerLineItem, StoreKey, CalendarKey -- this version of MySQL doesn't support using aliases like ROUND(TotalRevenue / TotalNoOfTxns, 2) AS AvgRevenuePerTxn
FROM valsanv_ZAGIMORE_DS.RevenueFactTable
GROUP BY StoreKey, CalendarKey;

-- Create DailyStoreSnapshot in ZAGIMORE_DW
CREATE Table DailyStoreSnapshot
(
  TotalRevenue DECIMAL(30,2),
  TotalNoOfTxns INT,
  TotalNoLineItems INT,
  AvgRevenuePerTxn DECIMAL(30,2),
  AvgRevenuePerLineItem DECIMAL(30,2),
  StoreKey INT,
  CalendarKey INT,
  PRIMARY KEY (StoreKey, CalendarKey)
);

-- Connect the Dimensions to the new Snapshot table in ZAGIMORE_DW
ALTER TABLE DailyStoreSnapshot
ADD FOREIGN KEY (StoreKey) REFERENCES StoreDimension(StoreKey),
ADD FOREIGN KEY (CalendarKey) REFERENCES CalendarDimension(CalendarKey);

-- Populate DailyStoreSnapshot in ZAGIMORE_DW from DailyStoreSnapshot in ZAGIMORE_DS
INSERT INTO valsanv_ZAGIMORE_DW.DailyStoreSnapshot (TotalRevenue, TotalNoOfTxns, TotalNoLineItems, AvgRevenuePerTxn, AvgRevenuePerLineItem, StoreKey, CalendarKey)
SELECT TotalRevenue, TotalNoOfTxns, TotalNoLineItems, AvgRevenuePerTxn, AvgRevenuePerLineItem, StoreKey, CalendarKey
FROM valsanv_ZAGIMORE_DS.DailyStoreSnapshot;

-- =========================================================================================================================
-- Assignment ETL Part4: One way aggregation by Product Category and One way aggregation by Region - Due: Monday, March 23, 2026, 11:00 AM
-- =========================================================================================================================

-- 03/17/2026: renamed the Customer_Dimensions table to CustomerDimension in both ZAGIMORE_DS and ZAGIMORE_DW. This update is done in both the ZAGIMORE_DS_PopulateCode.sql and ZAGIMORE_DW_PopulateCode.sql as well
RENAME TABLE valsanv_ZAGIMORE_DS.Customer_Dimensions TO valsanv_ZAGIMORE_DS.CustomerDimension;
RENAME TABLE valsanv_ZAGIMORE_DW.Customer_Dimensions TO valsanv_ZAGIMORE_DW.CustomerDimension;

-- One way aggregation by Product Category
-- This is already done?? Check and confirm -- IS THIS THE SAME ONE DONE IN CLASS??


-- One way aggregation by Region
-- Checking/visualizing data for One way aggregation by Region
SELECT SUM(r.DollarAmount) AS TotalRevenue, r.CustomerKey, sd.RegionName, r.CalendarKey, r.ProductKey
FROM RevenueFactTable r, StoreDimension sd
WHERE r.StoreKey = sd.StoreKey
GROUP BY r.CustomerKey, sd.RegionName, r.CalendarKey, r.ProductKey
ORDER BY r.CalendarKey, sd.RegionName, r.CustomerKey, r.ProductKey

-- Create RegionDimension in ZAGIMORE_DS
CREATE Table RegionDimension
(
  RegionKey INT NOT NULL AUTO_INCREMENT, -- Notice that RegionKey is not set to AUTO_INCREMENT
  RegionID CHAR(1) NOT NULL,
  RegionName VARCHAR(25) NOT NULL,
  PRIMARY KEY (RegionKey)
);

-- Populate RegionDimension in ZAGIMORE_DS
INSERT INTO valsanv_ZAGIMORE_DS.RegionDimension (RegionID, RegionName)
SELECT DISTINCT RegionID, RegionName
FROM valsanv_ZAGIMORE_DS.StoreDimension;

-- Check data for One way aggregation by Region (now using the RegionDimension table in ZAGIMORE_DS)
SELECT SUM(r.DollarAmount) AS TotalRevenue, r.CustomerKey, rd.RegionID, rd.RegionName, r.CalendarKey, r.ProductKey
FROM RevenueFactTable r, StoreDimension sd, RegionDimension rd
WHERE r.StoreKey = sd.StoreKey
AND sd.RegionID = rd.RegionID
GROUP BY r.CustomerKey, rd.RegionID, rd.RegionName, r.CalendarKey, r.ProductKey
ORDER BY r.CalendarKey, rd.RegionName, r.CustomerKey, r.ProductKey;

-- Create OneWayRegionAggregate in ZAGIMORE_DS
CREATE Table OneWayRegionAggregate
(
  TotalRevenue DECIMAL(30,2) NOT NULL,
  CustomerKey INT NOT NULL,
  RegionKey INT NOT NULL,
  CalendarKey INT NOT NULL,
  ProductKey INT NOT NULL
  -- PRIMARY KEY (CustomerKey, RegionKey, CalendarKey, ProductKey) -- we won't define the primary key in DS, but we will define it in DW
);

-- Populate OneWayRegionAggregate in ZAGIMORE_DS
INSERT INTO valsanv_ZAGIMORE_DS.OneWayRegionAggregate (TotalRevenue, CustomerKey, RegionKey, CalendarKey, ProductKey)
SELECT SUM(r.DollarAmount) AS TotalRevenue, r.CustomerKey, rd.RegionKey, r.CalendarKey, r.ProductKey
FROM RevenueFactTable r, StoreDimension sd, RegionDimension rd
WHERE r.StoreKey = sd.StoreKey
AND sd.RegionID = rd.RegionID
GROUP BY r.CustomerKey, rd.RegionKey, r.CalendarKey, r.ProductKey;

-- Create RegionDimension in ZAGIMORE_DW
CREATE Table RegionDimension
(
  RegionKey INT NOT NULL, -- Notice that RegionKey is not set to AUTO_INCREMENT
  RegionID CHAR(1) NOT NULL,
  RegionName VARCHAR(25) NOT NULL,
  PRIMARY KEY (RegionKey)
);

-- Populate RegionDimension in ZAGIMORE_DW from RegionDimension in ZAGIMORE_DS
INSERT INTO valsanv_ZAGIMORE_DW.RegionDimension (RegionKey, RegionID, RegionName)
SELECT RegionKey, RegionID, RegionName
FROM valsanv_ZAGIMORE_DS.RegionDimension;

-- Create OneWayRegionAggregate in ZAGIMORE_DW
CREATE Table OneWayRegionAggregate
(
  TotalRevenue DECIMAL(30,2) NOT NULL,
  CustomerKey INT NOT NULL,
  RegionKey INT NOT NULL,
  CalendarKey INT NOT NULL,
  ProductKey INT NOT NULL,
  PRIMARY KEY (CustomerKey, RegionKey, CalendarKey, ProductKey) -- Note that we define the primary key in DW
);

-- Connect the Dimensions to the new OneWayRegionAggregate table in ZAGIMORE_DW
ALTER TABLE OneWayRegionAggregate
ADD FOREIGN KEY (CustomerKey) REFERENCES CustomerDimension(CustomerKey),
ADD FOREIGN KEY (RegionKey) REFERENCES RegionDimension(RegionKey),
ADD FOREIGN KEY (CalendarKey) REFERENCES CalendarDimension(CalendarKey),
ADD FOREIGN KEY (ProductKey) REFERENCES ProductDimension(ProductKey);

-- Populate OneWayRegionAggregate in ZAGIMORE_DW from OneWayRegionAggregate in ZAGIMORE_DS
INSERT INTO valsanv_ZAGIMORE_DW.OneWayRegionAggregate (TotalRevenue, CustomerKey, RegionKey, CalendarKey, ProductKey)
SELECT TotalRevenue, CustomerKey, RegionKey, CalendarKey, ProductKey
FROM valsanv_ZAGIMORE_DS.OneWayRegionAggregate;

-- =========================================================================================================================
-- Lecture 03/23/2026: Aggregates & Snapshots - Continued
-- =========================================================================================================================

-- 6-c. Add the following derived facts to the daily store snapshot:  total revenue from the  footwear items sold,  number of transactions with more than $100 in revenue, total revenue from 'local' customers (criteria for local: first two digits of the zip code for the store and customer are same)

-- DailyStoreSnapshot - TotalFootwearRevenue
SELECT SUM(r.DollarAmount) AS TotalFootwearRevenue, r.StoreKey, r.CalendarKey
FROM RevenueFactTable r, ProductDimension pd
WHERE r.ProductKey = pd.ProductKey
AND pd.CategoryName = "Footwear" -- "Footwear" is the CategoryName for footwear products in the ProductDimension table
GROUP BY r.StoreKey, r.CalendarKey
ORDER BY r.StoreKey ASC, r.CalendarKey ASC;

-- DailyStoreSnapshot, Number of transactions with more than $100 in revenue -- [CHECK THIS QUERY]
SELECT -- SUM(DollarAmount) AS TotalRevenue, 
COUNT(DISTINCT TID) AS TotalNoOfTxns, 
r.StoreKey, r.CalendarKey
FROM RevenueFactTable r
GROUP BY r.StoreKey, r.CalendarKey
HAVING SUM(DollarAmount) > 100
ORDER BY r.StoreKey ASC, r.CalendarKey ASC;

-- DailyStoreSnapshot, Number of transactions with more than $100 in revenue
SELECT COUNT(DISTINCT TID) AS TotalNoOfTxns, r.StoreKey, r.CalendarKey
FROM RevenueFactTable r
GROUP BY r.StoreKey, r.CalendarKey
ORDER BY r.StoreKey ASC, r.CalendarKey ASC;

-- Query to group TotalRevenue by TID and filter out transactions with less than $100 in revenue
SELECT -- SUM(DollarAmount) AS TotalTxnRevenue, -- OPTIONAL - this was used just to see the total revenue for each transaction 
-- COUNT(DISTINCT TID) AS TotalNoOfTxns, -- OPTIONAL - just to show that total revenue calculated is per transaction
r.StoreKey, r.CalendarKey, r.TID
FROM RevenueFactTable r
GROUP BY r.StoreKey, r.CalendarKey, r.TID
HAVING SUM(DollarAmount) > 100 -- this version of MySQL doesn't support using alias "TotalTxnRevenue" here; otherwise, we could have written "HAVING TotalTxnRevenue > 100" 
ORDER BY r.StoreKey ASC, r.CalendarKey ASC;

-- Query to group TotalRevenue by TID and filter out transactions with less than $100 -- FINAL 
-- Now were creating a view using the query above. Here, we also dropped the optional fields, because we don't need them
CREATE VIEW RFTHundredPlus AS
SELECT r.StoreKey, r.CalendarKey, r.TID
FROM RevenueFactTable r
GROUP BY r.StoreKey, r.CalendarKey, r.TID
HAVING SUM(DollarAmount) > 100
ORDER BY r.StoreKey ASC, r.CalendarKey ASC;

-- DailyStoreSnapshot, Number of transactions with more than $100 in revenue
SELECT COUNT(DISTINCT r.TID) AS TotalNoOfTxnsHundredPlus, r.StoreKey, r.CalendarKey
FROM RFTHundredPlus r
GROUP BY r.StoreKey, r.CalendarKey
ORDER BY r.StoreKey ASC, r.CalendarKey ASC;

-- DailyStoreSnapshot, Local Customer Revenue
SELECT SUM(DollarAmount) AS TotalLocalCustomerRevenue, r.StoreKey, r.CalendarKey
FROM RevenueFactTable r, CustomerDimension cd, StoreDimension sd
WHERE r.CustomerKey = cd.CustomerKey
AND r.StoreKey = sd.StoreKey
AND LEFT(sd.StoreZip, 2) = LEFT(cd.CustomerZip, 2) -- the first two digits of the zip code for the store and customer are matched
-- OR sd.StoreZip = cd.CustomerZip -- for exactly matching; the two zip codes must be strictly equal
GROUP BY r.StoreKey, r.CalendarKey;

/* -- DO IT YOURSELF
-- DailyStoreSnapshot_2 table is not required; write the query to modify the existing DailyStoreSnapshot table
CREATE TABLE DailyStoreSnapshot_2
(
  TotalRevenue DECIMAL(30,2),
  TotalNoOfTxns INT,
  TotalNoLineItems INT,
  AvgRevenuePerTxn DECIMAL(30,2),
  AvgRevenuePerLineItem DECIMAL(30,2),
  TotalFootwareRevenue DECIMAL(30,2), -- NEW field
  TotalNoOfTxnsHundredPlus INT, -- NEW field
  TotalLocalCustomerRevenue DECIMAL(30,2), -- NEW field
  StoreKey INT,
  CalendarKey INT
  -- PRIMARY KEY (StoreKey, CalendarKey) -- do not define the primary key in DS
); */

-- Since I had already created the DailyStoreSnapshot table, I can just alter the existing table to add the new fields
ALTER TABLE valsanv_ZAGIMORE_DS.DailyStoreSnapshot
ADD COLUMN TotalFootwareRevenue DECIMAL(30,2),
ADD COLUMN TotalNoOfTxnsHundredPlus INT,
ADD COLUMN TotalLocalCustomerRevenue DECIMAL(30,2);
-- Reorder the columns so that the primary key is at the end
ALTER TABLE valsanv_ZAGIMORE_DS.DailyStoreSnapshot
MODIFY COLUMN StoreKey INT AFTER TotalLocalCustomerRevenue;
ALTER TABLE valsanv_ZAGIMORE_DS.DailyStoreSnapshot
MODIFY COLUMN CalendarKey INT AFTER StoreKey;

-- Populate the altered DailySnapshot table in ZAGIMORE_DS

/* INSERT INTO DailyStoreSnapshot_2(TotalRevenue, TotalNoOfTxns, TotalNoLineItems, AvgRevenuePerTxn, AvgRevenuePerLineItem, TotalFootwareRevenue, TotalNoOfTxnsHundredPlus, TotalLocalCustomerRevenue, StoreKey, CalendarKey)
SELECT SUM(DollarAmount) AS TotalRevenue, COUNT(DISTINCT TID) AS TotalNoOfTxns, COUNT(DISTINCT ProductKey) AS TotalNoLineItems, 
AVG(DollarAmount) AS AvgRevenuePerTxn, AVG(DollarAmount) AS AvgRevenuePerLineItem, 
SUM(DollarAmount) AS TotalFootwareRevenue, COUNT(DISTINCT TID) AS TotalNoOfTxnsHundredPlus, 
SUM(DollarAmount) AS TotalLocalCustomerRevenue, r.StoreKey, r.CalendarKey
FROM RFTHundredPlus r */

CREATE VIEW RFTFootwear AS
SELECT SUM(r.DollarAmount) AS TotalFootwareRevenue, r.StoreKey, r.CalendarKey
FROM RevenueFactTable r, ProductDimension pd
WHERE r.ProductKey = pd.ProductKey
AND pd.CategoryName = "Footwear"
GROUP BY r.StoreKey, r.CalendarKey
ORDER BY r.StoreKey ASC, r.CalendarKey ASC;


UPDATE DailyStoreSnapshot ds, RFTFootwear rft
SET ds.TotalFootwareRevenue = rft.TotalFootwareRevenue
-- Check the rows before UPDATE
/* SELECT *
FROM DailyStoreSnapshot ds, RFTFootwear rft */
WHERE ds.StoreKey = rft.StoreKey 
AND ds.CalendarKey = rft.CalendarKey; 

-- replace the NULL values in the TotalFootwareRevenue column with 0
UPDATE DailyStoreSnapshot ds
SET ds.TotalFootwareRevenue = 0
-- Check the rows before UPDATE
/* SELECT *
FROM DailyStoreSnapshot ds */
WHERE ds.TotalFootwareRevenue IS NULL;

-- =========================================================================================================================
-- Lecture 03/25/2026: Aggregates & Snapshots - Continued
-- =========================================================================================================================

-- replace the NULL values in the TotalNoOfTxnsHundredPlus column with 0
UPDATE DailyStoreSnapshot ds
SET ds.TotalNoOfTxnsHundredPlus = 0
-- Check the rows before UPDATE
/* SELECT * 
FROM DailyStoreSnapshot ds */
WHERE ds.TotalNoOfTxnsHundredPlus IS NULL;

-- replace the NULL values in the TotalLocalCustomerRevenue column with 0
UPDATE DailyStoreSnapshot ds
SET ds.TotalLocalCustomerRevenue = 0
-- Check the rows before UPDATE
/* SELECT *
FROM DailyStoreSnapshot ds */
WHERE ds.TotalLocalCustomerRevenue IS NULL;

-- Create a view for TotalNoOfTxnsHundredPlus
CREATE VIEW HighNoOfTxns AS
SELECT COUNT(DISTINCT TID) AS TotalNoOfTxnsHundredPlus, r.StoreKey, r.CalendarKey
FROM RFTHundredPlus r
GROUP BY r.StoreKey, r.CalendarKey
ORDER BY r.StoreKey ASC, r.CalendarKey ASC;

UPDATE DailyStoreSnapshot ds, HighNoOfTxns hnt
SET ds.TotalNoOfTxnsHundredPlus = hnt.TotalNoOfTxnsHundredPlus
-- Check the rows before UPDATE
/* SELECT *
FROM DailyStoreSnapshot ds, HighNoOfTxns hnt */
WHERE ds.StoreKey = hnt.StoreKey 
AND ds.CalendarKey = hnt.CalendarKey;

CREATE VIEW LocalCustomerRevenue AS
SELECT SUM(DollarAmount) AS TotalLocalCustomerRevenue, r.StoreKey, r.CalendarKey
FROM RevenueFactTable r, CustomerDimension cd, StoreDimension sd
WHERE r.CustomerKey = cd.CustomerKey
AND r.StoreKey = sd.StoreKey
AND LEFT(sd.StoreZip, 2) = LEFT(cd.CustomerZip, 2) -- the first two digits of the zip code for the store and customer are matched
-- OR sd.StoreZip = cd.CustomerZip -- for exactly matching; the two zip codes must be strictly equal
GROUP BY r.StoreKey, r.CalendarKey
ORDER BY r.StoreKey ASC, r.CalendarKey ASC;

-- Update the TotalLocalCustomerRevenue column
UPDATE DailyStoreSnapshot ds, LocalCustomerRevenue lcr
SET ds.TotalLocalCustomerRevenue = lcr.TotalLocalCustomerRevenue
-- Check the rows before UPDATE 
/* SELECT * 
FROM DailyStoreSnapshot ds, LocalCustomerRevenue lcr */
WHERE ds.StoreKey = lcr.StoreKey 
AND ds.CalendarKey = lcr.CalendarKey;

-- N.B. The views that we have created can be dropped now. It is not required to keep them in the database. I'll keep them for now, to understand the concept.

/* -- Method used in the class by the Professor
-- Create the DailyStoreSnapshot table in ZAGIMORE_DW
CREATE TABLE valsanv_ZAGIMORE_DW.DailyStoreSnapshot AS
SELECT * 
FROM valsanv_ZAGIMORE_DS.DailyStoreSnapshot */

-- Since I had already created the DailyStoreSnapshot table in ZAGIMORE_DW, I can just alter the existing table to add the new fields
ALTER TABLE valsanv_ZAGIMORE_DW.DailyStoreSnapshot
ADD COLUMN TotalFootwareRevenue DECIMAL(30,2),
ADD COLUMN TotalNoOfTxnsHundredPlus INT,
ADD COLUMN TotalLocalCustomerRevenue DECIMAL(30,2);
-- Reorder the columns so that the primary key is at the end
ALTER TABLE valsanv_ZAGIMORE_DW.DailyStoreSnapshot
MODIFY COLUMN StoreKey INT AFTER TotalLocalCustomerRevenue;
ALTER TABLE valsanv_ZAGIMORE_DW.DailyStoreSnapshot
MODIFY COLUMN CalendarKey INT AFTER StoreKey;

-- Populate the altered DailySnapshot table in ZAGIMORE_DW from DailyStoreSnapshot in ZAGIMORE_DS. We only need to insert data for the new columns since the data for the other columns already exist in the DailyStoreSnapshot table in ZAGIMORE_DW.
UPDATE valsanv_ZAGIMORE_DW.DailyStoreSnapshot dsw, valsanv_ZAGIMORE_DS.DailyStoreSnapshot dss
SET dsw.TotalFootwareRevenue = dss.TotalFootwareRevenue, dsw.TotalNoOfTxnsHundredPlus = dss.TotalNoOfTxnsHundredPlus, dsw.TotalLocalCustomerRevenue = dss.TotalLocalCustomerRevenue
WHERE dsw.StoreKey = dss.StoreKey 
AND dsw.CalendarKey = dss.CalendarKey;

-- INITIAL DATA WAREHOUSE LOADING is COMPLETED on 03/25/2023
-- INITIAL DATA WAREHOUSE LOADING is COMPLETED on 03/25/2023