
SELECT TOP 10 
		queryStatement =   IIF(LEFT(t.query_sql_text,1) = '(', TRIM(')' FROM SUBSTRING( t.query_sql_text, (PATINDEX( '%)[^),]%', t.query_sql_text))+1, LEN(t.query_sql_text))), t.query_sql_text) ,
		params =  IIF(LEFT(t.query_sql_text,1) = '(', SUBSTRING( t.query_sql_text, 2, (PATINDEX( '%)[^),]%', t.query_sql_text+')'))-2), '') ,
		rs.plan_id,
		rs.execution_type_desc,
		rs.count_executions,
		duration_s = CAST(ROUND( rs.avg_duration /1000.0 /1000.0, 2) AS NUMERIC(12,2)),
		cpu_time_ms = CAST(ROUND(rs.avg_cpu_time /1000.0, 1) AS NUMERIC(12,1)),
		logical_io_reads_kb = CAST(ROUND(rs.avg_logical_io_reads * 8 /1000.0, 2) AS NUMERIC(12,2)),
		logical_io_writes_kb = CAST(ROUND(rs.avg_logical_io_writes * 8 /1000.0, 2) AS NUMERIC(12,2)),
		physical_io_reads_kb = CAST(ROUND(rs.avg_physical_io_reads * 8 /1000.0, 2) AS NUMERIC(12,2)),
		clr_time_ms = CAST(ROUND(rs.avg_clr_time /1000.0, 1) AS NUMERIC(12,1)),
		max_used_memory_mb = rs.avg_query_max_used_memory * 8.0 /1000,

		num_physical_io_reads = rs.avg_num_physical_io_reads,
		log_bytes_used_kb = CAST(ROUND( rs.avg_log_bytes_used /1000.0, 2) AS NUMERIC(12,2)),
		tempdb_used_mb = CAST(ROUND(rs.avg_tempdb_space_used *8 /1000.0, 2) AS NUMERIC(12,2)),

		start_time = rsi.start_time,
		end_time = convert(varchar(16), rsi.end_time, 20),
		interval_mi = datediff(mi, rsi.start_time, rsi.end_time),
		q.context_settings_id, q.query_hash
FROM sys.query_store_query_text t
	join sys.query_store_query q on t.query_text_id = q.query_text_id
	join sys.query_store_plan p on p.query_id = q.query_id
	join sys.query_store_runtime_stats rs on rs.plan_id = p.plan_id
	join sys.query_store_runtime_stats_interval rsi
		on rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
--where 
	--start_time >= '20200101' and start_time <= '20200120' and
	--CAST(ROUND(rs.avg_cpu_time /1000.0, 1) AS NUMERIC(12,1)) > 100
ORDER BY cpu_time_ms DESC
