create table customers (
customer_id	int4,
first_name varchar(50),
last_name varchar(50),
gender varchar(30),	
DOB varchar(50),	
job_title varchar(50),
job_industry_category varchar(50),	
wealth_segment varchar(50),	
deceased_indicator varchar(50),	
owns_car varchar(50),
address varchar(50),
postcode varchar(30),
state varchar(30),
country varchar(30),
property_valuation int4);

create table transactions (
 transaction_id	int4,
 product_id	int4,
 customer_id int4,	
 transaction_date varchar(30),	
 online_order varchar(30),	
 order_status varchar(30),	
 brand varchar(30),	
 product_line varchar(30),	
 product_class varchar(30),
 product_size varchar(30),
 list_price	float4,
 standard_cost float4
);

-- Вывести распределение (количество) клиентов по сферам деятельности, отсортировав результат по убыванию количества. */
SELECT job_industry_category, count (*) as count_job_industry_category 
FROM customers 
GROUP BY job_industry_category
order by count_job_industry_category desc 

-- Найти сумму транзакций за каждый месяц по сферам деятельности, отсортировав по месяцам и по сфере деятельности. */
select date_trunc('month',tr.transaction_date::date) as transactions_month, 
	sum(tr.list_price) as transactions_sum, 
	cus.job_industry_category as job_cat 
from transactions as tr 
	left join customers as cus 
	on tr.customer_id = cus.customer_id 
group by transactions_month, job_cat 
order by transactions_month, job_cat 

--Вывести количество онлайн-заказов для всех брендов в рамках подтвержденных заказов клиентов из сферы IT. */
select tr.brand as brand, count(*) as count_orders 
from transactions as tr 
	left join customers as cus  
	on tr.customer_id = cus.customer_id 
where tr.online_order = 'True' and tr.online_order = 'True' and tr.order_status = 'Approved' and cus.job_industry_category = 'IT'
group by brand

-- Найти по всем клиентам сумму всех транзакций (list_price), максимум, минимум и количество транзакций, отсортировав результат по убыванию суммы транзакций и количества клиентов. 
--Выполните двумя способами: используя только group by и используя только оконные функции. Сравните результат. */
select tr.customer_id as customer_id, 
	count(*) as count_transactions,
	sum(tr.list_price) as sum_price 
from transactions as tr 
group by customer_id
order by sum_price desc, count_transactions desc 


SELECT 
 tr_base.customer_id as customer_id,
 max(tr_base.count_transactions) over (partition by tr_base.customer_id) as count_transactions_max,
 tr_base.sum_price as sum_price
FROM (select 
	customer_id as customer_id,
	count(*) 		over (partition by customer_id) as count_transactions,
	sum(list_price) over (partition by customer_id) as sum_price
from transactions) AS tr_base
order by sum_price desc, count_transactions_max desc

-- Найти имена и фамилии клиентов с минимальной/максимальной суммой транзакций за весь период (сумма транзакций не может быть null). 
-- Напишите отдельные запросы для минимальной и максимальной суммы. */
select cus.first_name, 
	   cus.last_name,
	   max(tr.list_price) as max_trans
from transactions as tr 
	left join customers as cus  
	on tr.customer_id = cus.customer_id 
group by cus.first_name,cus.last_name
order by max_trans desc 

select cus.first_name, 
	   cus.last_name,
	   min(tr.list_price) as min_trans
from transactions as tr 
	left join customers as cus  
	on tr.customer_id = cus.customer_id 
group by cus.first_name,cus.last_name
order by min_trans  

-- Вывести только самые первые транзакции клиентов. Решить с помощью оконных функций. */
select 
 tr.*
from 
(select 
	distinct 
	customer_id,
	min(transaction_id) over (partition by customer_id) as transaction_id
from transactions) as tr_min left join transactions as tr 
on tr_min.transaction_id = tr.transaction_id
order by tr.customer_id

-- Вывести имена, фамилии и профессии клиентов, между транзакциями которых был максимальный интервал (интервал вычисляется в днях) */
select 
 cust.first_name as first_name,
 cust.last_name as last_name, 
 max(coalesce(max_lag.diff,0)) as max_diff
from customers as cust
left join (select 
 customer_id,
 lead(transaction_date::date) over (partition by customer_id) - lag(transaction_date::date) over (partition by customer_id)  as diff
from 
 transactions) as max_lag 
 on cust.customer_id = max_lag.customer_id
group by first_name,last_name
order by max_diff desc