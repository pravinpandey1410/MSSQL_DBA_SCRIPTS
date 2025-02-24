USE [master]
GO
/****** Object:  StoredProcedure [dbo].[Alerts_Long_Runquery]    Script Date: 2/6/2025 1:17:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--Text
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------













--select * from msdb..sysmail_profile                
CREATE procedure [dbo].[Alerts_Long_Runquery]                
as               
DECLARE @tableHTML  NVARCHAR(MAX)   
if(  
SELECT  count(req.session_id)  
FROM sys.dm_exec_requests req        
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext        
where req.status in ('RUNNING','SUSPENDED','RUNNABLE') and req.command<>'BACKUP DATABASE'  
AND ((DATEPART(MINUTE,getdate())-(DATEPART(MINUTE,req.start_time))))>15)>=1
begin           
print 'CPU Alert Condition True, Sending Email..'               
SET @tableHTML =                    
N'<H1 bgcolor="green">Long Running Query</H1>' +                    
N'<H2 bgcolor="green">Query Details</H2>' +                   
 N'<table border="1">' +                  
   N'<tr bgcolor="green"><th>Query</th><th>Session_Id</th><th>Status</th><th>Command</th><th>Database</th><th>Start-Time</th>'+                
   CAST ((  
   SELECT         
  td=sqltext.TEXT,'',        
  td=req.session_id,'',        
  td=req.status,'',        
  td=req.command,'',        
  td=Db_name(req.database_ID),'',        
  td=req.start_time,''        
 FROM sys.dm_exec_requests req        
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext        
where ((DATEPART(MINUTE,getdate())-(DATEPART(MINUTE,req.start_time))))>1         
AND status in ('RUNNING','SUSPENDED','RUNNABLE')  and req.command<>'BACKUP DATABASE'       
     FOR XML PATH('tr'), TYPE )AS NVARCHAR(MAX))+N'</table>'                 
     -- Change SQL Server Email notification code here                
     EXEC msdb.dbo.sp_send_dbmail  
	   --@recipients='cloversqlconnect@cloverinfotech.com',          
      @recipients='cloversqlconnect@cloverinfotech.com;cloversqldb@chola1.murugappa.com;',
    --@copy_recipients='saravanakumark@chola.murugappa.com;avinashn@chola.murugappa.com;kalivarathank@chola.murugappa.com;',                 
     @profile_name = 'mail notification',                    
     @subject = 'CHOLA Query Running More than 5 Minutes on 10.11.32.17 (POSIDEX) server',               
     @body = @tableHTML,@body_format = 'HTML';                
     end





GO
