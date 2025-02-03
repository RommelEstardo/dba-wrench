USE msdb;
GO

-- Full Backup Job (Daily)
EXEC dbo.sp_add_job @job_name = N'Database Full Backup',
    @enabled = 1,
    @description = N'Daily full backup of all databases';

EXEC dbo.sp_add_jobstep @job_name = N'Database Full Backup',
    @step_name = N'Execute Full Backup',
    @subsystem = N'TSQL',
    @command = N'EXEC dbaWrench.dbo.sp_BackupMaintenance @BackupType = ''FULL''',
    @database_name = N'dbaWrench';

-- Log Backup Job (Every 15 minutes)
EXEC dbo.sp_add_job @job_name = N'Database Log Backup',
    @enabled = 1,
    @description = N'Transaction log backup every 15 minutes';

EXEC dbo.sp_add_jobstep @job_name = N'Database Log Backup',
    @step_name = N'Execute Log Backup',
    @subsystem = N'TSQL',
    @command = N'EXEC dbaWrench.dbo.sp_BackupMaintenance @BackupType = ''LOG''',
    @database_name = N'dbaWrench';

-- Index Maintenance Job (Weekly)
EXEC dbo.sp_add_job @job_name = N'Index Maintenance',
    @enabled = 1,
    @description = N'Weekly index reorganize/rebuild';

EXEC dbo.sp_add_jobstep @job_name = N'Index Maintenance',
    @step_name = N'Execute Index Maintenance',
    @subsystem = N'TSQL',
    @command = N'EXEC dbaWrench.dbo.sp_IndexMaintenance',
    @database_name = N'dbaWrench';

-- Statistics Update Job(Weekly)
EXEC dbo.sp_add_job @job_name = N'Statistics Update',
    @enabled = 1,
    @description = N'Weekly statistics update';

-- Add schedules for each job
-- Daily Full Backup (1 AM)
EXEC dbo.sp_add_schedule @schedule_name = N'DailyFullBackup',
    @freq_type = 4,
    @freq_interval = 1,
    @active_start_time = 010000;

-- Log Backup (Every 15 minutes)
EXEC dbo.sp_add_schedule @schedule_name = N'LogBackup15Min',
    @freq_type = 4,
    @freq_interval = 1,
    @freq_subday_type = 4,
    @freq_subday_interval = 15;

-- Weekly Index Maintenance (Sunday 2 AM)
EXEC dbo.sp_add_schedule @schedule_name = N'WeeklyIndexMaint',
    @freq_type = 8,
    @freq_interval = 1,
    @active_start_time = 020000;

-- Attach schedules to jobs
EXEC sp_attach_schedule @job_name = N'Database Full Backup',
    @schedule_name = N'DailyFullBackup';

EXEC sp_attach_schedule @job_name = N'Database Log Backup',
    @schedule_name = N'LogBackup15Min';

EXEC sp_attach_schedule @job_name = N'Index Maintenance',
    @schedule_name = N'WeeklyIndexMaint';