-- Performance Testing Framework for WideWorldImporters Stored Procedures
-- This framework captures comprehensive performance metrics before and after optimization

USE WideWorldImporters;
GO

-- Create schema for performance testing if not exists
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'PerformanceTest')
BEGIN
    EXEC('CREATE SCHEMA PerformanceTest');
END
GO

-- Drop existing tables if they exist
DROP TABLE IF EXISTS PerformanceTest.TestResults;
DROP TABLE IF EXISTS PerformanceTest.IOStatistics;
DROP TABLE IF EXISTS PerformanceTest.WaitStatistics;
GO

-- Create table to store test results
CREATE TABLE PerformanceTest.TestResults (
    TestID INT IDENTITY(1,1) PRIMARY KEY,
    TestRunID UNIQUEIDENTIFIER NOT NULL,
    ProcedureName NVARCHAR(256) NOT NULL,
    TestPhase NVARCHAR(50) NOT NULL, -- 'BASELINE' or 'OPTIMIZED'
    StartTime DATETIME2(7) NOT NULL,
    EndTime DATETIME2(7) NULL,
    ExecutionTimeMs BIGINT NULL,
    CPUTimeMs BIGINT NULL,
    LogicalReads BIGINT NULL,
    PhysicalReads BIGINT NULL,
    Writes BIGINT NULL,
    RowsAffected BIGINT NULL,
    WorkerTimeUs BIGINT NULL,
    ElapsedTimeUs BIGINT NULL,
    ErrorMessage NVARCHAR(MAX) NULL,
    TestParameters NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2(7) DEFAULT SYSDATETIME()
);
GO

-- Create table to store I/O statistics per table
CREATE TABLE PerformanceTest.IOStatistics (
    IOStatID INT IDENTITY(1,1) PRIMARY KEY,
    TestRunID UNIQUEIDENTIFIER NOT NULL,
    ProcedureName NVARCHAR(256) NOT NULL,
    TestPhase NVARCHAR(50) NOT NULL,
    TableName NVARCHAR(256) NOT NULL,
    IndexName NVARCHAR(256) NULL,
    ScanCount BIGINT NULL,
    LogicalReads BIGINT NULL,
    PhysicalReads BIGINT NULL,
    ReadAheadReads BIGINT NULL,
    LobLogicalReads BIGINT NULL,
    LobPhysicalReads BIGINT NULL,
    LobReadAheadReads BIGINT NULL,
    CreatedAt DATETIME2(7) DEFAULT SYSDATETIME()
);
GO

-- Create table to store wait statistics
CREATE TABLE PerformanceTest.WaitStatistics (
    WaitStatID INT IDENTITY(1,1) PRIMARY KEY,
    TestRunID UNIQUEIDENTIFIER NOT NULL,
    ProcedureName NVARCHAR(256) NOT NULL,
    TestPhase NVARCHAR(50) NOT NULL,
    WaitType NVARCHAR(128) NOT NULL,
    WaitingTasksCount BIGINT NULL,
    WaitTimeMs BIGINT NULL,
    MaxWaitTimeMs BIGINT NULL,
    SignalWaitTimeMs BIGINT NULL,
    CreatedAt DATETIME2(7) DEFAULT SYSDATETIME()
);
GO

-- Stored procedure to capture baseline wait stats
CREATE OR ALTER PROCEDURE PerformanceTest.CaptureWaitStats
    @TestRunID UNIQUEIDENTIFIER,
    @ProcedureName NVARCHAR(256),
    @TestPhase NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO PerformanceTest.WaitStatistics (
        TestRunID, ProcedureName, TestPhase, WaitType, 
        WaitingTasksCount, WaitTimeMs, MaxWaitTimeMs, SignalWaitTimeMs
    )
    SELECT 
        @TestRunID,
        @ProcedureName,
        @TestPhase,
        wait_type,
        waiting_tasks_count,
        wait_time_ms,
        max_wait_time_ms,
        signal_wait_time_ms
    FROM sys.dm_os_wait_stats
    WHERE wait_time_ms > 0
    AND wait_type NOT LIKE '%SLEEP%'
    AND wait_type NOT LIKE 'BROKER%'
    AND wait_type NOT LIKE 'XE%'
    AND wait_type NOT IN ('CLR_AUTO_EVENT', 'CLR_MANUAL_EVENT', 'REQUEST_FOR_DEADLOCK_SEARCH',
                          'SQLTRACE_BUFFER_FLUSH', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
                          'LAZYWRITER_SLEEP', 'CHECKPOINT_QUEUE', 'DIRTY_PAGE_POLL',
                          'HADR_FILESTREAM_IOMGR_IOCOMPLETION', 'LOGMGR_QUEUE',
                          'FT_IFTS_SCHEDULER_IDLE_WAIT', 'FT_IFTSHC_MUTEX');
