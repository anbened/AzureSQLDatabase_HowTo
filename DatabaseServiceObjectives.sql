
/*** Connect to MASTER ***/

/*
Returns info like edition (service tier), pricing tier and elastic pool name, if any, ... 
for an Azure SQL database or an Azure SQL Data Warehouse
*/

select 
	d.name as [DB Name],
	so.edition as [Service Tier],
	so.service_objective as [Pricing Tier],
	d.create_date as [DB Create Date],
	d.compatibility_level as [DB Compatibility Level],
	case (d.is_encrypted) when 1 then 'Yes' else 'No' end as [Encrypted],
	case (DatabasePropertyEx(DB_Name(), 'IsXTPSupported')) when 1 then 'Yes' else 'No' end as [In-Memory Support]
FROM sys.databases d   
JOIN sys.database_service_objectives so 
ON d.database_id = so.database_id
where edition != 'System'
order by d.name

