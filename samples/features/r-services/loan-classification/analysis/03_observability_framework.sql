-- ============================================================================
-- LendingClub Database - Observability Framework
-- ============================================================================
-- This script implements comprehensive monitoring and alerting including:
-- - Query/Runtime tracking
-- - Expensive query identification
-- - SLA alerting mechanisms
-- - Performance monitoring dashboards
-- ============================================================================

USE [LendingClub]
GO

SET NOCOUNT ON;

PRINT '============================================================================';
PRINT 'LENDINGCLUB DATABASE - OBSERVABILITY FRAMEWORK';
PRINT 'Generated: ' + CONVERT(VARCHAR(30), GETDATE(), 120);
PRINT '============================================================================';
PRINT '';

-- ============================================================================
-- SECTION 1: ENHANCED MONITORING TABLES
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 1: CREATING ENHANCED MONITORING TABLES';
PRINT '----------------------------------------------------------------------------';

-- Create QueryPerformanceLog table for detailed query tracking
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'QueryPerformanceLog')
BEGIN
    CREATE TABLE [dbo].[QueryPerformanceLog](
        [log_id] [int] IDENTITY(1,1) PRIMARY KEY,
        [query_hash] [varbinary](8) NULL,
        [query_plan_hash] [varbinary](8) NULL,
        [query_text] [nvarchar](max) NULL,
        [execution_count] [bigint] NULL,
        [total_worker_time_ms] [bigint] NULL,
        [avg_worker_time_ms] [bigint] NULL,
        [total_elapsed_time_ms] [bigint] NULL,
        [avg_elapsed_time_ms] [bigint] NULL,
        [total_logical_reads] [bigint] NULL,
        [avg_logical_reads] [bigint] NULL,
        [total_physical_reads] [bigint] NULL,
        [total_logical_writes] [bigint] NULL,
        [last_execution_time] [datetime] NULL,
        [creation_time] [datetime] NULL,
        [captured_at] [datetime] DEFAULT GETDATE()
    );
    PRINT '   QueryPerformanceLog table created';
END
ELSE
    PRINT '   QueryPerformanceLog table already exists';

-- Create SLAThresholds table for configurable SLA definitions
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SLAThresholds')
BEGIN
    CREATE TABLE [dbo].[SLAThresholds](
        [threshold_id] [int] IDENTITY(1,1) PRIMARY KEY,
        [operation_name] [nvarchar](100) NOT NULL,
        [metric_name] [nvarchar](50) NOT NULL,
        [warning_threshold] [float] NOT NULL,
        [critical_threshold] [float] NOT NULL,
        [unit] [nvarchar](20) NOT NULL,
        [is_active] [bit] DEFAULT 1,
        [created_at] [datetime] DEFAULT GETDATE(),
        [updated_at] [datetime] DEFAULT GETDATE()
    );
    PRINT '   SLAThresholds table created';
    
    -- Insert default SLA thresholds
    INSERT INTO [dbo].[SLAThresholds] ([operation_name], [metric_name], [warning_threshold], [critical_threshold], [unit])
    VALUES 
        ('ScoreLoans', 'execution_time', 5000, 10000, 'milliseconds'),
        ('ScoreLoansWhatIf', 'execution_time', 8000, 15000, 'milliseconds'),
        ('PerformETL', 'execution_time', 60000, 120000, 'milliseconds'),
        ('DataLoad', 'execution_time', 900000, 1800000, 'milliseconds'),
        ('AnalyticsQuery', 'execution_time', 3000, 10000, 'milliseconds'),
        ('DataFreshness', 'hours_since_update', 24, 48, 'hours'),
        ('PredictionCoverage', 'percentage', 90, 80, 'percent'),
        ('DatabaseSize', 'size_gb', 15, 18, 'gigabytes');
    PRINT '   Default SLA thresholds inserted';
END
ELSE
    PRINT '   SLAThresholds table already exists';

