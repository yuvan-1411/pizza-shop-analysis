-- capestone project 

-- Q1 active branchs

select * from branch_data
where Branch_status = 'active';

-- Q2 basic product details

select
	product_id,
    product_name,
    product_type,
    product_size,
    price
from products;

-- Q3 recent customer singnup 

select
	Customer_ID,
	Customer_name,
	SignUp_timestamp
from customers_info
where date(SignUp_timestamp) between '2020-01-01' and '2022-12-31';

-- Q4 order overview

select 
	Orders_ID,
    Customer_ID,
    date(Order_timestamp),
    Payment_status
 from orders_info;
 
 -- Q5 unresolved problems
 
select * from customer_support
where ticket_status != 'resolved' and ticket_status != 'closed'; 

select * from customer_support
where ticket_status not in ('resolved','closed');

-- Q6 customers orders details

select 
Customer_name,
Email_address,
Orders_ID,
consumption_type
from customers_info as ci
inner join orders_info as oi
on ci.customer_id = oi.customer_id;

-- Q7 finding total revnue made

select round(sum(Amount_in_USD),0)
from finance_transactions;

select round(sum(Amount_in_USD)/10)*10
from finance_transactions;

-- Q8 avg support response time 

select 
		contact_channel,
        round(avg(time_taken_in_sec)/60,2) as avg_in_mins
from customer_support
group by contact_channel;

-- support_response_time.csv (add branch)
SELECT
    bd.Branch_name,
    cs.contact_channel,
    ROUND(AVG(cs.time_taken_in_sec) / 60, 2) AS avg_in_mins
FROM customer_support cs
JOIN orders_info o  ON cs.order_id  = o.orders_id
JOIN branch_data bd ON o.branch_id  = bd.branch_id
GROUP BY bd.Branch_name, cs.contact_channel;

-- Q9 active employee count by department

select 
		Department,
        count(Emp_ID) as active_employee
from employee_data
WHERE Employee_Employment_status = 'ACTIVE'
group by Department;

SELECT
    bd.Branch_name,
    ed.Department,
    COUNT(CASE WHEN Employee_Employment_status = 'ACTIVE' THEN 1 END) AS active_employee
FROM employee_data ed
JOIN branch_data bd ON ed.branch_id = bd.branch_id
GROUP BY bd.Branch_name, ed.Department;

select 
		Department,
        count(case when Employee_Employment_status = 'ACTIVE' then '1' end) as active_employee,
        count(case when Employee_Employment_status = 'INACTIVE' then '1' end) as inactive_employee
from employee_data
group by department;

-- Q10 expired inventory items 

select
Item_id,
Item_Name,
date(expiry_date) 
from inventory
where expiry_date < '2025-01-10';

select
Item_id,
Item_Name,
(expiry_date) 
from inventory
where expiry_date < now();

-- Q11 marketing campaigns by channel

select
channel,
count(campaign_id) no_of_campaigns
from marketing_campaigns
group by channel;


-- Q12 asset deployment per branch

select
Branch_name,
count(asset_id)
from assets a
join branch_data bd
on a.deployed_branch_id = bd.branch_id
where asset_status != 'inactive'
group by branch_name;

-- Q13 top 5 products by revenue 

select 
product_name,
round(sum(amount_in_usd)) revenue_by_products
from products p 
join finance_transactions ft
on p.product_id = ft.product_id
group by product_name
order by revenue_by_products desc limit 5;

-- Q14 asset depriciation calculation 

SELECT 
  asset_id,
  asset_name,
  asset_cost,
  depreciation_percent,
  deployment_date,
  TIMESTAMPDIFF(YEAR, deployment_date, CURDATE()) AS years_used,
  ROUND(
    asset_cost * (1 - ((depreciation_percent / 100) * TIMESTAMPDIFF(YEAR, deployment_date, CURDATE()))), 
    2
  ) AS current_value
FROM assets;

-- Q15 high cost empolyee by department 

select * from(

select 
Employee_name,
Department,
Current_Annual_Cost,
rank()
over (partition by department order by Current_Annual_Cost desc) high_cost_employee
from employee_data) sub
where high_cost_employee = 1;

-- Q16 ROI for active branches

with revenue_info as (

select 
Branch_ID,
sum(Amount_in_USD) as revenue
from orders_info o
join finance_transactions f
on o.orders_id = f.orders_id
group by Branch_ID
)
select
b.Branch_ID,
b.Branch_name,
b.Branch_Investment_cost,
revenue,
round(revenue/Branch_Investment_cost,2) ROI
from branch_data b
left join revenue_info r
on b.branch_id = r.branch_id
where Branch_status = 'active';

-- Q17 orders ferquency per customer

select 
Customer_ID,
count(Orders_ID),
dense_rank()
over (order by count(Orders_ID)desc) rank_of_customers
from orders_info
group by Customer_ID
order by customer_id asc;

-- Q18 top 3 products per product type

select * from
(select 
product_id,
product_name,
product_type,
price,
rank ()
over(partition by product_type order by price desc) top 
from products) ranked_data
where top <= 3;

-- Q19 Inventory expiry tracker

