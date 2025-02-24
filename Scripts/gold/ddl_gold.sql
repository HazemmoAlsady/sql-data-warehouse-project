/***************************************************************************
DDL Script: Create Gold Layer Views
***************************************************************************
Script Purpose:
    This script creates views in the 'gold' schema for dimensional modeling.
    Run this script to define the structure of the Gold Layer Views.
***************************************************************************/

-- Drop views if they already exist
DROP VIEW IF EXISTS gold.dim_customers;
DROP VIEW IF EXISTS gold.dim_products;
DROP VIEW IF EXISTS gold.face_sales;
----------------------------------------------------------------------
-- create dimesnsion : gold.dim_customers
----------------------------------------------------------------------
create view gold.dim_customers AS
select 
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.cntry AS country,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the master for gender Info
		 ELSE COALESCE(ca.gen, 'n/a')
	END AS gender,
	ca.bdate AS birthdate,
	cst_create_date AS create_date
from silver.crm_cust_info as ci
LEFT JOIN silver.erp_cust_az12 as ca
ON		  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 as la
ON		  ci.cst_key = la.cid


----------------------------------------------------------------------
-- create dimesnsion : gold.dim_products
----------------------------------------------------------------------
create view gold.dim_products AS 
SELECT 
	ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key ) AS product_key,
	pn.prd_id AS product_id,
	pn.prd_key AS product_number,
	pn.prd_nm AS product_name,
	pn.cat_id AS category_id,
	pc.cat AS category,
	pc.subcat AS subcategory,
	pc.maintenance,
	pn.prd_cost AS cost,
	pn.prd_line AS product_line,
	pn.prd_start_dt AS start_date
from silver.crm_prd_info AS pn
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
ON		  pn.cat_id = pc.id

----------------------------------------------------------------------
-- create dimesnsion : gold.face_sales
----------------------------------------------------------------------
create view gold.face_sales AS
select 
	sd.sls_ord_num AS order_number,
	pr.product_key,
	cu.customer_key,
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS shipping_date,
	sd.sls_due_dt AS due_date,
	sd.sls_sales AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price AS price
from silver.crm_sales_details as sd
LEFT JOIN gold.dim_products as pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers as cu
ON sd.sls_cust_id = cu.customer_id