-- Create SLAAlerts table for storing alert history
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SLAAlerts')
BEGIN
    CREATE TABLE [dbo].[SLAAlerts](
        [alert_id] [int] IDENTITY(1,1) PRIMARY KEY,
        [alert_time] [datetime] DEFAULT GETDATE(),
        [operation_name] [nvarchar](100) NOT NULL,
        [metric_name] [nvarchar](50) NOT NULL,
        [current_value] [float] NOT NULL,
        [threshold_value] [float] NOT NULL,
        [severity] [nvarchar](20) NOT NULL,
        [alert_message] [nvarchar](500) NOT NULL,
        [is_acknowledged] [bit] DEFAULT 0,
        [acknowledged_by] [nvarchar](100) NULL,
        [acknowledged_at] [datetime] NULL
    );
    PRINT '   SLAAlerts table created';
END
ELSE
    PRINT '   SLAAlerts table already exists';

-- Create DatabaseMetrics table for tracking database health
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DatabaseMetrics')
BEGIN
    CREATE TABLE [dbo].[DatabaseMetrics](
        [metric_id] [int] IDENTITY(1,1) PRIMARY KEY,
        [captured_at] [datetime] DEFAULT GETDATE(),
        [database_size_mb] [decimal](18,2) NULL,
        [log_size_mb] [decimal](18,2) NULL,
        [data_file_size_mb] [decimal](18,2) NULL,
        [total_connections] [int] NULL,
        [active_transactions] [int] NULL,
        [blocked_processes] [int] NULL,
        [cpu_usage_percent] [decimal](5,2) NULL,
        [memory_usage_mb] [decimal](18,2) NULL,
        [io_pending_count] [int] NULL
    );
    PRINT '   DatabaseMetrics table created';
END
ELSE
    PRINT '   DatabaseMetrics table already exists';

GO

-- ============================================================================
-- SECTION 2: STORED PROCEDURES FOR MONITORING
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 2: CREATING MONITORING STORED PROCEDURES';
PRINT '----------------------------------------------------------------------------';

-- Procedure to capture query performance statistics
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'CaptureQueryPerformance')
    DROP PROCEDURE [dbo].[CaptureQueryPerformance];
GO

CREATE PROCEDURE [dbo].[CaptureQueryPerformance]
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO [dbo].[QueryPerformanceLog] (
        [query_hash], [query_plan_hash], [query_text],
        [execution_count], [total_worker_time_ms], [avg_worker_time_ms],
        [total_elapsed_time_ms], [avg_elapsed_time_ms],
        [total_logical_reads], [avg_logical_reads],
        [total_physical_reads], [total_logical_writes],
        [last_execution_time], [creation_time]
    )
    SELECT TOP 50
        qs.query_hash,
        qs.query_plan_hash,
        SUBSTRING(st.text, (qs.statement_start_offset/2)+1,
            ((CASE qs.statement_end_offset
                WHEN -1 THEN DATALENGTH(st.text)
                ELSE qs.statement_end_offset
            END - qs.statement_start_offset)/2) + 1) AS query_text,
        qs.execution_count,
        qs.total_worker_time / 1000 AS total_worker_time_ms,
        (qs.total_worker_time / qs.execution_count) / 1000 AS avg_worker_time_ms,
        qs.total_elapsed_time / 1000 AS total_elapsed_time_ms,
        (qs.total_elapsed_time / qs.execution_count) / 1000 AS avg_elapsed_time_ms,
        qs.total_logical_reads,
        qs.total_logical_reads / qs.execution_count AS avg_logical_reads,
        qs.total_physical_reads,
        qs.total_logical_writes,
        qs.last_execution_time,
        qs.creation_time
    FROM sys.dm_exec_query_stats qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
    WHERE st.dbid = DB_ID()
    ORDER BY qs.total_elapsed_time DESC;
    
    PRINT 'Query performance captured: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' queries logged';
END
GO

PRINT '   CaptureQueryPerformance procedure created';

-- Procedure to capture database metrics
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'CaptureDatabaseMetrics')
    DROP PROCEDURE [dbo].[CaptureDatabaseMetrics];
GO

