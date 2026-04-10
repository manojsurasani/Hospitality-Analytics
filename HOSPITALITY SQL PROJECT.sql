
CREATE DATABASE hospitality_project_db;
USE hospitality_project_db;

-- Table for Fact_Booking
CREATE TABLE Fact_Booking (
    booking_id VARCHAR(50) PRIMARY KEY,
    property_id INT,
    booking_date DATE,
    check_in_date DATE,
    checkout_date DATE,
    no_guests INT,
    room_category VARCHAR(10),
    booking_platform VARCHAR(50),
    ratings_given INT,
    booking_status VARCHAR(50),
    revenue_generated INT,
    revenue_realized INT,
    property_name VARCHAR(100),
    category VARCHAR(50),
    city VARCHAR(50),
    room_class VARCHAR(50),
    week_no VARCHAR(10),
    day_type VARCHAR(20),
    cancellation INT
);

-- Table for Fact_Aggregated_Bookings
CREATE TABLE fact_aggregated_bookings (
    property_id INT,
    check_in_date DATE,
    room_category VARCHAR(10),
    successful_bookings INT,
    capacity INT
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Fact_Booking.csv' 
INTO TABLE Fact_Booking 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(booking_id, property_id, @booking_date, @check_in_date, @checkout_date, no_guests, room_category, booking_platform, ratings_given, booking_status, revenue_generated, revenue_realized, property_name, category, city, room_class, week_no, day_type, cancellation)
SET 
    booking_date = STR_TO_DATE(@booking_date, '%m/%d/%Y'),
    check_in_date = STR_TO_DATE(@check_in_date, '%m/%d/%Y'),
    checkout_date = STR_TO_DATE(@checkout_date, '%m/%d/%Y');

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/fact_aggregated_bookings.csv' 
INTO TABLE fact_aggregated_bookings 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(property_id, @check_in_date, room_category, successful_bookings, capacity)
SET 
    check_in_date = STR_TO_DATE(@check_in_date, '%d-%b-%y');

SELECT * FROM Fact_Booking;
SELECT * FROM fact_aggregated_bookings;

----- 1.Total Revenue
SELECT 
   concat(round(sum(revenue_realized) / 1000000, 2) ,'M') AS Total_Revenue
FROM Fact_Booking;

----- 2.Occupancy Rate
SELECT 
  concat(round((SUM(successful_bookings) / SUM(capacity)) * 100, 2), '%') AS Occupancy_Rate
FROM fact_aggregated_bookings;

----- 3.Cancellation Rate
SELECT 
concat(round((SUM(CASE WHEN booking_status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*)) * 100 , 2), '%') AS Cancellation_Rate
FROM Fact_Booking;

----- 4.Total Bookings
SELECT 
  concat(round(COUNT(booking_id) /1000 , 2), 'K')AS Total_Bookings
FROM Fact_Booking;

----- 5.Trend Analysis (City-wise Revenue Trend (Weekly))
SELECT 
    `week_no`,
    `city`,
    SUM(revenue_realized) AS weekly_revenue
FROM Fact_Booking
GROUP BY `week_no`, `city`
ORDER BY `week_no`, weekly_revenue DESC;

----- 5.2 Booking Platform Revenue Trend (Weekly)
SELECT 
    `week_no`,
    booking_platform,
    SUM(revenue_realized) AS weekly_revenue
FROM Fact_Booking
GROUP BY `week_no`, booking_platform
ORDER BY `week_no`, weekly_revenue DESC;

----- 6.Utilize Capacity
SELECT
concat(round(SUM(capacity) / 1000, 2), 'K') AS Total_Capacity 
FROM fact_aggregated_bookings;

----- 7.Weekday & Weekend Revenue and Booking
SELECT 
    day_type,
   concat(round(COUNT(booking_id) /100 , 2 ), 'K') AS Total_Bookings,
  concat(round( SUM(revenue_realized) / 1000000, 2), 'M') AS Total_Revenue
FROM Fact_Booking
GROUP BY day_type;

----- 8.Revenue by City & Hotel
SELECT city, property_name, concat(round(SUM(revenue_realized) / 1000000, 2), 'M') AS Total_Revenue
FROM Fact_Booking
GROUP BY city, property_name
ORDER BY Total_Revenue DESC;

----- 9.Class-Wise Revenue
SELECT room_class, 
concat(round(SUM(revenue_realized) / 1000000, 2), 'M') AS Total_Revenue
FROM Fact_Booking
GROUP BY room_class
ORDER BY Total_Revenue DESC;

----- 10.Booking Status Breakdown (Checked out, Cancel, No show)
SELECT 
    booking_status, 
  concat(round(COUNT(*) / 1000, 2), 'K') AS Total_Count
FROM Fact_Booking
GROUP BY booking_status;

----- 11.Weekly Trend Analysis (Revenue, Bookings, Occupancy)
SELECT 
    fb.week_no,
    CONCAT(ROUND(SUM(fb.revenue_realized) / 1000000 , 2), 'M') AS Weekly_Revenue,
  CONCAT(ROUND(COUNT(fb.booking_id) / 1000, 2), 'k') AS Weekly_Bookings,
    -- Occupancy calculation joined by week
   CONCAT(ROUND(SUM(fab.total_successful_bookings) / SUM(fab.total_capacity) * 100, 2), '%') AS Weekly_Occupancy_Rate
FROM Fact_Booking fb
JOIN (
    -- Pre-aggregating occupancy by check-in date to align with the main fact table
    SELECT 
        check_in_date, 
        SUM(successful_bookings) AS total_successful_bookings, 
        SUM(capacity) AS total_capacity
    FROM fact_aggregated_bookings
    GROUP BY check_in_date
) fab ON fb.check_in_date = fab.check_in_date
GROUP BY fb.week_no
ORDER BY fb.week_no;
