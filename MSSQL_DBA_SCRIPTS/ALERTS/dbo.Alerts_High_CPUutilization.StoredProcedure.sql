USE [master]
GO
/****** Object:  StoredProcedure [dbo].[Alerts_High_CPUutilization]    Script Date: 2/6/2025 1:17:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--select * from msdb..sysmail_profile      
CREATE procedure [dbo].[Alerts_High_CPUutilization]      
as      
--SET NOCOUNT       
--ON      
declare @ts_now bigint select @ts_now = cpu_ticks / (cpu_ticks/ms_ticks) from sys.dm_os_sys_info      
-- Collect Data from DMV      
select record_id, dateadd(ms, -1 * (@ts_now - [timestamp]), GetDate()) as EventTime,       
SQLProcessUtilization,SystemIdle,100 - SystemIdle - SQLProcessUtilization as OtherProcessUtilization       
into #tempCPURecords       
from ( select record.value('(./Record/@id)[1]', 'int') as record_id,       
 record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') as SystemIdle,       
 record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') as SQLProcessUtilization,       
 timestamp       
 from ( select timestamp, convert(xml, record) as record       
 from sys.dm_os_ring_buffers       
 where ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'       
and record like '%<SystemHealth>%') as x       
 ) as y order by record_id desc       
-- To send detailed sql server session reports consuming high cpu      
-- For a dedicated SQL Server you can monitor 'SQLProcessUtilization'       
-- if (select avg(SQLSvcUtilization) from #temp where EventTime>dateadd(mm,-5,getdate()))>=80      
-- For a Shared SQL Server you can monitor 'SQLProcessUtilization'+'OtherOSProcessUtilization'      
if (select avg(SQLProcessUtilization+OtherProcessUtilization)       
from #tempCPURecords       
where EventTime>dateadd(mm,-5,getdate()))>=60      
begin  
print 'CPU Alert Condition True, Sending Email..'DECLARE @tableHTML  NVARCHAR(MAX) ;      
SET @tableHTML =          
N'<H1 bgcolor="magenta">High CPU Utilization Reported</H1>' +          
N'<H2 bgcolor="magenta">SQL Server Session Details</H2>' +         
 N'<table border="1">' +        
   N'<tr bgcolor="magenta"><th>SPID</th><th>Status</th><th>Login</th><th>Host</th><th>BlkBy</th>'+      
   N'<th>DatabaseID</th><th>CommandType</th><th>SQLStatement</th><th>ElapsedMS</th>'+      
   N'<th>CPUTime</th><th>IOReads</th><th>IOWrites</th><th>LastWaitType</th>'+      
   N'<th>StartTime</th><th>Protocol</th><th>ConnectionWrites</th>'+      
   N'<th>ConnectionReads</th><th>ClientAddress</th><th>Authentication</th></tr>'+      
   CAST ( ( SELECT  TOP 5 -- or all by using *      
   td= er.session_id,'',      
   td= ses.status,'',      
   td= ses.login_name,'',        
   td= ses.host_name,'',         
   td= er.blocking_session_id,'',        
   td= er.database_id,'',        
   td= er.command,'',        
   td= st.text,'',       
    td= er.total_elapsed_time,'',        
    td= er.cpu_time,'',        
    td= er.reads,'',        
    td= er.writes,'',        
    td= er.last_wait_type,'',        
    td= er.start_time,'',       
     td= con.net_transport,'',        
     td= con.num_writes,'',        
     td= con.num_reads,'',        
     td= con.client_net_address,'',        
     td= con.auth_scheme,''        
     FROM sys.dm_exec_requests er  OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) st        
     LEFT JOIN sys.dm_exec_sessions ses  ON ses.session_id = er.session_id        
     LEFT JOIN sys.dm_exec_connections con  ON con.session_id = ses.session_id        
     WHERE er.session_id > 50        
     ORDER BY er.cpu_time DESC ,      
     er.blocking_session_id      
     FOR XML PATH('tr'), TYPE )AS NVARCHAR(MAX))+N'</table>'       
     -- Change SQL Server Email notification code here      
     EXEC msdb.dbo.sp_send_dbmail       
     @recipients='mssql.cholasupport@cloverinfotech.com;cloversqldb@chola1.murugappa.com;cloversqldb@chola1.murugappa.com',  
     --@copy_recipients='saravanakumark@chola.murugappa.com;ramachandrank@chola.murugappa.com',       
     @profile_name = 'POSIDEX',          
     @subject = 'CHOLA 10.11.32.17(POSIDEX) :Last 5 Minutes Avg CPU Utilization Over 60%',      
     @body = @tableHTML,@body_format = 'HTML';      
     END      
     -- Drop the Temporary Table      
     --DROP Table #tempCPURecords      
           
    else if (select avg(SQLProcessUtilization+OtherProcessUtilization)       
from #tempCPURecords       
where EventTime>dateadd(mm,-5,getdate()))>=60      
begin  
--print 'CPU Alert Condition True, Sending Email..'DECLARE @tableHTML  NVARCHAR(MAX) ;      
SET @tableHTML =          
N'<H1 bgcolor="magenta">High CPU Utilization Reported</H1>' +          
N'<H2 bgcolor="magenta">SQL Server Session Details</H2>' +         
 N'<table border="1">' +        
   N'<tr bgcolor="magenta"><th>SPID</th><th>Status</th><th>Login</th><th>Host</th><th>BlkBy</th>'+      
   N'<th>DatabaseID</th><th>CommandType</th><th>SQLStatement</th><th>ElapsedMS</th>'+      
   N'<th>CPUTime</th><th>IOReads</th><th>IOWrites</th><th>LastWaitType</th>'+      
   N'<th>StartTime</th><th>Protocol</th><th>ConnectionWrites</th>'+      
   N'<th>ConnectionReads</th><th>ClientAddress</th><th>Authentication</th></tr>'+      
   CAST ( ( SELECT  TOP 5 -- or all by using *      
   td= er.session_id,'',      
   td= ses.status,'',      
   td= ses.login_name,'',        
   td= ses.host_name,'',         
   td= er.blocking_session_id,'',        
   td= er.database_id,'',        
   td= er.command,'',        
   td= st.text,'',       
    td= er.total_elapsed_time,'',        
    td= er.cpu_time,'',        
    td= er.reads,'',        
    td= er.writes,'',        
    td= er.last_wait_type,'',        
    td= er.start_time,'',       
     td= con.net_transport,'',        
     td= con.num_writes,'',        
     td= con.num_reads,'',        
     td= con.client_net_address,'',        
     td= con.auth_scheme,''        
     FROM sys.dm_exec_requests er  OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) st        
     LEFT JOIN sys.dm_exec_sessions ses  ON ses.session_id = er.session_id        
     LEFT JOIN sys.dm_exec_connections con  ON con.session_id = ses.session_id        
     WHERE er.session_id > 50        
     ORDER BY er.cpu_time DESC ,      
     er.blocking_session_id      
     FOR XML PATH('tr'), TYPE )AS NVARCHAR(MAX))+N'</table>'       
     -- Change SQL Server Email notification code here      
     EXEC msdb.dbo.sp_send_dbmail       
     @recipients='cloversqlconnect@cloverinfotech.com',  
     --@copy_recipients='saravanakumark@chola.murugappa.com;ramachandrank@chola.murugappa.com',  
     --@recipients='',      
     @profile_name = 'Posidex',          
     @subject = 'CHOLA 10.11.32.17(POSIDEX) :Last 5 Minutes Avg CPU Utilization Over 60%',      
     @body = @tableHTML,@body_format = 'HTML';      
     End  
         
      


	 






GO
