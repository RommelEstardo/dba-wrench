# dba-wrench
SQL Server monitoring and maintenance toolkit

# DBA Wrench

A SQL Server Database Administration toolkit providing comprehensive monitoring and maintenance solutions for database administrators.

## Repository Structure

```
dba-wrench/
├── maintenance/
│   ├── jobs/         # SQL Agent job definitions
│   ├── procedures/   # Stored procedures
│   ├── queries/      # Analysis queries
│   └── tables/       # Table definitions
└── monitoring/
    ├── jobs/         # SQL Agent job definitions
    ├── procedures/   # Stored procedures
    ├── queries/      # Analysis queries
    └── tables/       # Table definitions
```

## Features

### Monitoring
- Long-running query tracking
- Process monitoring with configurable thresholds
- Performance metrics collection
- Resource usage analysis
- Query execution history

### Maintenance
- Automated database backups (Full and Log)
- Index maintenance routines
- Statistics updates
- Database integrity checks
- Maintenance history tracking

## Prerequisites

- SQL Server 2016 or later
- SQL Server Agent enabled
- Appropriate permissions for:
  - Creating databases
  - Creating and modifying jobs
  - Running DBCC commands
  - Performing backups
  - Creating and modifying objects

## Installation

1. Create the necessary tables by executing scripts in the `tables` folders
2. Deploy stored procedures from the `procedures` folders
3. Set up SQL Agent jobs using scripts in the `jobs` folders
4. Configure monitoring thresholds and maintenance settings

## Configuration

### Monitoring Settings
Configure in the ProcessMonitoringConfig table:
- Minimum duration for tracking queries
- Database scope
- Active monitoring status

### Maintenance Settings
Configure in the MaintenanceConfig table:
- Backup retention periods
- Index maintenance thresholds
- File growth monitoring settings
- Statistics update frequency

## Usage

### Monitoring
- View long-running queries and their resource usage
- Track blocking and wait statistics
- Analyze query performance patterns

### Maintenance
- Schedule and manage database backups
- Automate index maintenance
- Track maintenance task history
- Monitor task execution status

## Analysis Queries

The `queries` folders contain pre-built analysis scripts for:
- Query performance metrics
- Resource utilization
- Maintenance task history
- System health checks

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/YourFeature`)
3. Commit your changes (`git commit -m 'Add some feature'`)
4. Push to the branch (`git push origin feature/YourFeature`)
5. Open a Pull Request
