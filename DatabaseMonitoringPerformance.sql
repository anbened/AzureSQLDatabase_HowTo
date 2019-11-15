
/*** Connect to DATABASE USER ***/
/*
Monitoring performance Azure SQL Database 
*/

/*Identify CPU performance issues */
/* Top 10 Active CPU Consuming Queries (aggregated) */
SELECT TOP 10 
	GETDATE() as [Get Date], 
	*
FROM
(
    SELECT query_stats.query_hash, 
		SUBSTRING(REPLACE(REPLACE(MIN(query_stats.statement_text), CHAR(10), ' '), CHAR(13), ' '), 1, 256) AS [Statement_Text],
		SUM(query_stats.cpu_time) as [Total Request Cpu Time (ms)], 
		SUM(logical_reads) as [Total Request Logical Reads], 
		MIN(start_time) as [Earliest Request start Time], 
		COUNT(*) 'Number_Of_Requests'
    FROM
    (
        SELECT req.*, 
               SUBSTRING(ST.text, (req.statement_start_offset / 2) + 1, ((CASE statement_end_offset
                                                                              WHEN-1
                                                                              THEN DATALENGTH(ST.text)
                                                                              ELSE req.statement_end_offset
                                                                          END - req.statement_start_offset) / 2) + 1) AS statement_text
        FROM sys.dm_exec_requests AS req
             CROSS APPLY sys.dm_exec_sql_text(req.sql_handle) AS ST
    ) AS query_stats
    GROUP BY query_hash
) AS t
ORDER BY [Total Request Cpu Time (ms)] DESC;


/* Top 15 CPU consuming queries by query hash
Note that a query hash can have many query id if not parameterized or not parameterized properly it grabs a sample query text by min */
WITH AggregatedCPU AS 
(
	SELECT q.query_hash, SUM(count_executions * avg_cpu_time / 1000.0) AS total_cpu_millisec, SUM(count_executions * avg_cpu_time / 1000.0)/ SUM(count_executions) AS avg_cpu_millisec, MAX(rs.max_cpu_time / 1000.00) AS max_cpu_millisec, MAX(max_logical_io_reads) max_logical_reads, COUNT(DISTINCT p.plan_id) AS number_of_distinct_plans, COUNT(DISTINCT p.query_id) AS number_of_distinct_query_ids, SUM(CASE WHEN rs.execution_type_desc='Aborted' THEN count_executions ELSE 0 END) AS Aborted_Execution_Count, SUM(CASE WHEN rs.execution_type_desc='Regular' THEN count_executions ELSE 0 END) AS Regular_Execution_Count, SUM(CASE WHEN rs.execution_type_desc='Exception' THEN count_executions ELSE 0 END) AS Exception_Execution_Count, SUM(count_executions) AS total_executions, MIN(qt.query_sql_text) AS sampled_query_text
    FROM sys.query_store_query_text AS qt
        JOIN sys.query_store_query AS q ON qt.query_text_id=q.query_text_id
        JOIN sys.query_store_plan AS p ON q.query_id=p.query_id
        JOIN sys.query_store_runtime_stats AS rs ON rs.plan_id=p.plan_id
        JOIN sys.query_store_runtime_stats_interval AS rsi ON rsi.runtime_stats_interval_id=rs.runtime_stats_interval_id
    WHERE rs.execution_type_desc IN ('Regular', 'Aborted', 'Exception')AND rsi.start_time>=DATEADD(HOUR, -2, GETUTCDATE())
    GROUP BY q.query_hash), OrderedCPU AS 
	(
		SELECT 
			query_hash, total_cpu_millisec, avg_cpu_millisec, 
			max_cpu_millisec, max_logical_reads, number_of_distinct_plans, 
			number_of_distinct_query_ids, total_executions, 
			Aborted_Execution_Count, Regular_Execution_Count, 
			Exception_Execution_Count, sampled_query_text, 
			ROW_NUMBER() OVER (ORDER BY total_cpu_millisec DESC, query_hash ASC) AS RN
        FROM AggregatedCPU
	)
SELECT 
	OD.query_hash, 
	OD.sampled_query_text, 
	OD.total_cpu_millisec, 
	OD.avg_cpu_millisec, 
	OD.max_cpu_millisec, 
	OD.max_logical_reads, 
	OD.number_of_distinct_plans, 
	OD.number_of_distinct_query_ids, 
	OD.total_executions, 
	OD.Aborted_Execution_Count, 
	OD.Regular_Execution_Count, 
	OD.Exception_Execution_Count, 
	OD.RN
FROM OrderedCPU AS OD
WHERE OD.RN<=15
ORDER BY total_cpu_millisec DESC;


