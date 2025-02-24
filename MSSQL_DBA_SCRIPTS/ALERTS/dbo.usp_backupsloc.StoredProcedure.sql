USE [master]
GO
/****** Object:  StoredProcedure [dbo].[usp_backupsloc]    Script Date: 2/6/2025 1:17:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[usp_backupsloc] ( @db_name VARCHAR(100), @backup_type VARCHAR(100))

AS BEGIN


SELECT TOP (30) s.database_name,m.physical_device_name
,CAST(CAST(s.backup_size / 1000000 AS INT) AS VARCHAR(14)) + ' ' +'MB' AS bkSize
,CAST(DATEDIFF(second, s.backup_start_date, s.backup_finish_date) AS VARCHAR(4)) + ' ' + 'Seconds' TimeTaken,s.backup_start_date
,CAST(s.first_lsn AS VARCHAR(50)) AS first_lsn
,CAST(s.last_lsn AS VARCHAR(50)) AS last_lsn
,CAST(s.database_backup_lsn AS VARCHAR(50)) AS database_backup_lsn
,CAST(s.checkpoint_lsn AS VARCHAR(50)) AS checkpoint_lsn
,CASE s.[type] WHEN 'D' THEN 'Full' WHEN 'I' THEN 'Differential' WHEN 'L' THEN 'Transaction Log' END AS BackupType,is_copy_only
,s.server_name,s.recovery_model FROM msdb.dbo.backupset s with (nolock)
INNER JOIN msdb.dbo.backupmediafamily m with (nolock) ON s.media_set_id =m.media_set_id
WHERE s.database_name = @db_name and s.type= @backup_type ORDER BY backup_start_date DESC,backup_finish_date

END
GO
