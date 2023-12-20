use supply_db ;

/*  Question: Month-wise NIKE sales

	Description:
		Find the combined month-wise sales and quantities sold for all the Nike products. 
        The months should be formatted as ‘YYYY-MM’ (for example, ‘2019-01’ for January 2019). 
        Sort the output based on the month column (from the oldest to newest). The output should have following columns :
			-Month
			-Quantities_sold
			-Sales
		HINT:
			Use orders, ordered_items, and product_info tables from the Supply chain dataset.
*/		
SELECT 
	DATE_FORMAT(ord.Order_Date, '%Y-%m') AS Month,
    SUM(ord_itm.Quantity) AS Quantities_Sold,
    SUM(ord_itm.Sales) AS Sales
FROM
	orders AS ord
	LEFT JOIN
    ordered_items AS ord_itm
    ON ord.Order_Id = ord_itm.Order_Id
    LEFT JOIN 
    product_info AS prod_info
    ON ord_itm.Item_Id = prod_info.Product_Id
WHERE
	LOWER(prod_info.Product_Name) LIKE '%nike%'
GROUP BY Month
ORDER BY Month;

-- **********************************************************************************************************************************
/*

Question : Costliest products

Description: What are the top five costliest products in the catalogue? Provide the following information/details:
-Product_Id
-Product_Name
-Category_Name
-Department_Name
-Product_Price

Sort the result in the descending order of the Product_Price.

HINT:
Use product_info, category, and department tables from the Supply chain dataset.
*/
SELECT 
	prod_info.Product_Id,
    prod_info.Product_Name,
    cat.Name AS Category_Name,
    dept.Name AS Department_Name,
	prod_info.Product_Price
FROM 
	product_info AS prod_info
    LEFT JOIN
    category AS cat
    ON prod_info.Category_Id = cat.Id
    LEFT JOIN
    department AS dept
    ON prod_info.Department_Id = dept.Id
ORDER BY 5 DESC
LIMIT 5;
    
-- **********************************************************************************************************************************

/*

Question : Cash customers

Description: Identify the top 10 most ordered items based on sales from all the ‘CASH’ type orders. 
Provide the Product Name, Sales, and Distinct Order count for these items. Sort the table in descending
 order of Order counts and for the cases where the order count is the same, sort based on sales (highest to
 lowest) within that group.
 
HINT: Use orders, ordered_items, and product_info tables from the Supply chain dataset.

*/
SELECT 
	prod_info.Product_Name,
    SUM(ord_itm.Sales) AS Sales,
    COUNT(DISTINCT ord.Order_Id) AS Order_Count
FROM
	orders AS ord
    LEFT JOIN
    ordered_items AS ord_itm 
    ON ord.Order_Id = ord_itm.Order_Id
    LEFT JOIN
    product_info AS prod_info
    ON ord_itm.Item_Id = prod_info.Product_Id
WHERE
	ord.Type = 'CASH'
GROUP BY prod_info.Product_Name
ORDER BY Order_Count DESC, Sales DESC
LIMIT 10;
-- **********************************************************************************************************************************
/*
Question : Customers from texas

Obtain all the details from the Orders table (all columns) for customer orders in the state of Texas (TX),
whose street address contains the word ‘Plaza’ but not the word ‘Mountain’. The output should be sorted by the Order_Id.

HINT: Use orders and customer_info tables from the Supply chain dataset.

*/
SELECT ord.* 
FROM 
	orders AS ord
    LEFT JOIN
	customer_info AS cust_info
    ON ord.Customer_Id = cust_info.Id
WHERE 
	cust_info.State = 'TX' 
    AND
    LOWER(cust_info.Street) LIKE '%plaza%'
    AND 
    LOWER(cust_info.Street) NOT LIKE '%mountain%'
ORDER BY ord.Order_Id;
-- **********************************************************************************************************************************
/*
 
Question: Home office

For all the orders of the customers belonging to “Home Office” Segment and have ordered items belonging to
“Apparel” or “Outdoors” departments. Compute the total count of such orders. The final output should contain the 
following columns:
-Order_Count

*/ 
SELECT 
	COUNT(DISTINCT ord.Order_Id) AS Order_Count
