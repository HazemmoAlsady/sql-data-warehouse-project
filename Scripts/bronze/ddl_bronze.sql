/*
*****************************************************************************
DDL Script: Create Bronze Tables
******************************************************************************
Script Purpose:
    This script creata table in the 'bronze' schema, droping existing tables
    if they already exist
  Run this scirpt to re_defined the DLL structure of 'bronze' Tables
*******************************************************************************
*/

IF OBJECT_ID ('bronze.crm_cust_info', 'U') IS NOT NULL
	DROP TABLE bronze.crm_cust_info;
CREATE TABLE bronze.crm_cust_info (
	cst_id INT,
	cst_key nvarchar(50),
	cst_firstname nvarchar(50),
	cst_lastname nvarchar(50),
	cst_marital_status nvarchar(50),
	cst_gndr nvarchar(50),
	cst_create_date date
);

IF OBJECT_ID ('bronze.crm_prd_info', 'U') IS NOT NULL
	DROP TABLE bronze.crm_prd_info;
create table bronze.crm_prd_info (
	prd_id INT,
	prd_key nvarchar(50),
	prd_nm nvarchar(50),
	prd_cost nvarchar(50),
	prd_line nvarchar(50),
	prd_start_dt datetime,
	prd_end_dt datetime
);

IF OBJECT_ID ('bronze.crm_sales_details', 'U') IS NOT NULL
	DROP TABLE bronze.crm_sales_details;
create table bronze.crm_sales_details (
	sls_ord_num nvarchar(50),
	sls_prd_key nvarchar(50),
	sls_cust_id INT,
	sls_order_dt INT,
	sls_ship_dt INT,
	sls_due_dt INT,
	sls_sales INT,
	sls_quantity INT,
	sls_price INT
);

IF OBJECT_ID ('bronze.erp_cust_az12', 'U') IS NOT NULL
	DROP TABLE bronze.erp_cust_az12;
create table bronze.erp_cust_az12 (
	cid nvarchar(50),
	bdate datetime,
	gen nvarchar(50),
);

IF OBJECT_ID ('bronze.erp_loc_a101', 'U') IS NOT NULL
	DROP TABLE bronze.erp_loc_a101;
create table bronze.erp_loc_a101 (
	cid nvarchar(50),
	cntry nvarchar(50),
);

IF OBJECT_ID ('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
	DROP TABLE bronze.erp_px_cat_g1v2;
create table bronze.erp_px_cat_g1v2 (
	id nvarchar(50),
	cat nvarchar(50),
	subcat nvarchar(50),
	maintenance nvarchar(50)
);