/* Identify IO performance issues */
/* Top queries that waited on buffer note these are finished queries */
WITH Aggregated AS (SELECT q.query_hash, SUM(total_query_wait_time_ms) total_wait_time_ms, SUM(total_query_wait_time_ms / avg_query_wait_time_ms) AS total_executions, MIN(qt.query_sql_text) AS sampled_query_text, MIN(wait_category_desc) AS wait_category_desc
                    FROM sys.query_store_query_text AS qt
                         JOIN sys.query_store_query AS q ON qt.query_text_id=q.query_text_id
                         JOIN sys.query_store_plan AS p ON q.query_id=p.query_id
                         JOIN sys.query_store_wait_stats AS waits ON waits.plan_id=p.plan_id
                         JOIN sys.query_store_runtime_stats_interval AS rsi ON rsi.runtime_stats_interval_id=waits.runtime_stats_interval_id
                    WHERE wait_category_desc='Buffer IO' AND rsi.start_time>=DATEADD(HOUR, -2, GETUTCDATE())
                    GROUP BY q.query_hash), Ordered AS (SELECT query_hash, total_executions, total_wait_time_ms, sampled_query_text, wait_category_desc, ROW_NUMBER() OVER (ORDER BY total_wait_time_ms DESC, query_hash ASC) AS RN
                                                        FROM Aggregated)
SELECT OD.query_hash, OD.total_executions, OD.total_wait_time_ms, OD.sampled_query_text, OD.wait_category_desc, OD.RN
FROM Ordered AS OD
WHERE OD.RN<=15
ORDER BY total_wait_time_ms DESC;
GO

/* View total log IO for WRITELOG waits  */
/* Top transaction log consumers

Adjust the time window by changing:

rsi.start_time >= DATEADD(hour, -2, GETUTCDATE()) */
WITH AggregatedLogUsed
AS (SELECT q.query_hash,
           SUM(count_executions * avg_cpu_time / 1000.0) AS total_cpu_millisec,
           SUM(count_executions * avg_cpu_time / 1000.0) / SUM(count_executions) AS avg_cpu_millisec,
           SUM(count_executions * avg_log_bytes_used) AS total_log_bytes_used,
           MAX(rs.max_cpu_time / 1000.00) AS max_cpu_millisec,
           MAX(max_logical_io_reads) max_logical_reads,
           COUNT(DISTINCT p.plan_id) AS number_of_distinct_plans,
           COUNT(DISTINCT p.query_id) AS number_of_distinct_query_ids,
           SUM(   CASE
                      WHEN rs.execution_type_desc = 'Aborted' THEN
                          count_executions
                      ELSE
                          0
                  END
              ) AS Aborted_Execution_Count,
           SUM(   CASE
                      WHEN rs.execution_type_desc = 'Regular' THEN
                          count_executions
                      ELSE
                          0
                  END
              ) AS Regular_Execution_Count,
           SUM(   CASE
                      WHEN rs.execution_type_desc = 'Exception' THEN
                          count_executions
                      ELSE
                          0
                  END
              ) AS Exception_Execution_Count,
           SUM(count_executions) AS total_executions,
           MIN(qt.query_sql_text) AS sampled_query_text
    FROM sys.query_store_query_text AS qt
        JOIN sys.query_store_query AS q
            ON qt.query_text_id = q.query_text_id
        JOIN sys.query_store_plan AS p
            ON q.query_id = p.query_id
        JOIN sys.query_store_runtime_stats AS rs
            ON rs.plan_id = p.plan_id
        JOIN sys.query_store_runtime_stats_interval AS rsi
            ON rsi.runtime_stats_interval_id = rs.runtime_stats_interval_id
    WHERE rs.execution_type_desc IN ( 'Regular', 'Aborted', 'Exception' )
          AND rsi.start_time >= DATEADD(HOUR, -2, GETUTCDATE())
    GROUP BY q.query_hash),
     OrderedLogUsed
AS (SELECT query_hash,
           total_log_bytes_used,
           number_of_distinct_plans,
           number_of_distinct_query_ids,
           total_executions,
           Aborted_Execution_Count,
           Regular_Execution_Count,
           Exception_Execution_Count,
           sampled_query_text,
           ROW_NUMBER() OVER (ORDER BY total_log_bytes_used DESC, query_hash ASC) AS RN
    FROM AggregatedLogUsed)
SELECT OD.total_log_bytes_used,
       OD.number_of_distinct_plans,
       OD.number_of_distinct_query_ids,
       OD.total_executions,
       OD.Aborted_Execution_Count,
       OD.Regular_Execution_Count,
       OD.Exception_Execution_Count,
       OD.sampled_query_text,
       OD.RN
FROM OrderedLogUsed AS OD
WHERE OD.RN <= 15
ORDER BY total_log_bytes_used DESC;
GO

