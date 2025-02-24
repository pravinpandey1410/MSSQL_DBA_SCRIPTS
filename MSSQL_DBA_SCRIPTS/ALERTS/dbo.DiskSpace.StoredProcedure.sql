USE [master]
GO
/****** Object:  StoredProcedure [dbo].[DiskSpace]    Script Date: 2/6/2025 1:17:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[DiskSpace] as  SET NOCOUNT ON   DECLARE @hr int   DECLARE @fso int   DECLARE @drive char(1)   DECLARE @odrive int   DECLARE @TotalSize varchar(20)   DECLARE @MB bigint ; SET @MB = 1048576   CREATE TABLE #drives (ServerName varchar(
50),   drive char(1) PRIMARY KEY,   FreeSpace int NULL,   TotalSize int NULL,   FreespaceTimestamp DATETIME NULL)   INSERT #drives(drive,FreeSpace)   EXEC master.dbo.xp_fixeddrives   EXEC @hr=sp_OACreate 'Scripting.FileSystemObject',@fso OUT   IF @hr <> 0
 EXEC sp_OAGetErrorInfo @fso   DECLARE dcur CURSOR LOCAL FAST_FORWARD   FOR SELECT drive from #drives   ORDER by drive   OPEN dcur   FETCH NEXT FROM dcur INTO @drive   WHILE @@FETCH_STATUS=0   BEGIN   EXEC @hr = sp_OAMethod @fso,'GetDrive', @odrive OUT,
 @drive   IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso   EXEC @hr = sp_OAGetProperty @odrive,'TotalSize', @TotalSize OUT   IF @hr <> 0 EXEC sp_OAGetErrorInfo @odrive   UPDATE #drives   SET TotalSize=@TotalSize/@MB, ServerName = @@servername, FreespaceTimestamp =
 (GETDATE())   WHERE drive=@drive   FETCH NEXT FROM dcur INTO @drive   END   CLOSE dcur   DEALLOCATE dcur   EXEC @hr=sp_OADestroy @fso   IF @hr <> 0 EXEC sp_OAGetErrorInfo @fso   SELECT ServerName,   drive,   TotalSize as 'Total(MB)',   FreeSpace as 'Free(MB)',   CAST((FreeSpace/(TotalSize*1.0))*100.0 as int) as 'Free(%)',   FreespaceTimestamp   FROM #drives   ORDER BY drive   DROP TABLE #drives   RETURN   
GO