CREATE PROCEDURE [dbo].[CaptureDatabaseMetrics]
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DatabaseSizeMB DECIMAL(18,2);
    DECLARE @LogSizeMB DECIMAL(18,2);
    DECLARE @DataFileSizeMB DECIMAL(18,2);
    DECLARE @TotalConnections INT;
    DECLARE @ActiveTransactions INT;
    DECLARE @BlockedProcesses INT;
    
    -- Get database size
    SELECT 
        @DatabaseSizeMB = SUM(size * 8.0 / 1024),
        @DataFileSizeMB = SUM(CASE WHEN type = 0 THEN size * 8.0 / 1024 ELSE 0 END),
        @LogSizeMB = SUM(CASE WHEN type = 1 THEN size * 8.0 / 1024 ELSE 0 END)
    FROM sys.database_files;
    
    -- Get connection count
    SELECT @TotalConnections = COUNT(*)
    FROM sys.dm_exec_sessions
    WHERE database_id = DB_ID();
    
    -- Get active transactions
    SELECT @ActiveTransactions = COUNT(*)
    FROM sys.dm_tran_active_transactions;
    
    -- Get blocked processes
    SELECT @BlockedProcesses = COUNT(*)
    FROM sys.dm_exec_requests
    WHERE blocking_session_id > 0;
    
    INSERT INTO [dbo].[DatabaseMetrics] (
        [database_size_mb], [log_size_mb], [data_file_size_mb],
        [total_connections], [active_transactions], [blocked_processes]
    )
    VALUES (
        @DatabaseSizeMB, @LogSizeMB, @DataFileSizeMB,
        @TotalConnections, @ActiveTransactions, @BlockedProcesses
    );
    
    PRINT 'Database metrics captured successfully';
END
GO

PRINT '   CaptureDatabaseMetrics procedure created';

-- Procedure to check SLA compliance and generate alerts
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'CheckSLACompliance')
    DROP PROCEDURE [dbo].[CheckSLACompliance];
GO

