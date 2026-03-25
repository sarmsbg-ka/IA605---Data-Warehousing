CREATE TABLE IF NOT EXISTS ProductDimension
(
  ProductKey INT NOT NULL AUTO_INCREMENT,
  ProductID CHAR(3) NOT NULL,
  ProductName VARCHAR(25) NOT NULL,
  VendorID CHAR(2) NOT NULL,
  CategoryID CHAR(2) NOT NULL,
  VendorName VARCHAR(25) NOT NULL,
  CategoryName VARCHAR(25) NOT NULL,
  ProductType CHAR(1) NOT NULL,
  ProductSalePrice NUMERIC(7,2),
  ProductPriceDaily NUMERIC(7,2),
  ProductPriceWeekly NUMERIC(7,2),
  ProductPriceMonthly NUMERIC(7,2),
  PRIMARY KEY (ProductKey)
);

CREATE TABLE IF NOT EXISTS StoreDimension
(
  StoreKey INT NOT NULL AUTO_INCREMENT,
  StoreID VARCHAR(3) NOT NULL,
  StoreZip CHAR(5) NOT NULL,
  RegionID CHAR(1) NOT NULL,
  RegionName VARCHAR(25) NOT NULL,
  PRIMARY KEY (StoreKey)
);

CREATE TABLE IF NOT EXISTS CalendarDimension
(
  CalendarKey INT NOT NULL AUTO_INCREMENT,
  FullDate DATE NOT NULL,
  MonthYear CHAR(6) NOT NULL,
  CalendarYear CHAR(4) NOT NULL,
  PRIMARY KEY (CalendarKey)
);

CREATE TABLE IF NOT EXISTS CustomerDimension
(
  CustomerKey INT NOT NULL AUTO_INCREMENT,
  CustomerID CHAR(7) NOT NULL,
  CustomerName VARCHAR(15) NOT NULL,
  CustomerZip CHAR(5) NOT NULL,
  PRIMARY KEY (CustomerKey)
);

CREATE TABLE IF NOT EXISTS RevenueFactTable
(
  DollarAmount NUMERIC(8,2) NOT NULL,
  RevenueSource VARCHAR(25) NOT NULL,
  TID VARCHAR(8) NOT NULL,
  ProductKey INT NOT NULL,
  StoreKey INT NOT NULL,
  CalendarKey INT NOT NULL,
  CustomerKey INT NOT NULL
);

-- Connect the Dimensions and the RevenueFactTable in ZAGIMORE_DW
ALTER TABLE RevenueFactTable
ADD 
(
FOREIGN KEY (ProductKey) REFERENCES ProductDimension(ProductKey),
FOREIGN KEY (StoreKey) REFERENCES StoreDimension(StoreKey),
FOREIGN KEY (CalendarKey) REFERENCES CalendarDimension(CalendarKey),
FOREIGN KEY (CustomerKey) REFERENCES CustomerDimension(CustomerKey),
PRIMARY KEY (TID, RevenueSource, ProductKey, StoreKey, CalendarKey, CustomerKey)
);