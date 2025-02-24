USE [master]
GO
/****** Object:  StoredProcedure [dbo].[Alerts_Blocking]    Script Date: 2/6/2025 1:17:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

  
  
  
  
  
  
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------  


--select * from msdb..sysmail_profile      
CREATE procedure [dbo].[Alerts_Blocking]      
as      
--SET NOCOUNT       
--ON      
declare @ts_now bigint   
if (select COUNT(1) from sys.sysprocesses where datediff(mm,login_time,GETDATE())>3 and blocked<>0 and spid<>blocked)>=5       
begin  
print 'CPU Alert Condition True, Sending Email..'DECLARE @tableHTML  NVARCHAR(MAX) ;      
SET @tableHTML =          
N'<H1 bgcolor="magenta">Blocking Found</H1>' +          
N'<H2 bgcolor="magenta">SQL Server Session Details</H2>' +         
 N'<table border="1">' +        
   N'<tr bgcolor="magenta"><th>session_id</th><th>Status</th><th>login_name</th><th>host_name</th><th>blocking_session_id</th>'+      
   N'<th>DatabaseID</th><th>command</th><th>SQLStatement</th><th>ElapsedMS</th>'+      
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
     WHERE er.session_id <> 0        
     ORDER BY er.cpu_time DESC , er.blocking_session_id      
     FOR XML PATH('tr'), TYPE )AS NVARCHAR(MAX))+N'</table>'       
     -- Change SQL Server Email notification code here      
     EXEC msdb.dbo.sp_send_dbmail       
     @recipients='cloversqlconnect@cloverinfotech.com;
Cloversqldb@chola1.murugappa.com
',    
     --@copy_recipients='saravanakumark@chola.murugappa.com;avinashn@chola.murugappa.com;muthuvels@chola.murugappa.com',       
     @profile_name = 'Posidex',          
     @subject = 'CHOLA 10.11.32.17 (POSIDEX PROD)Blocking Found',      
     @body = @tableHTML,@body_format = 'HTML';      
     END      
     -- Drop the Temporary Table      
     --DROP Table #tempCPURecords      
  
  
  
  
  
  
  
  
  

GO