CREATE PROCEDURE [dbo].[CheckSLACompliance]
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @AlertCount INT = 0;
    
    -- Check data freshness SLA
    DECLARE @HoursSinceLastUpdate FLOAT;
    SELECT @HoursSinceLastUpdate = DATEDIFF(HOUR, MAX(created_at), GETDATE())
    FROM [dbo].[LoanStats];
    
    IF @HoursSinceLastUpdate > (SELECT critical_threshold FROM [dbo].[SLAThresholds] WHERE operation_name = 'DataFreshness' AND is_active = 1)
    BEGIN
        INSERT INTO [dbo].[SLAAlerts] ([operation_name], [metric_name], [current_value], [threshold_value], [severity], [alert_message])
        VALUES ('DataFreshness', 'hours_since_update', @HoursSinceLastUpdate, 
                (SELECT critical_threshold FROM [dbo].[SLAThresholds] WHERE operation_name = 'DataFreshness'),
                'CRITICAL', 'Data freshness SLA breached - ' + CAST(@HoursSinceLastUpdate AS VARCHAR(10)) + ' hours since last update');
        SET @AlertCount = @AlertCount + 1;
    END
    ELSE IF @HoursSinceLastUpdate > (SELECT warning_threshold FROM [dbo].[SLAThresholds] WHERE operation_name = 'DataFreshness' AND is_active = 1)
    BEGIN
        INSERT INTO [dbo].[SLAAlerts] ([operation_name], [metric_name], [current_value], [threshold_value], [severity], [alert_message])
        VALUES ('DataFreshness', 'hours_since_update', @HoursSinceLastUpdate,
                (SELECT warning_threshold FROM [dbo].[SLAThresholds] WHERE operation_name = 'DataFreshness'),
                'WARNING', 'Data freshness approaching SLA threshold - ' + CAST(@HoursSinceLastUpdate AS VARCHAR(10)) + ' hours since last update');
        SET @AlertCount = @AlertCount + 1;
    END
    
    -- Check prediction coverage SLA
    DECLARE @PredictionCoverage FLOAT;
    SELECT @PredictionCoverage = 100.0 * COUNT(DISTINCT p.id) / COUNT(DISTINCT l.id)
    FROM [dbo].[LoanStats] l
    LEFT JOIN [dbo].[LoanStatsPredictions] p ON l.id = p.id;
    
    IF @PredictionCoverage < (SELECT critical_threshold FROM [dbo].[SLAThresholds] WHERE operation_name = 'PredictionCoverage' AND is_active = 1)
    BEGIN
        INSERT INTO [dbo].[SLAAlerts] ([operation_name], [metric_name], [current_value], [threshold_value], [severity], [alert_message])
        VALUES ('PredictionCoverage', 'percentage', @PredictionCoverage,
                (SELECT critical_threshold FROM [dbo].[SLAThresholds] WHERE operation_name = 'PredictionCoverage'),
                'CRITICAL', 'Prediction coverage below critical threshold - ' + CAST(CAST(@PredictionCoverage AS DECIMAL(5,2)) AS VARCHAR(10)) + '% coverage');
        SET @AlertCount = @AlertCount + 1;
    END
    ELSE IF @PredictionCoverage < (SELECT warning_threshold FROM [dbo].[SLAThresholds] WHERE operation_name = 'PredictionCoverage' AND is_active = 1)
    BEGIN
        INSERT INTO [dbo].[SLAAlerts] ([operation_name], [metric_name], [current_value], [threshold_value], [severity], [alert_message])
        VALUES ('PredictionCoverage', 'percentage', @PredictionCoverage,
                (SELECT warning_threshold FROM [dbo].[SLAThresholds] WHERE operation_name = 'PredictionCoverage'),
                'WARNING', 'Prediction coverage below warning threshold - ' + CAST(CAST(@PredictionCoverage AS DECIMAL(5,2)) AS VARCHAR(10)) + '% coverage');
        SET @AlertCount = @AlertCount + 1;
    END
    
    -- Check database size SLA
    DECLARE @DatabaseSizeGB FLOAT;
    SELECT @DatabaseSizeGB = SUM(size * 8.0 / 1024 / 1024)
    FROM sys.database_files;
    
    IF @DatabaseSizeGB > (SELECT critical_threshold FROM [dbo].[SLAThresholds] WHERE operation_name = 'DatabaseSize' AND is_active = 1)
    BEGIN
        INSERT INTO [dbo].[SLAAlerts] ([operation_name], [metric_name], [current_value], [threshold_value], [severity], [alert_message])
        VALUES ('DatabaseSize', 'size_gb', @DatabaseSizeGB,
                (SELECT critical_threshold FROM [dbo].[SLAThresholds] WHERE operation_name = 'DatabaseSize'),
                'CRITICAL', 'Database size exceeds critical threshold - ' + CAST(CAST(@DatabaseSizeGB AS DECIMAL(10,2)) AS VARCHAR(20)) + ' GB');
        SET @AlertCount = @AlertCount + 1;
    END
    ELSE IF @DatabaseSizeGB > (SELECT warning_threshold FROM [dbo].[SLAThresholds] WHERE operation_name = 'DatabaseSize' AND is_active = 1)
    BEGIN
        INSERT INTO [dbo].[SLAAlerts] ([operation_name], [metric_name], [current_value], [threshold_value], [severity], [alert_message])
        VALUES ('DatabaseSize', 'size_gb', @DatabaseSizeGB,
                (SELECT warning_threshold FROM [dbo].[SLAThresholds] WHERE operation_name = 'DatabaseSize'),
                'WARNING', 'Database size approaching threshold - ' + CAST(CAST(@DatabaseSizeGB AS DECIMAL(10,2)) AS VARCHAR(20)) + ' GB');
        SET @AlertCount = @AlertCount + 1;
    END
    
    -- Check for slow queries in recent runtime stats
    DECLARE @SlowQueryCount INT;
    SELECT @SlowQueryCount = COUNT(*)
    FROM [dbo].[RunTimeStats]
    WHERE Duration_ms > (SELECT critical_threshold FROM [dbo].[SLAThresholds] WHERE operation_name = 'AnalyticsQuery' AND is_active = 1)
      AND RunTime > DATEADD(HOUR, -1, GETDATE());
    
    IF @SlowQueryCount > 0
    BEGIN
        INSERT INTO [dbo].[SLAAlerts] ([operation_name], [metric_name], [current_value], [threshold_value], [severity], [alert_message])
        VALUES ('AnalyticsQuery', 'slow_query_count', @SlowQueryCount, 0,
                'WARNING', CAST(@SlowQueryCount AS VARCHAR(10)) + ' slow queries detected in the last hour');
        SET @AlertCount = @AlertCount + 1;
    END
    
    PRINT 'SLA compliance check completed. Alerts generated: ' + CAST(@AlertCount AS VARCHAR(10));
