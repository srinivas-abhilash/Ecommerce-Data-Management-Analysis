# Using the ecommerce database
use ecommerce;

# Performing SELECT * on all the tables to check if the data is available
SELECT * FROM customer;
SELECT * FROM geolocation;
SELECT * FROM order_item;
SELECT * FROM orders;
SELECT * FROM payment;
SELECT * FROM product;
SELECT * FROM seller;

# Hypothesis 1
# The e-commerce company started receiving complaints from the city ‘santa rita’. 
# The management wanted to have a look at the details of the orders from ‘santa rita’ and 
# understand if there are any issues after looking at the data.

SELECT 
	* 
FROM 
	ORDERS a 
    JOIN 
    CUSTOMER b 
    ON a.CUSTOMER_ID = B.CUSTOMER_ID
WHERE 
	CUSTOMER_CITY = 'santa rita';


# Hypothesis 2
# What is the average order value and average delivery cost?

# The ORDER_ITEM table contains the price and delivery cost for each item in the order, but since the business needs
# the average order value, we need to group the data based on the ORDER_ID first, and later calculate the average order value
# and average delivery cost

SELECT 
	AVG(A.ORDER_PRICE) AS AVG_ORDER_VALUE, 
	AVG(A.ORDER_DELIVERY) AS AVG_DELIVERY_COST 
FROM 
	(SELECT ORDER_ID, 
			SUM(PRICE) AS ORDER_PRICE, 
			SUM(FREIGHT_VALUE) AS ORDER_DELIVERY 
	 FROM ORDER_ITEM 
     GROUP BY ORDER_ID) A;

# Hypothesis 3
# How are the orders distributed over the days of the month? and days of the week?

# Order distribution over the day of the month
SELECT 
	B.ORDER_DAY_MONTH,
    B.ORDERS_PLACED, 
    SUM(B.ORDERS_PLACED) OVER () TOTAL_ORDERS,
	(B.ORDERS_PLACED/(SUM(B.ORDERS_PLACED) OVER ()))*100 AS ORDER_DISTRIBUTION 
FROM 
	(SELECT A.ORDER_DAY_MONTH, 
			SUM(A.ORDER_PLACED) AS ORDERS_PLACED 
	FROM 
	(SELECT *, 
    DAYOFMONTH(ORDER_PURCHASE_TIMESTAMP) AS ORDER_DAY_MONTH, 
    CASE 
    WHEN ORDER_ID IS NOT NULL THEN 1 
    ELSE 0 END AS ORDER_PLACED 
    FROM ORDERS) A 
    GROUP BY ORDER_DAY_MONTH 
	ORDER BY ORDER_DAY_MONTH) B;

# Order distribution over the day of the week
SELECT 
	B.ORDER_DAY_WEEK,
    B.ORDERS_PLACED, 
    SUM(B.ORDERS_PLACED) OVER () TOTAL_ORDERS,
	(B.ORDERS_PLACED/(SUM(B.ORDERS_PLACED) OVER ()))*100 AS ORDER_DISTRIBUTION 
    FROM 
	(SELECT A.ORDER_DAY_WEEK, 
			SUM(A.ORDER_PLACED) AS ORDERS_PLACED 
	 FROM 
		(SELECT 
				*,
				DAYNAME(ORDER_PURCHASE_TIMESTAMP) AS ORDER_DAY_WEEK, 
				CASE WHEN ORDER_ID IS NOT NULL THEN 1 
                ELSE 0 END AS ORDER_PLACED 
		FROM ORDERS) A 
	 GROUP BY ORDER_DAY_WEEK 
     ORDER BY ORDER_DAY_WEEK) B;

# Hypothesis 4
# What are the highest and lowest ordered product categories?

(SELECT 
	PRODUCT_CATEGORY_NAME, 
    COUNT(ORDER_ITEM_ID) AS ORDER_CNT 
FROM 
	ORDER_ITEM A 
	JOIN 
    PRODUCT B 
    ON A.PRODUCT_ID = B.PRODUCT_ID 
GROUP BY PRODUCT_CATEGORY_NAME 
ORDER BY ORDER_CNT DESC);

# Hypothesis 5
# Do customers prefer more installments for higher-value orders?

