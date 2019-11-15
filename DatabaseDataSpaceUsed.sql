
/*** Connect to MASTER ***/
/*** Database data space used ***/
/* Query to determine storage space quantities and other info for a single database 

- Data Space Used = The amount of space used to store database data in 8 KB pages
- Data Space Allocated = The amount of formatted file space made available for storing database data
- Data space allocated but unused	= The difference between the amount of data space allocated and data space used.
- Data max size = The maximum amount of space that can be used for storing database data
*/
SELECT 
	   RS.database_name AS [DB Name], 
	   RS.sku AS [Sku], 
       RS.storage_in_megabytes AS [DB Data Space Used (MB)], 
       RS.allocated_storage_in_megabytes AS [Allocated Storage (MB)], 
       RS.avg_instance_cpu_percent AS [Avg Instance CPU %], 
       RS.avg_instance_memory_percent AS [Avg Instance Memory %], 
       RS.cpu_limit AS [CPU Limit]
FROM sys.resource_stats RS
     JOIN
(
    SELECT database_name AS [database_name],
           --storage_in_megabytes AS [DB Data Space Used In MB],
           max(end_time) AS [End_Time]
    --*
    FROM sys.resource_stats
    GROUP BY database_name
) RSInfo ON RS.database_name = RSInfo.database_name
            AND RS.end_time = RSInfo.end_time
WHERE rs.sku != 'DW'
ORDER BY rs.database_name;