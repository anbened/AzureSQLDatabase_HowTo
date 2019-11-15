
/*** Connect to DATABASE USER ***/

/* The average and maximum values for CPU percent, 
data and log I/O, and memory consumption over the last hou */

/*
Returns CPU, I/O, and memory consumption for an Azure SQL Database database. 
One row exists for every 15 seconds, even if there is no activity in the database. 
Historical data is maintained for one hour.
*/
SELECT   
	'AVG' as Info,
    AVG(avg_cpu_percent) AS 'CPU Utilization In Percent',   
    AVG(avg_data_io_percent) AS 'Data IO In Percent',   
    AVG(avg_log_write_percent) AS 'Log Write I/O Throughput Utilization In Percent',   
    AVG(avg_memory_usage_percent) AS 'Memory Usage In Percent'
FROM sys.dm_db_resource_stats
UNION
SELECT 
	'MAX' as Info,
    MAX(avg_cpu_percent) AS 'CPU Utilization In Percent',   
    MAX(avg_data_io_percent) AS 'Data IO In Percent',   
    MAX(avg_log_write_percent) AS 'Log Write I/O Throughput Utilization In Percent',   
    MAX(avg_memory_usage_percent) AS 'Memory Usage In Percent'   
FROM sys.dm_db_resource_stats

/* single row */
SELECT   
	'AVG' as Info,
    AVG(avg_cpu_percent) AS 'Average CPU Utilization In Percent',   
    MAX(avg_cpu_percent) AS 'Maximum CPU Utilization In Percent',   
    AVG(avg_data_io_percent) AS 'Average Data IO In Percent',   
    MAX(avg_data_io_percent) AS 'Maximum Data IO In Percent',   
    AVG(avg_log_write_percent) AS 'Average Log Write I/O Throughput Utilization In Percent',   
    MAX(avg_log_write_percent) AS 'Maximum Log Write I/O Throughput Utilization In Percent',   
    AVG(avg_memory_usage_percent) AS 'Average Memory Usage In Percent',   
    MAX(avg_memory_usage_percent) AS 'Maximum Memory Usage In Percent'   
FROM sys.dm_db_resource_stats
