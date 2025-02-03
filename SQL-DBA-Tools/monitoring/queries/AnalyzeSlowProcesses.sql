USE dbaWrench;
GO

-- Get recent slow running processes with recommendations
SELECT
    DatabaseName,
    LoginName,
    TotalElapsedMinutes,
    CPUTimeMS / 1000.0 as CPUTimeSeconds,
    LogicalReads,
    PhysicalReads,
    MemoryUsagekB / 1024.0 as MemoryUsageMB,
    TuningRecommendations,
    CommandText,
    QueryPlan
FROM dbo.SlowProcessHistory
WHERE CaptureTime >= DATEADD(day, -1, GETDATE())
ORDER BY TotalElapsedMinutes DESC;

-- Get summary by database
SELECT
    DatabaseName,
    COUNT(*) as SlowQueryCount,
    AVG(TotalElapsedMinutes) as AvgDurationMinutes,
    MAX(TotalElapsedMinutes) as MaxDurationMinutes,
    AVG(CPUTimeMS) / 1000.0 as AvgCPUTimeSeconds,
    AVG(MemoryUsagekB / 1024.0) as AvgMemoryUsageMB
FROM dbo.SlowProcessHistory
GROUP BY DatabaseName
ORDER BY SlowQueryCount DESC;

-- Add this query to see completed vs running queries
SELECT
    Status,
    DatabaseName,
    LoginName,
    StartTime,
    EndTime,
    CASE
        WHEN EndTime IS NOT NULL THEN
            DATEDIFF(MINUTE, StartTime, EndTime)
        ELSE
            DATEDIFF(MINUTE, StartTime, GETDATE())
    END as DurationMinutes,
    CPUTimeMS / 1000.0 as CPUTimeSeconds,
    MemoryUsagekB / 1024.0 as MemoryUsageMB,
    CommandText
FROM dbo.SlowProcessHistory
WHERE CaptureTime >= DATEADD(day, -1, GETDATE())
ORDER BY StartTime DESC;

-- Add statistics about query completion times
SELECT
    DatabaseName,
    COUNT(*) as TotalQueries,
    COUNT(CASE WHEN Status = 'Completed' THEN 1 END) as CompletedQueries,
    COUNT(CASE WHEN Status = 'Running' THEN 1 END) as StillRunning,
    AVG(CASE
        WHEN Status = 'Completed'
        THEN DATEDIFF(MINUTE, StartTime, EndTime)
    END) as AvgCompletionTimeMinutes,
    MAX(CASE
        WHEN Status = 'Completed'
        THEN DATEDIFF(MINUTE, StartTime, EndTime)
    END) as MaxCompletionTimeMinutes
FROM dbo.SlowProcessHistory
GROUP BY DatabaseName
ORDER BY TotalQueries DESC;