END
GO

PRINT '   CheckSLACompliance procedure created';

-- Procedure to get top expensive queries
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'GetTopExpensiveQueries')
    DROP PROCEDURE [dbo].[GetTopExpensiveQueries];
GO

CREATE PROCEDURE [dbo].[GetTopExpensiveQueries]
    @TopN INT = 10,
    @OrderBy VARCHAR(20) = 'elapsed_time'
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @OrderBy = 'cpu_time'
    BEGIN
        SELECT TOP (@TopN)
            qs.query_hash,
            SUBSTRING(st.text, (qs.statement_start_offset/2)+1,
                ((CASE qs.statement_end_offset
                    WHEN -1 THEN DATALENGTH(st.text)
                    ELSE qs.statement_end_offset
                END - qs.statement_start_offset)/2) + 1) AS query_text,
            qs.execution_count,
            qs.total_worker_time / 1000 AS total_cpu_time_ms,
            (qs.total_worker_time / qs.execution_count) / 1000 AS avg_cpu_time_ms,
            qs.total_elapsed_time / 1000 AS total_elapsed_time_ms,
            qs.total_logical_reads,
            qs.last_execution_time
        FROM sys.dm_exec_query_stats qs
        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
        WHERE st.dbid = DB_ID()
        ORDER BY qs.total_worker_time DESC;
    END
    ELSE IF @OrderBy = 'logical_reads'
    BEGIN
        SELECT TOP (@TopN)
            qs.query_hash,
            SUBSTRING(st.text, (qs.statement_start_offset/2)+1,
                ((CASE qs.statement_end_offset
                    WHEN -1 THEN DATALENGTH(st.text)
                    ELSE qs.statement_end_offset
                END - qs.statement_start_offset)/2) + 1) AS query_text,
            qs.execution_count,
            qs.total_logical_reads,
            qs.total_logical_reads / qs.execution_count AS avg_logical_reads,
            qs.total_elapsed_time / 1000 AS total_elapsed_time_ms,
            qs.last_execution_time
        FROM sys.dm_exec_query_stats qs
        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
        WHERE st.dbid = DB_ID()
        ORDER BY qs.total_logical_reads DESC;
    END
    ELSE -- Default: elapsed_time
    BEGIN
        SELECT TOP (@TopN)
            qs.query_hash,
            SUBSTRING(st.text, (qs.statement_start_offset/2)+1,
                ((CASE qs.statement_end_offset
                    WHEN -1 THEN DATALENGTH(st.text)
                    ELSE qs.statement_end_offset
                END - qs.statement_start_offset)/2) + 1) AS query_text,
            qs.execution_count,
            qs.total_elapsed_time / 1000 AS total_elapsed_time_ms,
            (qs.total_elapsed_time / qs.execution_count) / 1000 AS avg_elapsed_time_ms,
            qs.total_worker_time / 1000 AS total_cpu_time_ms,
            qs.total_logical_reads,
            qs.last_execution_time
        FROM sys.dm_exec_query_stats qs
        CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
        WHERE st.dbid = DB_ID()
        ORDER BY qs.total_elapsed_time DESC;
    END
END
GO

PRINT '   GetTopExpensiveQueries procedure created';

-- Procedure to log operation runtime (wrapper for existing RunTimeStats)
IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'LogOperationRuntime')
    DROP PROCEDURE [dbo].[LogOperationRuntime];
GO

