USE [master]
GO
/****** Object:  StoredProcedure [dbo].[usp_DiskFreeSpaceAlert]    Script Date: 2/6/2025 1:17:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


    
    
    
  CREATE PROCEDURE [dbo].[usp_DiskFreeSpaceAlert]      
@DriveCBenchmark int = 10240,      
 @OtherDataDriveBenchmark int = 10240      
AS      
      
begin      
Declare @ipLine varchar(200)      
Declare @pos int      
declare @ip varchar(40)      
--declare @param1 varchar(40)      
--declare @param2 varchar(40)      
set nocount on      
          set @ip = NULL      
          --set @param1='%IPv4 ADDRESS%'      
          --set @param2='%Autoconfiguration%'      
          Create table #temp (ipLine varchar(200))      
          Insert #temp exec master..xp_cmdshell 'ipconfig'      
          --select @ipLine = ipLine      
          --from #temp      
          --where upper (ipLine) like '%IPv4 ADDRESS%'      
                
          select @ipLine =ipLine      
          from #temp      
          where ipLine like '%IPv4 ADDRESS%' and ipLine not like '%Autoconfiguration%'      
          if (isnull (@ipLine,'***') != '***')      
          begin       
                set @pos = CharIndex (':',@ipLine,1);      
                set @ip = rtrim(ltrim(substring (@ipLine ,@pos + 1 ,len (@ipLine) - @pos)))      
           end       
drop table #temp      
set nocount off      
--print @ip      
end      
      
--------------------------------------------------------------------------------------------------      
--By: Haidong "Alex" Ji  This procedure sends out an alert message when hard disk space is below a predefined value. This procedure can be scheduled to run daily so that DBA can act quickly to address this issue.      
IF EXISTS (SELECT * FROM tempdb..sysobjects      
WHERE id = object_id(N'[tempdb]..[#disk_free_space]'))      
DROP TABLE #disk_free_space      
CREATE TABLE #disk_free_space (      
 DriveLetter CHAR(1) NOT NULL,      
 FreeMB INTEGER NOT NULL)      
      
DECLARE @DiskFreeSpace INT      
DECLARE @DriveLetter CHAR(1)      
DECLARE @AlertMessage VARCHAR(500)      
DECLARE @MailSubject VARCHAR(100)      
--declare @query nvarchar(max)      
--declare @ip varchar(40)      
      
--SET @query=N'sp_get_ip_address'      
/* Populate #disk_free_space with data */      
INSERT INTO #disk_free_space      
 EXEC master..xp_fixeddrives      
      
SELECT @DiskFreeSpace = FreeMB FROM #disk_free_space where DriveLetter = 'C'      
      
IF @DiskFreeSpace < @DriveCBenchmark      
Begin      
      
--exec sp_executesql @query,@ip=@ip OUTPUT;      
SET @MailSubject = 'WARNING : Drive C free space is low on POSIDEX (10.11.32.17) ' + @ip      
SET @AlertMessage = 'Drive C on (HFCLMS)' + @@SERVERNAME + ' has only ' +  CAST(@DiskFreeSpace AS VARCHAR) + ' MB left. Please free up space on this drive. C drive usually has OS installed on it. Lower space on C could slow down performance of the server'      
-- Send out email      
      
EXEC msdb.dbo.sp_send_dbmail      
    @profile_name = 'mail notification',      
    @recipients='cloversqlconnect@cloverinfotech.com',      
--@copy_recipients='saravanakumark@chola.murugappa.com',     
   @subject = @MailSubject,      
@body = @AlertMessage;      
      
end      
--EXEC master..xp_sendmail @recipients = 'dba.sharedservices@birlasunlife.com',      
--@subject = @MailSubject,      
--@message = @AlertMessage      
      
      
DECLARE DriveSpace CURSOR FAST_FORWARD FOR      
select DriveLetter, FreeMB from #disk_free_space where DriveLetter not in ('C')      
      
open DriveSpace      
fetch next from DriveSpace into @DriveLetter, @DiskFreeSpace      
      
WHILE (@@FETCH_STATUS = 0)      
Begin      
if @DiskFreeSpace < @OtherDataDriveBenchmark      
Begin      
set @MailSubject = 'Warning :Drive ' + @DriveLetter + ' free space is low on POSIDEX (10.11.32.17)' + @ip      
set @AlertMessage = @DriveLetter + ' has only ' + cast(@DiskFreeSpace as varchar) + ' MB left. Please increase free space for this drive immediately to avoid production issues'      
      
-- Send out email      
      
EXEC msdb.dbo.sp_send_dbmail      
    @profile_name = 'mail notification',      
    @recipients='cloversqlconnect@cloverinfotech.com',      
--@copy_recipients='saravanakumark@chola.murugappa.com',     
   @subject = @MailSubject,      
@body = @AlertMessage;      
--EXEC master..xp_sendmail @recipients = 'dba.sharedservices@birlasunlife.com',      
--@subject = @MailSubject,      
--@message = @AlertMessage      
End      
fetch next from DriveSpace into @DriveLetter, @DiskFreeSpace      
End      
close DriveSpace
      
deallocate DriveSpace      
      
DROP TABLE #disk_free_space      
      
GO