END;
GO

-- Stored procedure to run performance test for a specific procedure
CREATE OR ALTER PROCEDURE PerformanceTest.RunPerformanceTest
    @ProcedureName NVARCHAR(256),
    @TestPhase NVARCHAR(50),
    @TestSQL NVARCHAR(MAX),
    @TestParameters NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @TestRunID UNIQUEIDENTIFIER = NEWID();
    DECLARE @StartTime DATETIME2(7);
    DECLARE @EndTime DATETIME2(7);
    DECLARE @CPUTime BIGINT;
    DECLARE @ElapsedTime BIGINT;
    DECLARE @LogicalReads BIGINT;
    DECLARE @PhysicalReads BIGINT;
    DECLARE @Writes BIGINT;
    DECLARE @RowsAffected BIGINT;
    DECLARE @ErrorMessage NVARCHAR(MAX);
    
    -- Clear procedure cache for accurate testing
    DBCC FREEPROCCACHE;
    DBCC DROPCLEANBUFFERS;
    
    -- Capture initial wait stats
    EXEC PerformanceTest.CaptureWaitStats @TestRunID, @ProcedureName, @TestPhase;
    
    -- Enable statistics
    SET STATISTICS IO ON;
    SET STATISTICS TIME ON;
    
    -- Record start time and CPU
    SELECT @StartTime = SYSDATETIME();
    
    DECLARE @StartCPU BIGINT, @StartElapsed BIGINT;
    SELECT @StartCPU = cpu_time, @StartElapsed = total_elapsed_time
    FROM sys.dm_exec_requests WHERE session_id = @@SPID;
    
    -- Execute the test
    BEGIN TRY
        EXEC sp_executesql @TestSQL;
        SET @RowsAffected = @@ROWCOUNT;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
    END CATCH
    
    -- Record end time and calculate metrics
    SELECT @EndTime = SYSDATETIME();
    
    DECLARE @EndCPU BIGINT, @EndElapsed BIGINT;
    SELECT @EndCPU = cpu_time, @EndElapsed = total_elapsed_time
    FROM sys.dm_exec_requests WHERE session_id = @@SPID;
    
    SET @CPUTime = ISNULL(@EndCPU - @StartCPU, 0);
    SET @ElapsedTime = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
    
    -- Get I/O statistics from recent query stats
    SELECT TOP 1
        @LogicalReads = total_logical_reads,
        @PhysicalReads = total_physical_reads,
        @Writes = total_logical_writes
    FROM sys.dm_exec_query_stats
    ORDER BY last_execution_time DESC;
    
    SET STATISTICS IO OFF;
    SET STATISTICS TIME OFF;
    
    -- Insert test results
    INSERT INTO PerformanceTest.TestResults (
        TestRunID, ProcedureName, TestPhase, StartTime, EndTime,
        ExecutionTimeMs, CPUTimeMs, LogicalReads, PhysicalReads, Writes,
        RowsAffected, ErrorMessage, TestParameters
    )
    VALUES (
        @TestRunID, @ProcedureName, @TestPhase, @StartTime, @EndTime,
        @ElapsedTime, @CPUTime, @LogicalReads, @PhysicalReads, @Writes,
        @RowsAffected, @ErrorMessage, @TestParameters
    );
    
    -- Return the test run ID
    SELECT @TestRunID AS TestRunID, @ElapsedTime AS ExecutionTimeMs, @ErrorMessage AS ErrorMessage;
END;
GO

-- Stored procedure to generate comparison report
CREATE OR ALTER PROCEDURE PerformanceTest.GenerateComparisonReport
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        b.ProcedureName,
        b.ExecutionTimeMs AS BaselineTimeMs,
        o.ExecutionTimeMs AS OptimizedTimeMs,
        CAST((b.ExecutionTimeMs - o.ExecutionTimeMs) AS FLOAT) / NULLIF(b.ExecutionTimeMs, 0) * 100 AS ImprovementPercent,
        b.CPUTimeMs AS BaselineCPUMs,
        o.CPUTimeMs AS OptimizedCPUMs,
        b.LogicalReads AS BaselineLogicalReads,
        o.LogicalReads AS OptimizedLogicalReads,
        b.PhysicalReads AS BaselinePhysicalReads,
        o.PhysicalReads AS OptimizedPhysicalReads,
        b.Writes AS BaselineWrites,
        o.Writes AS OptimizedWrites
    FROM PerformanceTest.TestResults b
    LEFT JOIN PerformanceTest.TestResults o 
        ON b.ProcedureName = o.ProcedureName AND o.TestPhase = 'OPTIMIZED'
    WHERE b.TestPhase = 'BASELINE'
    ORDER BY b.ProcedureName;
END;
GO

PRINT 'Performance Testing Framework created successfully';
GO