FROM
	orders AS ord
    LEFT JOIN 
    customer_info AS cust_info
    ON ord.Customer_Id = cust_info.Id
    LEFT JOIN
    ordered_items AS ord_itm
    ON ord.Order_Id = ord_itm.Order_Id
    LEFT JOIN
    product_info AS prod_info
    ON ord_itm.Item_Id = prod_info.Product_Id
    LEFT JOIN
    department AS dept
    ON prod_info.Department_Id = dept.Id
WHERE 
	cust_info.Segment = 'Home Office'
    AND
    (dept.Name = 'Apparel'  OR dept.Name = 'Outdoors');
    
-- **********************************************************************************************************************************
/*

Question : Within state ranking
 
For all the orders of the customers belonging to “Home Office” Segment and have ordered items belonging
to “Apparel” or “Outdoors” departments. Compute the count of orders for all combinations of Order_State and Order_City. 
Rank each Order_City within each Order State based on the descending order of their order count (use dense_rank). 
The states should be ordered alphabetically, and Order_Cities within each state should be ordered based on their rank. 
If there is a clash in the city ranking, in such cases, it must be ordered alphabetically based on the city name. 
The final output should contain the following columns:
-Order_State
-Order_City
-Order_Count
-City_rank

HINT: Use orders, ordered_items, product_info, customer_info, and department tables from the Supply chain dataset.

*/
WITH order_summary_home_office AS
(
SELECT 	
    ord.Order_State,
	ord.Order_City,
	COUNT(DISTINCT ord.Order_Id) AS Order_Count
FROM
	orders AS ord
    LEFT JOIN 
    customer_info AS cust_info
    ON ord.Customer_Id = cust_info.Id
    LEFT JOIN
    ordered_items AS ord_itm
    ON ord.Order_Id = ord_itm.Order_Id
    LEFT JOIN
    product_info AS prod_info
    ON ord_itm.Item_Id = prod_info.Product_Id
    LEFT JOIN
    department AS dept
    ON prod_info.Department_Id = dept.Id
WHERE 
	cust_info.Segment = 'Home Office'
    AND
    (dept.Name = 'Apparel'  OR dept.Name = 'Outdoors')
GROUP BY ord.Order_State, Ord.Order_City
ORDER BY ord.Order_State, Ord.Order_City
)
SELECT
	*,
    DENSE_RANK() 
		OVER(PARTITION BY ord_summary.Order_State
			ORDER BY ord_summary.Order_Count DESC) AS City_rank
From 
	order_summary_home_office AS ord_summary;		
    
-- **********************************************************************************************************************************
/*
Question : Underestimated orders

Rank (using row_number so that irrespective of the duplicates, so you obtain a unique ranking) the 
shipping mode for each year, based on the number of orders when the shipping days were underestimated 
(i.e., Scheduled_Shipping_Days < Real_Shipping_Days). The shipping mode with the highest orders that meet 
the required criteria should appear first. Consider only ‘COMPLETE’ and ‘CLOSED’ orders and those belonging to 
the customer segment: ‘Consumer’. The final output should contain the following columns:
-Shipping_Mode,
-Shipping_Underestimated_Order_Count,
-Shipping_Mode_Rank

HINT: Use orders and customer_info tables from the Supply chain dataset.
*/
WITH shipping_summary_underestimated AS
(
SELECT 
	ord.Shipping_Mode,
	COUNT(DISTINCT ord.Order_Id) AS Shipping_Underestimated_Order_Count
FROM
	orders AS ord
    LEFT JOIN
    customer_info AS cust_info
    ON ord.Customer_Id = cust_info.Id
WHERE
	(ord.Order_Status = 'COMPLETE' OR ord.Order_Status = 'CLOSED')
    AND
	ord.Scheduled_Shipping_Days < ord.Real_Shipping_Days
    AND
    cust_info.Segment = 'Consumer'
GROUP BY ord.Shipping_Mode
)
SELECT 
	*,
    ROW_NUMBER()
    OVER(
		ORDER BY ship_summary.Shipping_Underestimated_Order_Count DESC
        ) AS Shipping_Mode_Rank
FROM
	shipping_summary_underestimated AS ship_summary;
-- **********************************************************************************************************************************