CREATE PROCEDURE [dbo].[LogOperationRuntime]
    @Operation VARCHAR(255),
    @StartTime DATETIME,
    @EndTime DATETIME = NULL,
    @RowsAffected INT = NULL,
    @QueryText NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @EndTime IS NULL
        SET @EndTime = GETDATE();
    
    DECLARE @Duration INT = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
    
    INSERT INTO [dbo].[RunTimeStats] ([SessionID], [RunTime], [Operation], [Duration_ms], [RowsAffected], [QueryText])
    VALUES (@@SPID, @EndTime, @Operation, @Duration, @RowsAffected, @QueryText);
    
    -- Check if this operation breached SLA
    DECLARE @WarningThreshold FLOAT, @CriticalThreshold FLOAT;
    SELECT @WarningThreshold = warning_threshold, @CriticalThreshold = critical_threshold
    FROM [dbo].[SLAThresholds]
    WHERE operation_name = @Operation AND is_active = 1;
    
    IF @Duration > @CriticalThreshold
    BEGIN
        INSERT INTO [dbo].[SLAAlerts] ([operation_name], [metric_name], [current_value], [threshold_value], [severity], [alert_message])
        VALUES (@Operation, 'execution_time', @Duration, @CriticalThreshold, 'CRITICAL',
                @Operation + ' exceeded critical SLA threshold: ' + CAST(@Duration AS VARCHAR(20)) + 'ms (threshold: ' + CAST(CAST(@CriticalThreshold AS INT) AS VARCHAR(20)) + 'ms)');
    END
    ELSE IF @Duration > @WarningThreshold
    BEGIN
        INSERT INTO [dbo].[SLAAlerts] ([operation_name], [metric_name], [current_value], [threshold_value], [severity], [alert_message])
        VALUES (@Operation, 'execution_time', @Duration, @WarningThreshold, 'WARNING',
                @Operation + ' exceeded warning SLA threshold: ' + CAST(@Duration AS VARCHAR(20)) + 'ms (threshold: ' + CAST(CAST(@WarningThreshold AS INT) AS VARCHAR(20)) + 'ms)');
    END
    
    PRINT 'Operation logged: ' + @Operation + ' - Duration: ' + CAST(@Duration AS VARCHAR(20)) + 'ms';
END
GO

PRINT '   LogOperationRuntime procedure created';

GO

-- ============================================================================
-- SECTION 3: MONITORING DASHBOARD VIEWS
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 3: CREATING MONITORING DASHBOARD VIEWS';
PRINT '----------------------------------------------------------------------------';

-- View for current SLA status
IF EXISTS (SELECT 1 FROM sys.views WHERE name = 'vw_SLAStatus')
    DROP VIEW [dbo].[vw_SLAStatus];
GO

CREATE VIEW [dbo].[vw_SLAStatus]
AS
SELECT 
    t.operation_name,
    t.metric_name,
    t.warning_threshold,
    t.critical_threshold,
    t.unit,
    COALESCE(
        (SELECT TOP 1 current_value 
         FROM [dbo].[SLAAlerts] a 
         WHERE a.operation_name = t.operation_name 
         ORDER BY alert_time DESC), 
        0
    ) AS last_measured_value,
    COALESCE(
        (SELECT TOP 1 severity 
         FROM [dbo].[SLAAlerts] a 
         WHERE a.operation_name = t.operation_name 
           AND a.alert_time > DATEADD(HOUR, -24, GETDATE())
         ORDER BY alert_time DESC), 
        'OK'
    ) AS current_status,
    (SELECT COUNT(*) 
     FROM [dbo].[SLAAlerts] a 
     WHERE a.operation_name = t.operation_name 
       AND a.alert_time > DATEADD(HOUR, -24, GETDATE())
       AND a.is_acknowledged = 0
    ) AS unacknowledged_alerts_24h
FROM [dbo].[SLAThresholds] t
WHERE t.is_active = 1;
GO

PRINT '   vw_SLAStatus view created';

-- View for operation performance summary
IF EXISTS (SELECT 1 FROM sys.views WHERE name = 'vw_OperationPerformance')
    DROP VIEW [dbo].[vw_OperationPerformance];
GO

CREATE VIEW [dbo].[vw_OperationPerformance]
AS
SELECT 
    Operation,
    COUNT(*) AS ExecutionCount,
    MIN(Duration_ms) AS MinDurationMs,
    MAX(Duration_ms) AS MaxDurationMs,
    AVG(Duration_ms) AS AvgDurationMs,
    SUM(RowsAffected) AS TotalRowsAffected,
    MIN(RunTime) AS FirstExecution,
    MAX(RunTime) AS LastExecution
FROM [dbo].[RunTimeStats]
WHERE Operation NOT LIKE '%Baseline%' AND Operation NOT LIKE '%Optimized%'
GROUP BY Operation;
GO

