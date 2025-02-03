USE dbaWrench;
GO

CREATE OR ALTER PROCEDURE dbo.sp_BackupMaintenance
    @BackupType VARCHAR(10), -- 'FULL' or 'LOG'
    @DatabaseName NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @HistoryID BIGINT,
            @ErrorMessage NVARCHAR(MAX),
            @AdditionalInfo XML;
    
    -- Start logging
    EXEC dbo.sp_LogMaintenanceTask
        @TaskName = 'Backup ' + @BackupType,
        @DatabaseName = @DatabaseName,
        @HistoryID = @HistoryID OUTPUT;

    BEGIN TRY
        DECLARE @cmd NVARCHAR(MAX),
                @backupPath NVARCHAR(256),
                @timestamp VARCHAR(50);

        SET @backupPath = N'\\BackupServer\SQLBackups\'
        SET @timestamp = REPLACE(CONVERT(VARCHAR, GETDATE(), 120), ':', '')

        IF @BackupType = 'FULL'
        BEGIN
            SET @cmd = N'BACKUP DATABASE [' + @DatabaseName + ']
                TO DISK = ''' + @backupPath + @DatabaseName + '_' + @timestamp + '.bak''
                WITH COMPRESSION, CHECKSUM, INIT'
        END
        ELSE
        BEGIN
            SET @cmd = N'BACKUP LOG [' + @DatabaseName + ']
                TO DISK = ''' + @backupPath + @DatabaseName + '_' + @timestamp + '.trn''
                WITH COMPRESSION, CHECKSUM'
        END

        EXEC sp_executesql @cmd

        -- Log success
        SET @AdditionalInfo = (
            SELECT
                @backupPath AS BackupPath,
                @timestamp AS BackupTime
            FOR XML PATH('BackupInfo')
        )

        EXEC dbo.sp_LogMaintenanceTask
            @TaskName = 'Backup ' + @BackupType,
            @DatabaseName = @DatabaseName,
            @HistoryID = @HistoryID,
            @AdditionalInfo = @AdditionalInfo
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE()

        -- Log error
        EXEC dbo.sp_LogMaintenanceTask
            @TaskName = 'Backup ' + @BackupType,
            @DatabaseName = @DatabaseName,
            @HistoryID = @HistoryID,
            @ErrorMessage = @ErrorMessage

        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_IndexMaintenance
    @DatabaseName NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @fragThreshold INT;

    SELECT @fragThreshold = ThresholdPercent
    FROM dbo.MaintenanceConfig
    WHERE TaskName = 'Index Maintenance'

    -- Index maintenance logic
    DECLARE @sql NVARCHAR(MAX) = N'
    SELECT
        db_name() as DatabaseName,
        OBJECT_SCHEMA_NAME(i.object_id) as SchemaName,
        OBJECT_NAME(i.object_id) as TableName,
        i.name as IndexName,
        ips.avg_fragmentation_in_percent
    FROM sys.dm_db_index_physical_stats(db_id(), NULL, NULL, NULL, ''LIMITED'') ips
    JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
    WHERE ips.avg_fragmentation_in_percent > ' + CAST(@fragThreshold AS VARCHAR(3))
    
    -- Execute for specified database or all user databases
    IF @DatabaseName IS NOT NULL
        SET @sql = 'USE [' + @DatabaseName + ']; ' + @sql

    EXEC sp_executesql @sql
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_StatisticsMaintenance
    @DatabaseName NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX) = N'
    UPDATE STATISTICS [' + @DatabaseName + '] WITH FULLSCAN'

    IF @DatabaseName IS NOT NULL
        EXEC sp_executesql @sql
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_IntegrityCheck
    @DatabaseName NVARCHAR(128) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX) = N'
    DBCC CHECKDB ([' + @DatabaseName + ']) WITH NO_INFOMSGS'

    IF @DatabaseName IS NOT NULL
        EXEC sp_executesql @sql
END

-- Add logging wrapper procedure
CREATE OR ALTER PROCEDURE dbo.sp_LogMaintenanceTask
    @TaskName VARCHAR(100),
    @DatabaseName NVARCHAR(128),
    @RowsAffected BIGINT = NULL,
    @ErrorMessage NVARCHAR(MAX) = NULL,
    @AdditionalInfo XML = NULL,
    @HistoryID BIGINT = NULL OUTPUT
AS
BEGIN
    IF @HistoryID IS NULL -- New task starting
    BEGIN
        INSERT INTO dbo.MaintenanceHistory
            (TaskName, DatabaseName, Status)
        VALUES
            (@TaskName, @DatabaseName, 'In Progress')

        SET @HistoryID = SCOPE_IDENTITY()
        RETURN @HistoryID
    END
    ELSE -- Task completing
    BEGIN
        UPDATE dbo.MaintenanceHistory
        SET
            EndTime = GETDATE(),
            Status = CASE WHEN @ErrorMessage IS NULL THEN 'Success' ELSE 'Failed' END,
            ErrorMessage = @ErrorMessage,
            RowsAffected = @RowsAffected,
            AdditionalInfo = @AdditionalInfo
        WHERE HistoryID = @HistoryID
    END
END
GO