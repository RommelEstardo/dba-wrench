USE dbaWrench;
GO

-- Configuration table for maintenance tasks
CREATE TABLE dbo.MaintenanceConfig (
    ConfigID INT IDENTITY(1,1) PRIMARY KEY,
    TaskName VARCHAR(100),
    DatabaseName NVARCHAR(128) NULL, -- NULL means all databases
    IsActive BIT DEFAULT 1,
    RetentionDays INT,
    MaximumFileSize INT, -- In MB
    ThresholdPercent INT, -- For index fragmentation
    LastModified DATETIME DEFAULT GETDATE()
)

-- Insert default configurations
INSERT INTO dbo.MaintenanceConfig (TaskName, DatabaseName, RetentionDays, MaximumFileSize, ThresholdPercent)
VALUES
('Backup Full', NULL, 30, NULL, NULL),
('Backup Log', NULL, 7, NULL, NULL),
('Index Maintenance', NULL, NULL, NULL, 30),
('Statistics Update', NULL, NULL, NULL, NULL),
('DBCC CheckDB', NULL, NULL, NULL, NULL),
('File Growth Monitor', NULL, NULL, 1024, 85), -- Alert when file size > 1GB and used space > 85%
('Purge History', NULL, 90, NULL, NULL);

-- Add Maintenance History table
CREATE TABLE dbo.MaintenanceHistory (
    HistoryID BIGINT IDENTITY(1,1) PRIMARY KEY,
    TaskName VARCHAR(100),
    DatabaseName NVARCHAR(128),
    StartTime DATETIME DEFAULT GETDATE(),
    EndTime DATETIME NULL,
    Duration AS DATEDIFF(SECOND, StartTime, EndTime),
    Status VARCHAR(20), -- 'Success', 'Failed', 'In Progress'
    ErrorMessage NVARCHAR(MAX),
    RowsAffected BIGINT,
    AdditionalInfo XML
)
GO

-- Add index on common search columns
CREATE NONCLUSTERED INDEX IX_MaintenanceHistory_Task
ON dbo.MaintenanceHistory(TaskName, DatabaseName, StartTime)
INCLUDE (Status, Duration)
GO