PRINT '   vw_OperationPerformance view created';

-- View for recent alerts
IF EXISTS (SELECT 1 FROM sys.views WHERE name = 'vw_RecentAlerts')
    DROP VIEW [dbo].[vw_RecentAlerts];
GO

CREATE VIEW [dbo].[vw_RecentAlerts]
AS
SELECT 
    alert_id,
    alert_time,
    operation_name,
    metric_name,
    current_value,
    threshold_value,
    severity,
    alert_message,
    is_acknowledged,
    acknowledged_by,
    acknowledged_at,
    DATEDIFF(MINUTE, alert_time, GETDATE()) AS minutes_ago
FROM [dbo].[SLAAlerts]
WHERE alert_time > DATEADD(DAY, -7, GETDATE());
GO

PRINT '   vw_RecentAlerts view created';

-- View for database health dashboard
IF EXISTS (SELECT 1 FROM sys.views WHERE name = 'vw_DatabaseHealth')
    DROP VIEW [dbo].[vw_DatabaseHealth];
GO

CREATE VIEW [dbo].[vw_DatabaseHealth]
AS
SELECT 
    'LoanStats' AS TableName,
    (SELECT COUNT(*) FROM [dbo].[LoanStats]) AS TotalRecords,
    (SELECT MAX(created_at) FROM [dbo].[LoanStats]) AS LastRecordCreated,
    DATEDIFF(HOUR, (SELECT MAX(created_at) FROM [dbo].[LoanStats]), GETDATE()) AS HoursSinceLastRecord,
    (SELECT COUNT(*) FROM [dbo].[LoanStats] WHERE loan_amnt IS NULL) AS NullLoanAmounts,
    (SELECT COUNT(*) FROM [dbo].[LoanStats] WHERE is_bad = 1) AS BadLoans,
    CAST(100.0 * (SELECT COUNT(*) FROM [dbo].[LoanStats] WHERE is_bad = 1) / NULLIF((SELECT COUNT(*) FROM [dbo].[LoanStats]), 0) AS DECIMAL(5,2)) AS BadLoanPercentage
UNION ALL
SELECT 
    'LoanStatsPredictions',
    (SELECT COUNT(*) FROM [dbo].[LoanStatsPredictions]),
    (SELECT MAX(prediction_date) FROM [dbo].[LoanStatsPredictions]),
    DATEDIFF(HOUR, (SELECT MAX(prediction_date) FROM [dbo].[LoanStatsPredictions]), GETDATE()),
    0,
    0,
    0
UNION ALL
SELECT 
    'LoanStatsStaging',
    (SELECT COUNT(*) FROM [dbo].[LoanStatsStaging]),
    NULL,
    NULL,
    0,
    0,
    0;
GO

PRINT '   vw_DatabaseHealth view created';

GO

-- ============================================================================
-- SECTION 4: RUN INITIAL MONITORING
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 4: RUNNING INITIAL MONITORING';
PRINT '----------------------------------------------------------------------------';

-- Capture initial metrics
EXEC [dbo].[CaptureDatabaseMetrics];
EXEC [dbo].[CaptureQueryPerformance];
EXEC [dbo].[CheckSLACompliance];

PRINT '';
PRINT '4.1 Current SLA Status:';
SELECT * FROM [dbo].[vw_SLAStatus];

PRINT '';
PRINT '4.2 Database Health Dashboard:';
SELECT * FROM [dbo].[vw_DatabaseHealth];

PRINT '';
PRINT '4.3 Recent Alerts (last 7 days):';
SELECT * FROM [dbo].[vw_RecentAlerts] ORDER BY alert_time DESC;

PRINT '';
PRINT '4.4 Top 10 Expensive Queries by Elapsed Time:';
EXEC [dbo].[GetTopExpensiveQueries] @TopN = 10, @OrderBy = 'elapsed_time';

GO

-- ============================================================================
-- SECTION 5: SAMPLE MONITORING QUERIES
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 5: SAMPLE MONITORING QUERIES';
PRINT '----------------------------------------------------------------------------';

