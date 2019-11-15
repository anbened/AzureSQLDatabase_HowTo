
/*** Connect to MASTER ***/

/*
Returns info like edition (service tier), pricing tier and elastic pool name, if any, ... 
for an Azure SQL database or an Azure SQL Data Warehouse
*/

select 
	db_name(database_id) as [DB Name],
	edition as [Service Tier],
	service_objective as [Pricing Tier],
	case (DatabasePropertyEx(DB_Name(), 'IsXTPSupported')) when 1 then 'Yes' else 'No' end as [In-Memory Support]
from sys.database_service_objectives
where edition != 'System'

