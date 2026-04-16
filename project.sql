select * from order_items;
select * from products;
select * from payments;
select * from customers;
select * from orders;

select count(distinct customer_id), count(distinct customer_unique_id) from customers;

/*🟢 1. Monthly Revenue Trend */
select format(o.order_purchase_timestamp,'yyyy') as order_year
,format(o.order_purchase_timestamp,'MM') as order_month
,sum(p.payment_value) as total_amount
from orders o 
inner join payments p 
on o.order_id = p.order_id
group by format(o.order_purchase_timestamp,'yyyy'),format(o.order_purchase_timestamp,'MM')
order by format(o.order_purchase_timestamp,'yyyy') asc,format(o.order_purchase_timestamp,'MM') asc;

/* 🟢 2. Top 10 Products by Revenue */

select top 10 p.product_category_name, sum(o.price) as total_amount
from order_items o
inner join products p
on o.product_id = p.product_id
group by p.product_category_name
order by total_amount desc;

/* 🟢 3. Top Customers */

select top 10 c.customer_unique_id, sum(p.payment_value) as total_amount_paid
from customers c 
inner join orders o on o.customer_id = c.customer_id
inner join payments p on p.order_id = o.order_id
group by c.customer_unique_id
order by total_amount_paid desc;

/* 🟢 4. Payment Method Distribution */

select payment_type, count(*) as payment_counts, sum(payment_value) as total_amount
from payments
group by payment_type
order by total_amount desc;

/* 🟢 4. Average Order Value (AOV)*/

select sum(payment_value)/count(distinct order_id) as avg_order_value
from payments;

/* 🔵 7. Monthly Running Revenue (Window Function) */
with monthly_sales as (
select 
format(o.order_purchase_timestamp,'yyyy') as order_year
,format(o.order_purchase_timestamp,'MM') as order_month
,sum(p.payment_value) as total_amount
from orders o
inner join payments p on p.order_id = o.order_id
group by format(o.order_purchase_timestamp,'yyyy'),format(o.order_purchase_timestamp,'MM')
)
select *, 
sum(total_amount) over(partition by order_year order by order_month rows between unbounded preceding and current row ) as runnning_total_sum
from monthly_sales;

/* 🔵 8. Customer Segmentation (CASE) */

with customer_segment as (
select o.customer_id, sum(p.payment_value) as total_amount_paid
,case when sum(p.payment_value) > 1000 then 'High_Value'
      when sum(p.payment_value)  between 500 and 1000 then 'Medium_Value'
      else 'Low_Value' end as customer_segmentation
from orders o
inner join payments p on p.order_id = o.order_id
group by customer_id)
select 
concat(cast(sum(case when customer_segmentation = 'High_Value' then 1 else null end)*100.0/count(*) as decimal(10,3)),'%') as high_val_customers_percentage
,concat(cast(sum(case when customer_segmentation = 'Low_Value' then 1 else null end)*100.0/count(*) as decimal(10,3)),'%') as low_val_customers_percentage
,concat(cast(sum(case when customer_segmentation = 'Medium_Value' then 1 else null end)*100.0/count(*) as decimal(10,3)),'%') as medium_val_customers_percentage
from customer_segment;

/*
1. Revenue peaked in November
2. Most customers are low-value → opportunity for upselling
3. Credit cards dominate payments → optimize checkout experience
4. Small % of customers drive majority of revenue
*/