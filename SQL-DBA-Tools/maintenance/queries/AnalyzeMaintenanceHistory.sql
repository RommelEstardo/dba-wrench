USE dbaWrench;
GO

-- Get recent maintenace task execution status
SELECT
    TaskName,
    DatabaseName,
    StartTime,
    EndTime,
    Duration,
    Status,
    ErrorMessage,
    RowsAffected
FROM dbo.MaintenanceHistory
WHERE StartTime >= DATEADD(day, -7, GETDATE())
ORDER BY StartTime DESC;

-- Get average duration by task
SELECT
    TaskName,
    COUNT(*) as ExecutionCount,
    AVG(Duration) as AvgDurationSeconds,
    MAX(Duration) as MaxDurationSeconds,
    COUNT(CASE WHEN Status = 'Failed' THEN 1 END) as FailureCount
FROM dbo.MaintenanceHistory
WHERE StartTime >= DATEADD(month, -1, GETDATE())
    AND Status != 'In Progress'
GROUP BY TaskName
ORDER BY TaskName;

-- Get long-running tasks
SELECT
    TaskName,
    DatabaseName,
    StartTime,
    EndTime,
    Duration,
    Status,
    RowsAffected
FROM dbo.MaintenanceHistory
WHERE Duration > 3600 -- More than 1 hour
    AND StartTime >= DATEADD(month, -1, GETDATE())
ORDER BY Duration DESC;

-- Get failed tasks
SELECT
    TaskName,
    DatabaseName,
    StartTime,
    EndTime,
    ErrorMessage,
    AdditionalInfo
FROM dbo.MaintenanceHistory
WHERE Status = 'Failed'
    AND StartTime >= DATEADD(day, -7, GETDATE())
ORDER BY StartTime DESC;