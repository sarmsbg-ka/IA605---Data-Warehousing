-- From 02/23/2026 Lecture: Calendar Dimension Population
DELIMITER $$
-- create procedure
CREATE PROCEDURE populate_calendar()

BEGIN

  DECLARE i INT DEFAULT 0;   
  DECLARE FullDate DATE DEFAULT '2013-01-01'; -- initialize the date to desired start date
-- create a loop
myloop: LOOP

    

	INSERT INTO CalendarDimension (FullDate) SELECT DATE_ADD(FullDate, INTERVAL 1 DAY);
    -- increment the date by 1 day
    SET i=i+1;
    IF i=8000 then

            LEAVE myloop;

    END IF;

END LOOP myloop;



END;


-- Patricia's code for calendar population #1
DELIMITER $$
CREATE PROCEDURE populate_calendar()
BEGIN
  DECLARE i INT DEFAULT 0;   
  DECLARE FullDate DATE DEFAULT '2013-01-01';
myloop: LOOP
    
    INSERT INTO CalendarDimension(FullDate) SELECT DATE_ADD(FullDate, INTERVAL i DAY);
    SET i=i+1;
    IF i=8000 then
            LEAVE myloop;
    END IF;
END LOOP myloop;


END;

--////////////// CALENDAR DIMENSION //////////////  

CREATE PROCEDURE populateCalendar()
BEGIN
  DECLARE i INT DEFAULT 0;
  myloop:
  LOOP
  INSERT INTO Calendar_Dimension (Fulldate)
  SELECT DATE_ADD('2013-01-01', INTERVAL i DAY);
  SET i=i+1;
IF i=8000 then
LEAVE myloop;
END
IF;
END LOOP myloop;
UPDATE Calendar_Dimension
SET CalendarMonth = MONTH(Fulldate), CalendarYear = YEAR(Fulldate),MonthYear = CONCAT(CalendarMonth,CalendarYear);
END;

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
-- From 02/23/2026 Lecture: Customer Dimension Population
-- Populate the Customer_Dimensions table with data from the valsanv_ZAGIMORE.customer table

-- First, let's check the data in the valsanv_ZAGIMORE.customer table to ensure we have the correct columns and data types
SELECT c.customerid, c.customername, c.customerzip
FROM valsanv_ZAGIMORE.customer c;

INSERT INTO valsanv_ZAGIMORE_DS.Customer_Dimensions (CustomerID, CustomerName, CustomerZip)
SELECT c.customerid, c.customername, c.customerzip
FROM valsanv_ZAGIMORE.customer c;

-- If we need to clear the Customer_Dimensions table before repopulating it, we can use the following command:
-- NOTE: This will delete all the data in the Customer_Dimensions table, so use with caution!
-- This will reset the auto-increment counter to 1 as well, which is often desirable when repopulating a dimension table.
TRUNCATE valsanv_ZAGIMORE_DS.Customer_Dimensions; -- Clear the Customer_Dimensions table before repopulating it



-- STORE DIMENSION POPULATION
-- Code for extracting data from store and region tables in ZAGIMORE into the StoreDimension table in the ZAGIMORE_DS database
-- First, let's check the data in the valsanv_ZAGIMORE.store and valsanv_ZAGIMORE.region tables to ensure we have the correct columns and data types
SELECT 	s.storeid,	s.storezip,	s.regionid,	r.regionname	-- regionid can be r.regionid or s.regionid since they are the same, but we will use s.regionid to avoid confusion
FROM valsanv_ZAGIMORE.region r
JOIN valsanv_ZAGIMORE.store s ON r.RegionID = s.RegionID;

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
INSERT INTO valsanv_ZAGIMORE_DS.ProductDimension (ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly)
SELECT p.productid, p.productname, p.vendorid, p.categoryid, v.vendorname, c.categoryname, "S", p.productprice, NULL, NULL
FROM valsanv_ZAGIMORE.product p
JOIN valsanv_ZAGIMORE.vendor v ON p.vendorid = v.vendorid
JOIN valsanv_ZAGIMORE.category c ON p.categoryid = c.categoryid;

-- Now for the rental product type
-- 02 - Extracting data for products with product type "Rental"
SELECT r.productid, r.productname, r.vendorid, r.categoryid, v.vendorname, c.categoryname, "R", NULL, r.productpricedaily, r.productpriceweekly -- "R" for "Rental" since we don't have a product type column in the rental product table, but we can assume all rental products are for rent. NULL value for ProductSalePrice since rental products don't have a sale price.
FROM valsanv_ZAGIMORE.rentalProducts r
JOIN valsanv_ZAGIMORE.vendor v ON r.vendorid = v.vendorid
JOIN valsanv_ZAGIMORE.category c ON r.categoryid = c.categoryid;

-- Now we can insert this data into the ProductDimension table in the ZAGIMORE_DS database
INSERT INTO valsanv_ZAGIMORE_DS.ProductDimension (ProductID, ProductName, VendorID, CategoryID, VendorName, CategoryName, ProductType, ProductSalePrice, ProductPriceDaily, ProductPriceWeekly)
SELECT r.productid, r.productname, r.vendorid, r.categoryid, v.vendorname, c.categoryname, "R", NULL, r.productpricedaily, r.productpriceweekly
FROM valsanv_ZAGIMORE.rentalProducts r
JOIN valsanv_ZAGIMORE.vendor v ON r.vendorid = v.vendorid
JOIN valsanv_ZAGIMORE.category c ON r.categoryid = c.categoryid;
