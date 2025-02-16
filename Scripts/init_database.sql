/*
=====================================================================
  Script Purpose :  This script creates a Data Warehouse with structured 
               schemas (Bronze, Silver, and Gold) following best 
               practices in Data Engineering.

  Warning : Running this script in a production environment may cause conflicts if the DataWarehouse database already exists.
Ensure no active connections to DataWarehouse before executing to avoid locking issues.
=====================================================================
*/
-- Create Database 'DataWarehouse'

use master;
GO

-- Create database only if it doesn't exist  
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'DataWarehouse')  
BEGIN  
    CREATE DATABASE DataWarehouse;  
END  
GO  
-- create the 'DataWarehouse' database
CREATE DATABASE DataWarehouse;
GO

use DataWarehouse;
GO

-- create schemas
create schema bronze;
GO
  
create schema silver;
GO
  
create schema gold;
GO
