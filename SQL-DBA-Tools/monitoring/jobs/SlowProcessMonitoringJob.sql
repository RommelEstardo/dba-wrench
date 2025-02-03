USE msdb;
GO

-- Create the job
EXEC dbo.sp_add_job
    @job_name = N'Monitor Slow Running Processes',
    @enabled = 1,
    @description = N'Captures and analyzes long-running queries';

-- Add the job step
EXEC dbo.sp_add_jobstep
    @job_name = N'Monitor Slow Running Processes',
    @step_name = N'Capture Slow Processes',
    @subsystem = N'TSQL',
    @command = N'USE dbaWrench; EXEC dbo.sp_CaptureSlowProcesses',
    @database_name = N'dbaWrench';

-- Create the schedule
EXEC dbo.sp_add_schedule
    @schedule_name = N'HourlyMonitoring',
    @freq_type = 4, -- Daily
    @freq_interval = 1,
    @freq_subday_type = 8, -- Hours
    @freq_subday_interval = 1; -- Every 1 hour

-- Attach the schedule to the job
EXEC sp_attach_schedule
    @job_name = N'Monitor Slow Running Processes',
    @schedule_name = N'HourlyMonitoring';