# Grouped the data into deciles(or percentile groups)
SELECT 
	A.TEN_PER_GROUPS, 
    MIN(TOTAL_PAYMENT_VALUE) AS GRP_MIN_PAYMENT_VALUE, 
	MAX(TOTAL_PAYMENT_VALUE) AS GRP_MAX_PAYMENT_VALUE,
	AVG(A.PAYMENT_INSTALLMENTS) AS AVG_PAYMENT_INSTALLMENTS 
FROM 
	(SELECT PAYMENT_INSTALLMENTS,
			TOTAL_PAYMENT_VALUE, 
			NTILE(10) OVER (ORDER BY TOTAL_PAYMENT_VALUE DESC) TEN_PER_GROUPS 
	 FROM 
     ORDERS A 
     JOIN 
     PAYMENT B 
     ON A.ORDER_ID = B.ORDER_ID) A 
GROUP BY A.TEN_PER_GROUPS 
ORDER BY A.TEN_PER_GROUPS;


# Hypothesis 6
# The management is interested in knowing the states with the highest and the lowest orders 
# as it would help allocate the workforce accordingly. 
# The distribution of orders across different states in the country. 
# A detailed heatmap would help the organization allocate the workforce more efficiently.

SELECT 
	CUSTOMER_STATE, 
	COUNT(ORDER_ID) AS ORDER_CNT 
FROM 
	ORDERS A 
    JOIN 
    CUSTOMER B 
    ON A.CUSTOMER_ID = B.CUSTOMER_ID 
GROUP BY CUSTOMER_STATE
ORDER BY ORDER_CNT DESC; 

# Data required for plotting a heatmap
SELECT 
	ORDER_ID, 
	GEOLOCATION_LAT, 
    GEOLOCATION_LNG 
FROM 
	ORDERS A 
    JOIN 
    CUSTOMER B 
    ON A.CUSTOMER_ID = B.CUSTOMER_ID;

# Hypothesis 7
# What is the percentage of orders that are dispatched late by the seller (seller_dispatch_time = Delay) but delivered before the promised time to the customer (customer_delivery_time = Fast)?
SELECT 
	(SUM(A.SELLER_DELAY_PRODUCTS)/COUNT(A.SELLER_DELAY_PRODUCTS))*100 AS PER_SELLER_DELAY 
FROM 
	(SELECT ORDER_ID, 
			CASE WHEN SELLER_DISPATCH_TIME = 'Delay' AND CUSTOMER_DELIVERY_TIME = 'Fast' THEN 1 
            ELSE 0 END AS SELLER_DELAY_PRODUCTS 
	 FROM ORDERS) A;

# Hypothesis 8
# As high-value and low-volume products generate a lot of revenue for an e-commerce company, 
# What is the distribution of (high-value, low-volume), (low-value, high-volume), (low-value, low-volume), (high-value, high-volume) 
# products are delivered before the promised time to the customer?

SELECT 
	E.VAL_VOL_BANDS, 
	CNT_PRODUCTS, 
    (CNT_PRODUCTS/(SUM(CNT_PRODUCTS) OVER ()))*100 AS PER_DISTRN 
FROM 
	(SELECT 
		D.VAL_VOL_BANDS,
		COUNT(D.PRODUCT_ID) AS CNT_PRODUCTS
	 FROM
		(SELECT C.PRODUCT_ID, 
				CASE WHEN PRICE_BANDS IN (1,2,3,4,5,6) AND VOLUME_BANDS IN (7,8,9,10) THEN 'High_Val_Low_Vol'
					 WHEN PRICE_BANDS IN (7,8,9,10) AND VOLUME_BANDS IN (1,2,3,4,5,6) THEN 'Low_Val_High_Vol'
					 WHEN PRICE_BANDS IN (7,8,9,10) AND VOLUME_BANDS IN (7,8,9,10) THEN 'Low_Val_Low_Vol'
					 WHEN PRICE_BANDS IN (1,2,3,4,5,6) AND VOLUME_BANDS IN (1,2,3,4,5,6) THEN 'High_Val_High_Vol' END AS VAL_VOL_BANDS 
		 FROM
			(SELECT A.PRODUCT_ID, 
					A.PRICE, 
					NTILE(10) OVER (ORDER BY A.PRICE DESC) PRICE_BANDS, 
					B.VOLUMETRIC_WEIGHT, NTILE(10) OVER (ORDER BY B.VOLUMETRIC_WEIGHT DESC) VOLUME_BANDS
			 FROM 
             ORDER_ITEM A 
             JOIN 
             PRODUCT B 
             ON A.PRODUCT_ID = B.PRODUCT_ID) C) D 
	GROUP BY D.VAL_VOL_BANDS) E;

