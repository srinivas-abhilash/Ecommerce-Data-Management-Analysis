# Validating if the data is properly imported into the table
SELECT * FROM ecomm_denom_table;

# Insert statements to normalize data and load into the different tables

INSERT INTO seller (SELLER_ID, SELLER_STATE) 
SELECT 
	DISTINCT SELLER_ID, 
    SELLER_STATE 
FROM 
	ecomm_denom_table;

INSERT INTO product 
SELECT 
	DISTINCT PRODUCT_ID,
    PRODUCT_CATEGORY_NAME,
    PRODUCT_WEIGHT_G,
    VOLUMETRIC_WEIGHT
FROM ecomm_denom_table;

INSERT INTO customer 
SELECT 
	DISTINCT CUSTOMER_ID,
    CUSTOMER_CITY,
    CUSTOMER_STATE
FROM ecomm_denom_table;

INSERT INTO payment 
SELECT 
	DISTINCT ORDER_ID, 
	PAYMENT_TYPE, 
	PAYMENT_INSTALLMENTS, 
	PAYMENT_SEQUENTIAL, 
	TOTAL_PAYMENT_VALUE 
FROM 
	ecomm_denom_table;

INSERT INTO geolocation 
SELECT 
	DISTINCT CUSTOMER_ZIP_CODE_PREFIX,
    GEOLOCATION_LAT, 
    GEOLOCATION_LNG
FROM 
	ecomm_denom_table;

INSERT INTO orders 
SELECT 
	DISTINCT ORDER_ID, 
    CUSTOMER_ID, 
    GEOLOCATION_LAT, 
    GEOLOCATION_LNG, 
    ORDER_STATUS, 
    ORDER_PURCHASE_TIMESTAMP,
	ORDER_APPROVED_AT, 
    ORDER_DELIVERED_CARRIER_DATE, 
    ORDER_DELIVERED_CUSTOMER_DATE, 
    ORDER_ESTIMATED_DELIVERY_DATE,
	SELLER_TO_CARRIER_DELIVERYTIME, 
    CARRIER_TO_CUSTOMER_DELIVERY_TIME, 
    SELLER_DISPATCH_TIME, 
    CUSTOMER_DELIVERY_TIME 
FROM 
	ecomm_denom_table;

INSERT INTO order_item 
SELECT 
	DISTINCT ORDER_ID,
    ORDER_ITEM_ID,
    PRODUCT_ID, 
    SELLER_ID, 
    PRICE, 
    FREIGHT_VALUE 
FROM 
	ecomm_denom_table;

# Running SELECT * to validate if the data is properly imported into the tables

SELECT * FROM seller;

SELECT * FROM product;

SELECT * FROM customer;

SELECT * FROM payment;

SELECT * FROM order_item;

SELECT * FROM geolocation;

# Describing the tables
DESCRIBE customer;

DESCRIBE seller;

DESCRIBE product;

DESCRIBE order_item;

DESCRIBE orders;

DESCRIBE geolocation;

DESCRIBE payment;