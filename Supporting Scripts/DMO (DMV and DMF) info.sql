/*
Overview:
Shows some DMO info...
*/
/*
To get a full list of Dynamic Management Objects* (DMOs) run the below...
NOTE: 
- SQL Server 2005: 89
- SQL Server 2008: 136
- SQL Server 2012: 177
- SQL Server 2014: 201
- SQL Server 2016: ??

*NOTE: usually because of potential confusion with "Distributed Management Objects"
	these are referred to as just "DMVs"
*/
SELECT 
	[name],
	CASE [type]	
		WHEN 'V' THEN 'DMV'
		WHEN 'IF' THEN 'DMF'
	END AS [DMO Type]
FROM master.sys.sysobjects so
WHERE 
	so.[name] LIKE 'dm[_]%'
ORDER BY
	so.[name];

/*
To grant user rights to query need
- server scoped objects (most) : "VIEW SERVER STATE"
- database scoped objects : "VIEW DATABASE STATE"
*/
use [master]
GO
GRANT VIEW SERVER STATE TO [SOLVERA\darekt]
GO

/*
DMOs related to what is executing right now are all
dm_exec_...

For a "de facto standard" for "who is active" use script found here:
http://sqlblog.com/files/folders/beta/entry42453.aspx

...a very simplistic version of this is next...
*/
SELECT
	dec.client_net_address,
	des.host_name,
	dest.text
FROM sys.dm_exec_sessions des --NOTE: sys.dm_exec_sessions usually is the basis for any "who" questions
JOIN sys.dm_exec_connections dec
	ON dec.session_id = des.session_id
CROSS APPLY sys.dm_exec_sql_text(dec.most_recent_sql_handle) dest
WHERE
	des.program_name LIKE 'Microsoft SQL Server Management Studio%'
ORDER BY
	des.program_name
	, dec.client_net_address;

SELECT 
	dest.text,
	dest.dbid,
	dest.objectid
FROM sys.dm_exec_requests der --currently executing requests
CROSS APPLY sys.dm_exec_sql_text(der.sql_handle) AS dest
WHERE
	session_id = 60;

EXEC sp_who_is_active
