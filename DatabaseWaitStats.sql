
/*** Connect to DATABASE USER ***/

/* 
Azure SQL Database wait stats  

Doc: https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-wait-stats-azure-sql-database
*/

SELECT   TOP (10) wait_type,
                  CAST (([wait_time_ms] / 1000.0) AS DECIMAL (16, 2)) AS [WaitS],
                  CAST (100.0 * [wait_time_ms] / SUM([wait_time_ms]) OVER () AS DECIMAL (16, 2)) AS [Percentage]
FROM     sys.dm_db_wait_stats
ORDER BY [Percentage] DESC;


SELECT SUM(signal_wait_time_ms) as [Signal wait time (ms)],
	CAST(100.0 * SUM(signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)) as [Signal (cpu) waits %],
    SUM(wait_time_ms - signal_wait_time_ms) as [Resource wait time (ms)],
    CAST(100.0 * SUM(wait_time_ms - signal_wait_time_ms) / SUM (wait_time_ms) AS NUMERIC(20,2)) as [Resource waits %]
FROM sys.dm_os_wait_stats;

