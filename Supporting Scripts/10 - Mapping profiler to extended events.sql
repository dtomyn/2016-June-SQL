/*
Overview:
SQL Profiler was introduced in SQL Server 7 back in 1998 and so is 18 years old!
Extended Events is the replacement for it. This sql is meant to be a starting point
to follow to migrate over traces to events
*/

/*
Compare profiler/trace event classes with XE event actions
*/
USE master;
GO

--NOTE: as per https://connect.microsoft.com/SQLServer/feedback/details/714947/sys-trace-xe-event-map-and-sys-trace-xe-action-map-intellisense
-- the table trace_xe_event_map does not (and will not) get intellisense

SELECT DISTINCT
	tb.trace_event_id AS [Trace Event ID],
	te.name AS [Trace Event Class],
	em.package_name AS [XE Package],
	em.xe_event_name AS [XE Event],
	tb.trace_column_id AS [Trace Column ID],
	tc.name AS [Trace Column],
	am.xe_action_name aS [XE Action]
FROM sys.trace_events te
LEFT JOIN sys.trace_xe_event_map em 
	ON te.trace_event_id = em.trace_event_id
LEFT JOIN sys.trace_event_bindings tb
	ON em.trace_event_id = tb.trace_event_id
LEFT JOIN sys.trace_columns tc
	ON tb.trace_column_id = tc.trace_column_id
LEFT JOIN sys.trace_xe_action_map am
	ON tc.trace_column_id = am.trace_column_id
ORDER BY
	te.name,
	tc.name;
	--tb.trace_event_id;

--OR

/*
1. Execute the existing script to create a SQL Trace session
and then obtain the ID of the trace
2. Run a query that uses the fn_trace_geteventinfo function to
find the equivalent Extended Events events and actions for each 
SQL Trace event class and its associated columns
3. Use the fn_trace_getfilterinfo function to list the filters
and the equivalent Extended Events actions to use
4. Manually create an Extended Events session, using the equivalent
Extended Events events, actions and predicates (filters)
*/