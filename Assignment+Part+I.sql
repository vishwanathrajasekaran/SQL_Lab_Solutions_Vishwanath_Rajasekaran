use supply_db ;

/*
Question : Golf related products

List all products in categories related to golf. Display the Product_Id, Product_Name in the output. Sort the output in the order of product id.
Hint: You can identify a Golf category by the name of the category that contains golf.

*/

SELECT 
    p.product_Name AS Product_Name, p.product_Id AS Product_Id
FROM
    product_info p
        LEFT JOIN
    category c ON p.Category_Id = c.Id
WHERE
    LOWER(c.Name) LIKE '%golf%'
ORDER BY Product_Id;

-- **********************************************************************************************************************************

/*
Question : Most sold golf products

Find the top 10 most sold products (based on sales) in categories related to golf. Display the Product_Name and Sales column in the output. Sort the output in the descending order of sales.
Hint: You can identify a Golf category by the name of the category that contains golf.

HINT:
Use orders, ordered_items, product_info, and category tables from the Supply chain dataset.


*/

With golf_products as(
 SELECT 
    p.product_Name AS Product_Name, p.product_Id AS Product_Id
FROM
    product_info p
        LEFT JOIN
    category c ON p.Category_Id = c.Id
WHERE
    LOWER(c.Name) LIKE '%golf%'
ORDER BY Product_Id
 )
 SELECT 
    Product_Name, SUM(Sales) AS Sales
FROM
    golf_products g
        LEFT JOIN
    ordered_items o ON g.Product_Id = o.Item_Id
GROUP BY Product_Name
ORDER BY Sales DESC
LIMIT 10;

-- **********************************************************************************************************************************

/*
Question: Segment wise orders

Find the number of orders by each customer segment for orders. Sort the result from the highest to the lowest 
number of orders.The output table should have the following information:
-Customer_segment
-Orders
*/

SELECT 
    c.Segment AS customer_segment, COUNT(o.Order_Id) AS Orders
FROM
    customer_info c
        INNER JOIN
    orders o ON c.Id = o.Customer_Id
GROUP BY customer_segment
ORDER BY Orders DESC;

-- **********************************************************************************************************************************
/*
Question : Percentage of order split

Description: Find the percentage of split of orders by each customer segment for orders that took six days 
to ship (based on Real_Shipping_Days). Sort the result from the highest to the lowest percentage of split orders,
rounding off to one decimal place. The output table should have the following information:
-Customer_segment
-Percentage_order_split

HINT:
Use the orders and customer_info tables from the Supply chain dataset.


*/

WITH Seg_Orders AS
(
SELECT
cust.Segment AS customer_segment,
COUNT(ord.Order_Id) AS Orders
FROM
orders AS ord
LEFT JOIN
customer_info AS cust
ON ord.Customer_Id = cust.Id
WHERE Real_Shipping_Days=6
GROUP BY customer_segment
)
SELECT
s1.customer_segment,
ROUND(s1.Orders/SUM(s2.Orders)*100,1) AS percentage_order_split
FROM
Seg_Orders AS s1
JOIN
Seg_Orders AS s2
GROUP BY s1.customer_segment
ORDER BY percentage_order_split DESC;

-- **********************************************************************************************************************************
