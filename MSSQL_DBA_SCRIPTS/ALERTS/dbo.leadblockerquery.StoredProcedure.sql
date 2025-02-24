USE [master]
GO
/****** Object:  StoredProcedure [dbo].[leadblockerquery]    Script Date: 2/6/2025 1:17:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create proc [dbo].[leadblockerquery] 
as
begin
if is_member('sysadmin')=0
begin
print 'Must be a member of the sysadmin group in order to run this procedure'
return
end

set nocount on

declare @spid varchar(6)
declare @blocked varchar(6)
declare @time datetime
declare @time2 datetime
declare @dbname nvarchar(128)
declare @status sql_variant
declare @useraccess sql_variant
declare @request varchar(12)
declare @latch int
declare @fast int
declare @appname sysname

set @latch = 1
set @fast = 1
set @appname ='SSMS'
set @time = getdate()
declare @probclients table(spid smallint, request_id int, ecid smallint, blocked smallint, waittype binary(2), dbid smallint,
ignore_app tinyint, primary key (blocked, spid, request_id, ecid))
insert @probclients select spid, request_id, ecid, blocked, waittype, dbid,
case when convert(varchar(128),hostname) = @appname then 1 else 0 end
from master.dbo.sysprocesses where blocked!=0 or waittype != 0x0000

if exists (select spid from @probclients where ignore_app != 1)
begin
set @time2 = getdate()

insert @probclients select distinct blocked, 0, 0, 0, 0x0000, 0, 0 from @probclients
where blocked not in (select spid from @probclients) and blocked != 0

if (@fast = 1)
begin 
select spid,dbid,loginame, program_name,hostname
from master.dbo.sysprocesses
where spid in (select distinct spid from @probclients where blocked = 0 and spid in (select blocked from @probclients where spid != 0))


if exists(select blocked from @probclients where blocked != 0)
begin 
if @latch = 0 and exists (select spid from @probclients where waittype between 0x0001 and 0x0017) -- Change: exists
begin
--print 'SYSLOCKINFO'
select @time2 = getdate()

select spid = convert (smallint, req_spid),
ecid = convert (smallint, req_ecid),
rsc_dbid As dbid,
rsc_objid As ObjId,
rsc_indid As IndId,
Type = case rsc_type when 1 then 'NUL'
when 2 then 'DB'
when 3 then 'FIL'
when 4 then 'IDX'
when 5 then 'TAB'
when 6 then 'PAG'
when 7 then 'KEY'
when 8 then 'EXT'
when 9 then 'RID'
when 10 then 'APP' end,
Resource = substring (rsc_text, 1, 16),
Mode = case req_mode + 1 when 1 then NULL
when 2 then 'Sch-S'
when 3 then 'Sch-M'
when 4 then 'S'
when 5 then 'U'
when 6 then 'X'
when 7 then 'IS'
when 8 then 'IU'
when 9 then 'IX'
when 10 then 'SIU'
when 11 then 'SIX'
when 12 then 'UIX'
when 13 then 'BU'
when 14 then 'RangeS-S'
when 15 then 'RangeS-U'
when 16 then 'RangeIn-Null'
when 17 then 'RangeIn-S'
when 18 then 'RangeIn-U'
when 19 then 'RangeIn-X'
when 20 then 'RangeX-S'
when 21 then 'RangeX-U'
when 22 then 'RangeX-X'end,
Status = case req_status when 1 then 'GRANT'
when 2 then 'CNVT'
when 3 then 'WAIT' end,
req_transactionID As TransID, req_transactionUOW As TransUOW
from master.dbo.syslockinfo s,
@probclients p
where p.spid = s.req_spid

end -- latch not set
end
else
print 'No blocking'
--print ''
end -- fast set

else 
begin -- Fast not set
--print ''
--print 'SYSPROCESSES ' + ISNULL (@@servername,'(null)') + ' ' + str(@@microsoftversion)

select spid, status, blocked, open_tran, waitresource, waittype,
waittime, cmd, lastwaittype, cpu, physical_io,
memusage, last_batch=convert(varchar(26), last_batch,121),
login_time=convert(varchar(26), login_time,121),net_address,
net_library, dbid, ecid, kpid, hostname, hostprocess,
loginame, program_name, nt_domain, nt_username, uid, sid,
sql_handle, stmt_start, stmt_end, request_id
from master.dbo.sysprocesses

--print 'ESP ' + convert(varchar(12), datediff(ms,@time2,getdate()))

print ''

if exists(select blocked from @probclients where blocked != 0)
begin
--print 'Blocking via locks at ' + convert(varchar(26), @time, 121)
print ''
--print 'SPIDs at the head of blocking chains'
select spid from @probclients
where blocked = 0 and spid in (select blocked from @probclients where spid != 0)
if @latch = 0
begin
--print 'SYSLOCKINFO'
select @time2 = getdate()

select spid = convert (smallint, req_spid),
ecid = convert (smallint, req_ecid),
rsc_dbid As dbid,
rsc_objid As ObjId,
rsc_indid As IndId,
Type = case rsc_type when 1 then 'NUL'
when 2 then 'DB'
when 3 then 'FIL'
when 4 then 'IDX'
when 5 then 'TAB'
when 6 then 'PAG'
when 7 then 'KEY'
when 8 then 'EXT'
when 9 then 'RID'
when 10 then 'APP' end,
Resource = substring (rsc_text, 1, 16),
Mode = case req_mode + 1 when 1 then NULL
when 2 then 'Sch-S'
when 3 then 'Sch-M'
when 4 then 'S'
when 5 then 'U'
when 6 then 'X'
when 7 then 'IS'
when 8 then 'IU'
when 9 then 'IX'
when 10 then 'SIU'
when 11 then 'SIX'
when 12 then 'UIX'
when 13 then 'BU'
when 14 then 'RangeS-S'
when 15 then 'RangeS-U'
when 16 then 'RangeIn-Null'
when 17 then 'RangeIn-S'
when 18 then 'RangeIn-U'
when 19 then 'RangeIn-X'
when 20 then 'RangeX-S'
when 21 then 'RangeX-U'
when 22 then 'RangeX-X'end,
Status = case req_status when 1 then 'GRANT'
when 2 then 'CNVT'
when 3 then 'WAIT' end,
req_transactionID As TransID, req_transactionUOW As TransUOW
from master.dbo.syslockinfo

--print 'ESL ' + convert(varchar(12), datediff(ms,@time2,getdate()))
end -- latch not set
end
else
print 'No blocking'
print ''
end -- Fast not set



declare ibuffer cursor fast_forward for
select distinct spid,request_id from @probclients -- change: added distinct
where blocked = 0 and spid in (select blocked from @probclients where spid != 0)
open ibuffer
fetch next from ibuffer into @spid, @request
while (@@fetch_status != -1)
begin
print ''
print 'SPID ' + @spid +'('+@request+')'
exec ('dbcc inputbuffer (' + @spid + ',' + @request +')' + 'with no_infomsgs')

fetch next from ibuffer into @spid, @request
end
deallocate ibuffer

end -- All
else
print '8 No Waittypes: ' + convert(varchar(26), @time, 121) + ' '
+ convert(varchar(12), datediff(ms,@time,getdate())) + ' ' + ISNULL (@@servername,'(null)') + ' 19.2005'
end
GO