# Hypothesis 9
# How many orders in total are using more than 5 vouchers to pay the order amount?

# A - Length of payment type calculates the number of characters in the string
# B - Length(Replace(PAYMENT_TYPE, 'voucher', '')) replaces the 'voucher' strings with blanks
# (A - B) gives the number of characters for 'voucher' strings, and when we divide it with number of characters in 'voucher'
#we get the voucher's count

SELECT 
	COUNT(A.ORDER_ID) AS ORDER_COUNT 
FROM 
	((SELECT A.ORDER_ID, 
			 PAYMENT_TYPE, 
			 (LENGTH(PAYMENT_TYPE) - LENGTH(REPLACE(PAYMENT_TYPE, 'voucher', ''))) / CHAR_LENGTH('voucher') AS VOUCHER_CNT 
	  FROM 
      ORDERS A 
      JOIN 
      PAYMENT B 
      ON A.ORDER_ID = B.ORDER_ID)) A 
WHERE A.VOUCHER_CNT >= 5;

# Hypothesis 10
# As it would decrease the delivery costs, the management wants to run marketing campaigns 
# and generate more orders from the states where we have sellers but very few customers.

SELECT 
	P.SELLER_STATE AS STATE, 
    P.CNT_ORDER_SELLER_STATE,
    Q.CNT_ORDER_CUSTOMER_STATE,
	P.CNT_ORDER_SELLER_STATE/Q.CNT_ORDER_CUSTOMER_STATE AS SELLER_CUSTOMER_RATIO
FROM 
	(SELECT 
		DISTINCT E.SELLER_STATE, 
        COUNT(E.SELLER_STATE) OVER (PARTITION BY E.SELLER_STATE) CNT_ORDER_SELLER_STATE
	 FROM
		(SELECT 
			SELLER_STATE,
            CUSTOMER_STATE 
		 FROM 
			ORDER_ITEM A 
            JOIN
			ORDERS B 
            ON A.ORDER_ID = B.ORDER_ID
			JOIN 
            SELLER C 
            ON A.SELLER_ID = C.SELLER_ID
			JOIN 
            CUSTOMER D 
            ON B.CUSTOMER_ID = D.CUSTOMER_ID) E) P
	LEFT JOIN 
	(SELECT 
		DISTINCT E.CUSTOMER_STATE, 
        COUNT(E.CUSTOMER_STATE) OVER (PARTITION BY E.CUSTOMER_STATE) CNT_ORDER_CUSTOMER_STATE
	 FROM
		(SELECT SELLER_STATE,
				CUSTOMER_STATE 
		 FROM 
         ORDER_ITEM A 
         JOIN
		 ORDERS B 
         ON A.ORDER_ID = B.ORDER_ID
		 JOIN 
         SELLER C 
         ON A.SELLER_ID = C.SELLER_ID
		 JOIN CUSTOMER D 
         ON B.CUSTOMER_ID = D.CUSTOMER_ID) E) Q
	ON P.SELLER_STATE = Q.CUSTOMER_STATE
;


# Hypothesis 11
# The management would like to run a credit card campaign if there are a significant number of customers 
# who are not using credit cards to pay the orders, what is the percentage of customers who are using a credit card 
# for a full payment/ partial payment?

SELECT 
	SUM(D.CC_PART_FULL)/COUNT(D.CC_PART_FULL) AS PER_CC_PAYMENT 
FROM 
	(SELECT 
		C.ORDER_ID, 
		CASE WHEN C.CC_CNT >= 1 THEN 1 ELSE 0 END AS CC_PART_FULL 
	 FROM 
		(SELECT 
			A.ORDER_ID, 
            PAYMENT_TYPE,
			(LENGTH(PAYMENT_TYPE) - LENGTH(REPLACE(PAYMENT_TYPE, 'credit_card', ''))) / CHAR_LENGTH('credit_card') AS CC_CNT 
		 FROM 
         ORDERS A 
         JOIN 
         PAYMENT B 
         ON A.ORDER_ID = B.ORDER_ID) C) D;
