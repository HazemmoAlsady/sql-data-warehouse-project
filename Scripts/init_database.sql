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

-- Drop the database if it exists
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    PRINT 'Dropping existing DataWarehouse database...';
    
    -- Terminate all connections before dropping the database
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
    
    PRINT 'Database DataWarehouse dropped successfully.';
END
ELSE
BEGIN
    PRINT 'Database DataWarehouse does not exist. No action taken.';
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
