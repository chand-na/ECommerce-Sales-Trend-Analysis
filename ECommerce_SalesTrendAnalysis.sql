-- ============================================
-- STEP 1: Raw Data Exploration
-- ============================================

-- View raw data (first look)
SELECT * FROM staging_raw;

-- Check row count
SELECT COUNT(*) AS total_rows FROM staging_raw;  -- 541,909 rows

-- Check for NULLs in key columns
SELECT 
    SUM(CASE WHEN InvoiceNo IS NULL THEN 1 ELSE 0 END) AS null_invoice_num,
    SUM(CASE WHEN StockCode IS NULL THEN 1 ELSE 0 END) AS null_stock_code,
    SUM(CASE WHEN `Description` IS NULL THEN 1 ELSE 0 END) AS null_description,
    SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS null_quantity,
    SUM(CASE WHEN InvoiceDate IS NULL THEN 1 ELSE 0 END) AS null_invoice_date,
    SUM(CASE WHEN UnitPrice IS NULL THEN 1 ELSE 0 END) AS null_unit_price,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END) AS null_country
FROM staging_raw;

-- Basic distinct counts for understanding data diversity
SELECT 
    COUNT(DISTINCT InvoiceNo) AS total_orders,
    COUNT(DISTINCT CustomerID) AS unique_customers,
    COUNT(DISTINCT StockCode) AS unique_products,
    COUNT(DISTINCT Country) AS unique_countries
FROM staging_raw;

-- Check quantity and price range
SELECT 
    MIN(Quantity) AS min_quantity, MAX(Quantity) AS max_quantity,
    MIN(UnitPrice) AS min_price, MAX(UnitPrice) AS max_price
FROM staging_raw;


-- ============================================
-- STEP 2: Create Cleaned View
-- ============================================

-- Create a view with only valid sales data (positive quantity/price, no cancellations)
CREATE VIEW cleaned_sales AS
SELECT * 
FROM staging_raw
WHERE Quantity > 0
  AND UnitPrice > 0
  AND LEFT(InvoiceNo, 1) != 'C';

-- Preview cleaned data
SELECT * FROM cleaned_sales;


-- ============================================
-- STEP 3: Monthly Trends
-- ============================================

-- Monthly Order Volume
SELECT 
    DATE_FORMAT(InvoiceDate, '%y-%m') AS Month,
    COUNT(DISTINCT InvoiceNo) AS TotalOrders
FROM cleaned_sales
WHERE DATE_FORMAT(InvoiceDate, '%Y-%m-%d %H:%i:%s') != '0000-00-00 00:00:00'
GROUP BY Month
ORDER BY Month;

-- Monthly Total Units Sold
SELECT 
    DATE_FORMAT(InvoiceDate, '%y-%m') AS Month,
    SUM(Quantity) AS TotalUnitsSold
FROM cleaned_sales
WHERE DATE_FORMAT(InvoiceDate, '%Y-%m-%d %H:%i:%s') != '0000-00-00 00:00:00'
GROUP BY Month
ORDER BY Month;

-- Monthly Unique Customers
SELECT 
    DATE_FORMAT(InvoiceDate, '%y-%m') AS Month,
    COUNT(DISTINCT CustomerID) AS UniqueCustomerCount
FROM cleaned_sales
WHERE DATE_FORMAT(InvoiceDate, '%Y-%m-%d %H:%i:%s') != '0000-00-00 00:00:00'
GROUP BY Month
ORDER BY Month;


-- ============================================
-- STEP 4: Product and Country Insights
-- ============================================

-- Top 10 Selling Products by Quantity
SELECT 
    StockCode, Description, SUM(Quantity) AS TotalUnitsSold
FROM cleaned_sales
GROUP BY StockCode, Description
ORDER BY TotalUnitsSold DESC
LIMIT 10;

-- Top 10 Countries by Unique Orders
SELECT 
    Country, COUNT(DISTINCT InvoiceNo) AS UniqueOrders
FROM cleaned_sales
GROUP BY Country
ORDER BY UniqueOrders DESC
LIMIT 10;


-- ============================================
-- STEP 5: Temporal Patterns
-- ============================================

-- Orders by Day of the Week
SELECT 
    DAYNAME(InvoiceDate) AS DayOfWeek,
    COUNT(DISTINCT InvoiceNo) AS TotalOrders
FROM cleaned_sales
WHERE DATE_FORMAT(InvoiceDate, '%Y-%m-%d %H:%i:%s') != '0000-00-00 00:00:00'
GROUP BY DayOfWeek
ORDER BY FIELD(DayOfWeek, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');

-- Orders by Hour of the Day
SELECT 
    HOUR(InvoiceDate) AS HourOfDay,
    COUNT(DISTINCT InvoiceNo) AS TotalOrders
FROM cleaned_sales
WHERE DATE_FORMAT(InvoiceDate, '%Y-%m-%d %H:%i:%s') != '0000-00-00 00:00:00'
GROUP BY HourOfDay
ORDER BY HourOfDay;