select
Item_Name,
no_of_items_in_stock,
expiry_date,
supplier_name,
datediff(expiry_date, '2024-01-30') no_of_days_left
from inventory
where expiry_date between '2024-01-30' and '2024-02-10';

-- Q20 campaign spend efficiency

select
Campaign_ID,
Campaign_name,
Channel,
Impressions,
No_of_clicks,
campaign_spend,
round(No_of_clicks/Impressions *100,2) CTR,
round(campaign_spend/No_of_clicks,3) CPC
from marketing_campaigns
where No_of_clicks >0;

-- Q21 fixed delivery performance by branch

SELECT
    bd.Branch_name,
    COUNT(d.delivery_id)                                                      AS total_deliveries,
    SUM(CASE WHEN d.delivery_status = 'delivered'  THEN 1 ELSE 0 END)        AS delivered,
    SUM(CASE WHEN d.delivery_status = 'pending'    THEN 1 ELSE 0 END)        AS pending,
    SUM(CASE WHEN d.delivery_status = 'in transit' THEN 1 ELSE 0 END)        AS in_transit,
    SUM(CASE WHEN d.delivery_status = 'cancelled'   THEN 1 ELSE 0 END)        AS canceled,
    ROUND(
        SUM(CASE WHEN d.delivery_status = 'delivered' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(d.delivery_id), 2
    )                                                                         AS delivery_success_pct,
    ROUND(
        SUM(CASE WHEN d.delivery_status = 'cancelled' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(d.delivery_id), 2
    )                                                                         AS cancellation_rate_pct
FROM deliveries d
LEFT JOIN orders_info o  ON d.order_id  = o.orders_id
LEFT JOIN branch_data bd ON o.branch_id = bd.branch_id
GROUP BY bd.Branch_name
ORDER BY delivery_success_pct DESC;

-- Q22 average delivery time per product type

SELECT
    p.product_type,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, d.Delivery_start_timestamp, d.Delivery_end_timestamp)), 1) AS avg_delivery_mins,
    COUNT(d.delivery_id) AS total_orders
FROM deliveries d
JOIN orders_info o ON d.order_id = o.orders_id
JOIN products p ON o.product_id = p.product_id
WHERE d.Delivery_end_timestamp IS NOT NULL
GROUP BY p.product_type
ORDER BY avg_delivery_mins;

-- Q23 bundle revenue vs individual product revenue

SELECT 
    CASE 
        -- Check if the product ID exists anywhere inside the Bundle's Product_IDs string
        WHEN pb.Bundle_ID IS NOT NULL THEN pb.Bundle_name 
        ELSE 'Individual Product' 
    END AS sale_type,
    COUNT(DISTINCT ft.Orders_ID) AS total_orders,
    ROUND(SUM(ft.Amount_in_USD), 2) AS total_revenue
FROM finance_transactions ft
LEFT JOIN product_bundles pb ON (
    -- This matches the ID even if it's in the middle of a comma-separated list
    pb.Product_IDs LIKE CONCAT('%', ft.Product_ID, '%')
)
LEFT JOIN products p ON ft.Product_ID = p.product_id
GROUP BY sale_type
ORDER BY total_revenue DESC;

-- total revenue for kpi card
SELECT ROUND(SUM(Amount_in_USD), 0) AS total_revenue
FROM finance_transactions;

-- active branchs for kpi card
SELECT count(*) AS active_branches
FROM branch_data
WHERE Branch_status = 'active';

-- delivery_performance.csv (long format for Power BI)
SELECT
    bd.Branch_name,
    d.delivery_status,
    COUNT(d.delivery_id) AS total_deliveries
FROM deliveries d
LEFT JOIN orders_info o  ON d.order_id  = o.orders_id
LEFT JOIN branch_data bd ON o.branch_id = bd.branch_id
GROUP BY bd.Branch_name, d.delivery_status
ORDER BY bd.Branch_name;

-- employee_by_department.csv (add branch)
SELECT
    bd.Branch_name,
    ed.Department,
    COUNT(CASE WHEN Employee_Employment_status = 'ACTIVE' THEN 1 END) AS active_employee
FROM employee_data ed
JOIN branch_data bd ON ed.branch_id = bd.branch_id
GROUP BY bd.Branch_name, ed.Department;

-- support_response_time.csv (add branch)
SELECT
    bd.Branch_name,
    cs.contact_channel,
    ROUND(AVG(cs.time_taken_in_sec) / 60, 2) AS avg_in_mins
FROM customer_support cs
JOIN orders_info o  ON cs.order_id  = o.orders_id
JOIN branch_data bd ON o.branch_id  = bd.branch_id
GROUP BY bd.Branch_name, cs.contact_channel;

-- campaign_spend_efficiency.csv
SELECT
    channel,
    ROUND(SUM(campaign_spend), 0)        AS total_spend,
    ROUND(AVG(No_of_clicks/Impressions * 100), 2) AS avg_CTR,
    ROUND(SUM(campaign_spend)/SUM(No_of_clicks), 3) AS CPC
FROM marketing_campaigns
WHERE No_of_clicks > 0
GROUP BY channel;