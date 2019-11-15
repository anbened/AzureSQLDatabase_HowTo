
/*** Connect to DATABASE USER ***/

/* Size of the database */
SELECT SUM(CAST(FILEPROPERTY(name, 'SpaceUsed') AS bigint) * 8192.) / 1024 / 1024 AS DatabaseSizeInMB
FROM sys.database_files
WHERE type_desc = 'ROWS';
GO

/* Calculates the size of individual database objects */
SELECT 
	sys.objects.name as [Object], 
	sys.objects.type_desc as [Obj Type],
	SUM(reserved_page_count) * 8.0 / 1024 as [Obj Size (MB)]
FROM sys.dm_db_partition_stats, sys.objects
WHERE sys.dm_db_partition_stats.object_id = sys.objects.object_id
GROUP BY sys.objects.name, sys.objects.type_desc
ORDER BY SUM(reserved_page_count) desc;