PRINT '';
PRINT '5.1 Query to check index usage:';
SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    s.user_seeks,
    s.user_scans,
    s.user_lookups,
    s.user_updates,
    CASE 
        WHEN s.user_seeks + s.user_scans = 0 THEN 'UNUSED'
        WHEN s.user_updates > (s.user_seeks + s.user_scans) * 10 THEN 'HIGH_MAINTENANCE'
        ELSE 'ACTIVE'
    END AS IndexStatus
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
  AND OBJECT_NAME(s.object_id) NOT LIKE 'sys%'
ORDER BY s.user_seeks + s.user_scans DESC;

PRINT '';
PRINT '5.2 Query to check wait statistics:';
SELECT TOP 10
    wait_type,
    waiting_tasks_count,
    wait_time_ms,
    max_wait_time_ms,
    signal_wait_time_ms
FROM sys.dm_os_wait_stats
WHERE wait_type NOT LIKE 'SLEEP%'
  AND wait_type NOT LIKE 'BROKER%'
  AND wait_type NOT LIKE 'XE%'
  AND wait_type NOT LIKE 'SQLTRACE%'
  AND wait_type NOT LIKE 'CLR%'
  AND wait_type NOT LIKE 'LAZYWRITER%'
  AND wait_type NOT LIKE 'CHECKPOINT%'
  AND wait_type NOT IN ('WAITFOR', 'KSOURCE_WAKEUP', 'REQUEST_FOR_DEADLOCK_SEARCH')
ORDER BY wait_time_ms DESC;

PRINT '';
PRINT '5.3 Query to check blocking:';
SELECT 
    r.session_id AS blocked_session,
    r.blocking_session_id AS blocking_session,
    r.wait_type,
    r.wait_time / 1000.0 AS wait_time_seconds,
    r.status,
    SUBSTRING(st.text, (r.statement_start_offset/2)+1,
        ((CASE r.statement_end_offset
            WHEN -1 THEN DATALENGTH(st.text)
            ELSE r.statement_end_offset
        END - r.statement_start_offset)/2) + 1) AS blocked_query
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) st
WHERE r.blocking_session_id > 0;

GO

-- ============================================================================
-- SECTION 6: SCHEDULED JOB RECOMMENDATIONS
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 6: SCHEDULED JOB RECOMMENDATIONS';
PRINT '----------------------------------------------------------------------------';

PRINT '';
PRINT 'To implement automated monitoring, create SQL Server Agent jobs for:';
PRINT '';
PRINT '1. Every 5 minutes: EXEC [dbo].[CaptureDatabaseMetrics]';
PRINT '   - Captures database size, connections, and resource usage';
PRINT '';
PRINT '2. Every 15 minutes: EXEC [dbo].[CaptureQueryPerformance]';
PRINT '   - Logs top expensive queries for trend analysis';
PRINT '';
PRINT '3. Every hour: EXEC [dbo].[CheckSLACompliance]';
PRINT '   - Checks all SLA thresholds and generates alerts';
PRINT '';
PRINT '4. Daily: Run data quality analysis script';
PRINT '   - Comprehensive data quality checks';
PRINT '';
PRINT 'Example SQL Server Agent Job creation:';
PRINT '/*';
PRINT 'USE msdb;';
PRINT 'EXEC sp_add_job @job_name = ''LendingClub_SLA_Check'';';
PRINT 'EXEC sp_add_jobstep @job_name = ''LendingClub_SLA_Check'',';
PRINT '    @step_name = ''Check SLA Compliance'',';
PRINT '    @subsystem = ''TSQL'',';
PRINT '    @command = ''EXEC [LendingClub].[dbo].[CheckSLACompliance]'',';
PRINT '    @database_name = ''LendingClub'';';
PRINT 'EXEC sp_add_schedule @schedule_name = ''Hourly'',';
PRINT '    @freq_type = 4, @freq_interval = 1,';
PRINT '    @freq_subday_type = 8, @freq_subday_interval = 1;';
PRINT 'EXEC sp_attach_schedule @job_name = ''LendingClub_SLA_Check'',';
PRINT '    @schedule_name = ''Hourly'';';
PRINT '*/';

PRINT '';
PRINT '============================================================================';
PRINT 'OBSERVABILITY FRAMEWORK IMPLEMENTATION COMPLETE';
PRINT '============================================================================';
GO
