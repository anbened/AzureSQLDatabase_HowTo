
/*** Connect to MASTER ***/
/*
Returns info like edition (service tier), pricing tier and elastic pool name, if any, ... 
for an Azure SQL database or an Azure SQL Data Warehouse
*/

SELECT 
	@@SERVERNAME as [ServerName],
	d.name AS [DB Name], 
       so.edition AS [Service Tier], 
       so.service_objective AS [Pricing Tier], 
       d.create_date AS [DB Create Date], 
       d.compatibility_level AS [DB Compatibility Level],
       CASE(d.is_encrypted)
           WHEN 1
           THEN 'Yes'
           ELSE 'No'
       END AS [Encrypted],
       CASE(DATABASEPROPERTYEX(DB_NAME(), 'IsXTPSupported'))
           WHEN 1
           THEN 'Yes'
           ELSE 'No'
       END AS [In-Memory Support], 
       (CASE
            WHEN so.elastic_pool_name IS NULL
            THEN 'No Elastic Pool used'
            ELSE so.elastic_pool_name
        END) AS [Elastic Pool Info]
FROM sys.databases d
     JOIN sys.database_service_objectives so ON d.database_id = so.database_id
WHERE edition != 'System'
ORDER BY d.name;
