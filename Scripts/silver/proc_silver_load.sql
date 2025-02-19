EXEC silver.load_silver


CREATE OR ALTER PROCEDURE  silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME , @batch_end_time DATETIME
	BEGIN TRY
		---- Loading crm_cust_info -------------
		SET @batch_start_time = GETDATE()
		PRINT '==================================================='
		PRINT 'Loading Silver Layer';
		PRINT '==================================================='

		PRINT '---------------------------------------------------'
		PRINT 'Loading CRM Tables';
		PRINT '---------------------------------------------------'

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info
		PRINT '>> Inserting Date Into: Silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info (
				cst_id,
				cst_key,
				cst_firstname,
				cst_lastname,
				cst_marital_status,
				cst_gndr,
				cst_create_date
			)
			select
				cst_id,
				cst_key,
				TRIM(cst_firstname) AS cst_firstname,
				TRIM(cst_lastname) AS cst_lastname,
				CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
					 WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
					 ELse 'n/a'
				END cst_marital_status,  -- Normalize marital status values to readable format
				CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
					 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
					 ELse 'n/a'
				END cst_gndr, -- Normalize gender values to readable format
				cst_create_date
			from (
			select
			*,
			ROW_NUMBER() over (partition by cst_id order by cst_create_date DESC) as flag_last
			from bronze.crm_cust_info) t
			where flag_last = 1; -- select the most recent record per customer
		SET @end_time = GETDATE();
		PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seoncds';



		---- Loading crm_prd_info -----------------------
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info
		PRINT '>> Inserting Date Into: silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info (
				prd_id,
				cat_id,
				prd_key, 
				prd_nm,
				prd_cost,
				prd_line,
				prd_start_dt,
				prd_end_dt
			)
			select 
				prd_id,
				REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id, -- Extract category ID
				SUBSTRING(prd_key, 7, len(prd_key)) AS prd_key, -- Extract Product Key
				prd_nm,
				ISNULL(prd_cost, 0) AS prd_cost,
				CASE UPPER(TRIM(prd_line))
					WHEN 'M' THEN 'Mountain'
					WHEN 'R' THEN 'Road'
					WHEN 'S' THEN 'Other Sales'
					WHEN 'T' THEN 'Touring'
					ELSE 'n/a'
				END AS prd_line, -- Map Product Line codes to descriptive values
				CAST(prd_start_dt AS DATE) AS prd_start_dt,
				CAST(
					lead(prd_start_dt) over(partition by prd_key order by prd_start_dt)-1 
					AS DATE
				) as prd_end_dt -- Calculate end date as one day before the next start date
			from bronze.crm_prd_info
		SET @end_time = GETDATE();
		PRINT '>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seoncds';

		---- Loading crm_sales_details --------------------
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details
		PRINT '>> Inserting Date Into: Silver.crm_sales_details';
		INSERT INTO silver.crm_sales_details (
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt, 
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
			select 
				sls_ord_num,
				sls_prd_key,
				sls_cust_id,
				CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
					 Else CAST(CAST(sls_order_dt AS varchar) AS DATE)
				END AS sls_order_dt,
				CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
					 Else CAST(CAST(sls_ship_dt AS varchar) AS DATE)
				END AS sls_ship_dt,
				CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
					 Else CAST(CAST(sls_due_dt AS varchar) AS DATE)
				END AS sls_due_dt,
				CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
						THEN sls_quantity * ABS(sls_price)
					 ELSE sls_sales
				END AS sls_sales, -- Recalculate sales if original value is missing or incorrect
				sls_quantity,
				CASE WHEN sls_price IS NULL OR sls_price <= 0
						THEN sls_sales / NULLIF(sls_quantity, 0)
					ELSE sls_price -- Derive price if original value is invalid
				END AS sls_price
			from bronze.crm_sales_details
		SET @end_time = GETDATE();
		PRINT '>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seoncds';


		---- Loading erp_cust_az12 -----------------------------
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12
		PRINT '>> Inserting Date Into: Silver.erp_cust_az12';
		INSERT INTO silver.erp_cust_az12 (
			cid,
			bdate,
			gen
		)
			select 
				CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) -- Remove 'NAS' prefix if present
					 ELSE cid
				END cid,
				CASE 
					 WHEN bdate > GETDATE() 
						THEN NULL
					 ELSE bdate -- set future birthdate to NULL
				END AS bdate,
				CASE 
					WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
					WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
					ELSE 'n/a'
				END AS gen -- Normaize gender value and handle unknown cases
			from bronze.erp_cust_az12 
		SET @end_time = GETDATE();
		PRINT '>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seoncds';

		---- Loading erp_loc_a101 -----------------------------------
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101
		PRINT '>> Inserting Date Into: Silver.erp_loc_a101';
		INSERT INTO silver.erp_loc_a101 (cid, cntry)
			select 
				REPLACE(cid, '-', '') cid,
				CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
					 WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
					 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
					 ELSE TRIM(cntry)
				END AS cntry
			from bronze.erp_loc_a101
		SET @end_time = GETDATE();
		PRINT '>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seoncds';



		---- Loading erp_px_cat_g1v2 ---------------
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2
		PRINT '>> Inserting Date Into: Silver.erp_px_cat_g1v2';
		INSERT INTO silver.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
			select 
				id,
				cat,
				subcat,
				maintenance
			from bronze.erp_px_cat_g1v2 
		SET @end_time = GETDATE();
		PRINT '>> Load Duration ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' Seoncds';
		PRINT '>> ---------------';

		SET @batch_end_time = GETDATE()
		PRINT '===================================================';
		PRINT 'Loading silver layer is completed';
		PRINT ' -- Total Duration : ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' Seconds';
		PRINT '===================================================';
	END TRY 
	BEGIN CATCH
		PRINT 'ERROR OCCURED DURING LOADING DATE FROM BROZNE LAYER TO SLIVER LAYER';
		PRINT 'ERROR Message ' + ERROR_MESSAGE();
		PRINT 'ERROR Message ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT 'ERROR Message ' + CAST(ERROR_STATE() AS NVARCHAR);
	END CATCH
END
