-- Create the database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'dbaWrench')
BEGIN
    CREATE DATABASE dbaWrench;
END
GO

USE dbaWrench;
GO

-- Parameters table
CREATE TABLE dbo.ProcessMonitoringConfig (
    ConfigID INT IDENTITY(1,1) PRIMARY KEY,
    MinimumDurationHours INT DEFAULT 2,
    DatabaseName NVARCHAR(128) NULL, -- NULL means monitor all databases
    IsActive BIT DEFAULT 1,
    LastModified DATETIME DEFAULT GETDATE()
)

-- Monitoring results table
CREATE TABLE dbo.SlowProcessHistory (
    HistoryID BIGINT IDENTITY(1, 1) PRIMARY KEY,
    CaptureTime DATETIME,
    SessionID INT,
    RequestID INT,
    DatabaseName NVARCHAR(128),
    LoginName NVARCHAR(128),
    HostName NVARCHAR(128),
    ProgramName NVARCHAR(128),
    CommandText NVARCHAR(MAX),
    StartTime DATETIME,
    TotalElapsedMinutes INT,
    CPUTimeMS BIGINT,
    LogicalReads BIGINT,
    PhysicalReads BIGINT,
    MemoryUsageKB BIGINT,
    BlockingSessionID INT,
    WaitType NVARCHAR(60),
    QueryPlan XML,
    TuningRecommendations NVARCHAR(MAX),
    EndTime DATETIME NULL,
    Status VARCHAR(20) DEFAULT 'Running'
)

-- Insert default configuration
INSERT INTO dbo.ProcessMonitoringConfig (MinimumDurationHours, DatabaseName)
VALUES (2, NULL) -- Monitor all databases for queries running > 2 hours
GO