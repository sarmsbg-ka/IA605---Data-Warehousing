CREATE TABLE ProductDimension
(
  ProductKey INT NOT NULL,
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
  PRIMARY KEY (ProductKey)
);
CREATE TABLE StoreDimension
(
  StoreKey INT NOT NULL,
  StoreID VARCHAR(3) NOT NULL,
  StoreZip CHAR(5) NOT NULL,
  RegionID CHAR(1) NOT NULL,
  RegionName VARCHAR(25) NOT NULL,
  PRIMARY KEY (StoreKey)
);
CREATE TABLE CalendarDimension
(
  CalendarKey INT NOT NULL,
  FullDate DATE NOT NULL,
  MonthYear CHAR(6) NOT NULL,
  CalendarYear CHAR(4) NOT NULL,
  PRIMARY KEY (CalendarKey)
);
CREATE TABLE CustomerDimension
(
  CustomerKey INT NOT NULL,
  CustomerID CHAR(7) NOT NULL,
  CustomerName VARCHAR(15) NOT NULL,
  CustomerZip CHAR(5) NOT NULL,
  PRIMARY KEY (CustomerKey)
);
-- do not connect the fact table to the dimensions and define the primary key
CREATE TABLE RevenueFactTable
(
  DollarAmount NUMERIC(8,2) NOT NULL,
  RevenueSource VARCHAR(25) NOT NULL,
  TID VARCHAR(8) NOT NULL,
  ProductKey INT NOT NULL,
  StoreKey INT NOT NULL,
  CalendarKey INT NOT NULL,
  CustomerKey INT NOT NULL
);