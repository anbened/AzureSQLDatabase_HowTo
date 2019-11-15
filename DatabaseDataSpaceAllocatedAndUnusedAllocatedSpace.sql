
/*** Connect to DATABASE USER ***/
/*** Database data space used ***/
/* Query to determine storage space quantities and other info for a single database 

- Data Space Used = The amount of space used to store database data in 8 KB pages
- Data Space Allocated = The amount of formatted file space made available for storing database data
- Data space allocated but unused	= The difference between the amount of data space allocated and data space used.
- Data max size = The maximum amount of space that can be used for storing database data
*/
SELECT 
	db_name() as [DB Name],
	cast((((cast(DATABASEPROPERTYEX(db_name(), 'MaxSizeInBytes') as decimal(20,2))/1024.0)/1024.0)/1024.0) as decimal(15,2)) AS [DB Data Max Size (GB)], 
	SUM(size / 128.0) AS [DB Data Space Allocated (MB)],
    SUM(size / 128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS INT) / 128.0) AS [DB Data Space Allocated Unused (MB)]
FROM sys.database_files
GROUP BY type_desc
HAVING type_desc = 'ROWS';
