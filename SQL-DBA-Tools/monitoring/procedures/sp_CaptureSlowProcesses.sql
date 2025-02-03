USE dbaWrench;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CaptureSlowProcesses
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MinDurationHours INT,
            @DatabaseFilter NVARCHAR(128)
    
    -- Get configuration
    SELECT TOP 1
        @MindurationHours = MinimumDurationHours,
        @DatabaseFilter = DatabaseName
    FROM dbo.ProcessMonitoringConfig
    WHERE IsActive = 1

    -- First, update status of queries that are no longer running
    UPDATE h
    SET
        EndTime = GETDATE(),
        Status = 'Completed'
    FROM dbo.SlowProcessHistory h
    WHERE h.Status = 'Running'
    AND NOT EXISTS (
        SELECT 1
        FROM sys.dm_exec_sessions s
        INNER JOIN sys.dm_exec_requets r ON s.session_id = r.session_id
        WHERE s.session_id = h.SessionID
        AND r.start_time = h.StartTime 
    );

    -- Then capture new slow running queries
    INSERT INTO dbo.SlowProcessHistory (
        CaptureTime, SessionID, RequestID, DatabaseName, LoginName,
        HostName, ProgramName, CommandText, StartTime, TotalElapsedMinutes,
        CPUTimeMS, LogicalReads, PhysicalReads, MemoryUsageKB,
        BlockingSessionID, WaitType, QueryPlan, TuningRecommendations,
        Status
    )
    SELECT
        GETDATE() AS CaptureTime,
        s.session_id AS SessionID,
        r.request_id AS RequestID,
        DB_NAME(r.database_id) AS DatabaseName,
        s.login_name AS LoginName,
        s.host_name AS HostName,
        s.program_name AS ProgramName,
        t.text AS CommandText,
        r.start_time AS StartTime,
        DATEDIFF(MINUTE, r.start_time, GETDATE()) AS TotalElapsedMinutes,
        r.cpu_time AS CPUTimeMS,
        r.logical_reads AS LogicalReads,
        r.reads AS PhysicalReads,
        r.granted_query_memory * 8 AS MemoryUsageKB,
        r.blocking_session_id AS BlockingSessionID,
        r.wait_type AS WaitType,
        qp.query_plan AS QueryPlan,
        CASE
            WHEN qp.query_plan.exist('//MissingIndex') = 1 THEN 'Missing Index Detected'
            WHEN r.logical_reads / NULLIF(r.writes, 0) > 1000 THEN 'High reads to writes ratio'
            WHEN r.granted_query_memory > 1024 THEN 'High memory grant'
            ELSE 'Review query plan for optimization opportunities'
        END AS TuningRecommendations,
        'Running' AS Status
    FROM sys.dm_exec_sessions s
    INNER JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
    CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
    CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) qp
    WHERE
        DATEDIFF(HOUR, r.start_time, GETDATE()) >= @MinDurationHours
        AND s.is_user_process = 1
        AND (@DatabaseFilter IS NULL OR DB_NAME(r.database_id) = @DatabaseFilter)
        AND NOT EXISTS (
            SELECT 1
            FROM dbo.SlowProcessHistory h
            WHERE h.SessionID = s.session_id
                AND h.StartTime = r.start_time
                AND h.Status = 'Running'
        );
END

