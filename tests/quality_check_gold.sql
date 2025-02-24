-- ---------------------------------------------------------------------
-- checking 'gold.dim_customers'
-- ---------------------------------------------------------------------

select 
	customer_key,
	count(*) AS duplicate_count
from gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- ---------------------------------------------------------------------
-- checking 'gold.dim_products'
-- ---------------------------------------------------------------------
select 
	product_key,
	count(*) AS duplicate_count
from gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- ---------------------------------------------------------------------
-- checking 'gold.face_sales'
-- ---------------------------------------------------------------------
select *
from gold.face_sales f
left join gold.dim_customers c
ON c.customer_key = f.customer_key
left join gold.dim_products p
ON p.product_key = f.product_key
WHERE p.product_key IS NULL OR c.customer_key IS NULL

