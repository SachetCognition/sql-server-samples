-- Baseline Performance Tests for WideWorldImporters Stored Procedures
-- Run this script BEFORE applying optimizations

USE WideWorldImporters;
GO

PRINT '=================================================================';
PRINT 'BASELINE PERFORMANCE TESTS - Starting at ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '=================================================================';
GO

-- Clear any previous baseline results
DELETE FROM PerformanceTest.TestResults WHERE TestPhase = 'BASELINE';
DELETE FROM PerformanceTest.IOStatistics WHERE TestPhase = 'BASELINE';
DELETE FROM PerformanceTest.WaitStatistics WHERE TestPhase = 'BASELINE';
GO

-- =====================================================================
-- TEST 1: Integration.GetOrderUpdates
-- =====================================================================
PRINT '';
PRINT '-------------------------------------------------------------';
PRINT 'TEST 1: Integration.GetOrderUpdates';
PRINT '-------------------------------------------------------------';

DECLARE @TestRunID1 UNIQUEIDENTIFIER = NEWID();
DECLARE @StartTime1 DATETIME2(7) = SYSDATETIME();
DECLARE @EndTime1 DATETIME2(7);
DECLARE @CPUStart1 INT, @CPUEnd1 INT;
DECLARE @ReadsStart1 BIGINT, @ReadsEnd1 BIGINT;
DECLARE @WritesStart1 BIGINT, @WritesEnd1 BIGINT;

-- Clear caches for accurate measurement
DBCC FREEPROCCACHE;
DBCC DROPCLEANBUFFERS;
CHECKPOINT;

-- Get starting metrics
SELECT @CPUStart1 = cpu_time FROM sys.dm_exec_sessions WHERE session_id = @@SPID;
SELECT @ReadsStart1 = SUM(num_of_reads), @WritesStart1 = SUM(num_of_writes)
FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL);

-- Execute the procedure
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

DECLARE @LastCutoff1 DATETIME2(7) = '2015-01-01';
DECLARE @NewCutoff1 DATETIME2(7) = '2016-01-01';

EXEC Integration.GetOrderUpdates @LastCutoff = @LastCutoff1, @NewCutoff = @NewCutoff1;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- Get ending metrics
SET @EndTime1 = SYSDATETIME();
SELECT @CPUEnd1 = cpu_time FROM sys.dm_exec_sessions WHERE session_id = @@SPID;
SELECT @ReadsEnd1 = SUM(num_of_reads), @WritesEnd1 = SUM(num_of_writes)
FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL);

-- Record results
INSERT INTO PerformanceTest.TestResults (
    TestRunID, ProcedureName, TestPhase, StartTime, EndTime,
    ExecutionTimeMs, CPUTimeMs, LogicalReads, PhysicalReads, Writes,
    TestParameters
)
VALUES (
    @TestRunID1, 
    'Integration.GetOrderUpdates', 
    'BASELINE', 
    @StartTime1, 
    @EndTime1,
    DATEDIFF(MILLISECOND, @StartTime1, @EndTime1),
    @CPUEnd1 - @CPUStart1,
    @ReadsEnd1 - @ReadsStart1,
    0,
    @WritesEnd1 - @WritesStart1,
    '@LastCutoff=2015-01-01, @NewCutoff=2016-01-01'
);

PRINT 'GetOrderUpdates completed in ' + CAST(DATEDIFF(MILLISECOND, @StartTime1, @EndTime1) AS VARCHAR) + ' ms';
GO

-- =====================================================================
-- TEST 2: Integration.GetSaleUpdates
-- =====================================================================
PRINT '';
PRINT '-------------------------------------------------------------';
PRINT 'TEST 2: Integration.GetSaleUpdates';
PRINT '-------------------------------------------------------------';

DECLARE @TestRunID2 UNIQUEIDENTIFIER = NEWID();
DECLARE @StartTime2 DATETIME2(7) = SYSDATETIME();
DECLARE @EndTime2 DATETIME2(7);
DECLARE @CPUStart2 INT, @CPUEnd2 INT;
DECLARE @ReadsStart2 BIGINT, @ReadsEnd2 BIGINT;
DECLARE @WritesStart2 BIGINT, @WritesEnd2 BIGINT;

-- Clear caches
DBCC FREEPROCCACHE;
DBCC DROPCLEANBUFFERS;
CHECKPOINT;

-- Get starting metrics
SELECT @CPUStart2 = cpu_time FROM sys.dm_exec_sessions WHERE session_id = @@SPID;
SELECT @ReadsStart2 = SUM(num_of_reads), @WritesStart2 = SUM(num_of_writes)
FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL);

-- Execute the procedure
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

DECLARE @LastCutoff2 DATETIME2(7) = '2015-01-01';
DECLARE @NewCutoff2 DATETIME2(7) = '2016-01-01';

EXEC Integration.GetSaleUpdates @LastCutoff = @LastCutoff2, @NewCutoff = @NewCutoff2;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- Get ending metrics
SET @EndTime2 = SYSDATETIME();
SELECT @CPUEnd2 = cpu_time FROM sys.dm_exec_sessions WHERE session_id = @@SPID;
SELECT @ReadsEnd2 = SUM(num_of_reads), @WritesEnd2 = SUM(num_of_writes)
FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL);

-- Record results
INSERT INTO PerformanceTest.TestResults (
    TestRunID, ProcedureName, TestPhase, StartTime, EndTime,
    ExecutionTimeMs, CPUTimeMs, LogicalReads, PhysicalReads, Writes,
    TestParameters
)
VALUES (
    @TestRunID2, 
    'Integration.GetSaleUpdates', 
    'BASELINE', 
    @StartTime2, 
    @EndTime2,
    DATEDIFF(MILLISECOND, @StartTime2, @EndTime2),
    @CPUEnd2 - @CPUStart2,
    @ReadsEnd2 - @ReadsStart2,
    0,
    @WritesEnd2 - @WritesStart2,
    '@LastCutoff=2015-01-01, @NewCutoff=2016-01-01'
);

PRINT 'GetSaleUpdates completed in ' + CAST(DATEDIFF(MILLISECOND, @StartTime2, @EndTime2) AS VARCHAR) + ' ms';
GO

-- =====================================================================
-- TEST 3: Application.Configuration_ApplyRowLevelSecurity
-- =====================================================================
PRINT '';
PRINT '-------------------------------------------------------------';
PRINT 'TEST 3: Application.Configuration_ApplyRowLevelSecurity';
PRINT '-------------------------------------------------------------';

DECLARE @TestRunID3 UNIQUEIDENTIFIER = NEWID();
DECLARE @StartTime3 DATETIME2(7) = SYSDATETIME();
DECLARE @EndTime3 DATETIME2(7);
DECLARE @CPUStart3 INT, @CPUEnd3 INT;
DECLARE @ReadsStart3 BIGINT, @ReadsEnd3 BIGINT;
DECLARE @WritesStart3 BIGINT, @WritesEnd3 BIGINT;

-- Clear caches
DBCC FREEPROCCACHE;
DBCC DROPCLEANBUFFERS;
CHECKPOINT;

-- Get starting metrics
SELECT @CPUStart3 = cpu_time FROM sys.dm_exec_sessions WHERE session_id = @@SPID;
SELECT @ReadsStart3 = SUM(num_of_reads), @WritesStart3 = SUM(num_of_writes)
FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL);

-- Execute the procedure
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

EXEC [Application].Configuration_ApplyRowLevelSecurity;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- Get ending metrics
SET @EndTime3 = SYSDATETIME();
SELECT @CPUEnd3 = cpu_time FROM sys.dm_exec_sessions WHERE session_id = @@SPID;
SELECT @ReadsEnd3 = SUM(num_of_reads), @WritesEnd3 = SUM(num_of_writes)
FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL);

-- Record results
INSERT INTO PerformanceTest.TestResults (
    TestRunID, ProcedureName, TestPhase, StartTime, EndTime,
    ExecutionTimeMs, CPUTimeMs, LogicalReads, PhysicalReads, Writes,
    TestParameters
)
VALUES (
    @TestRunID3, 
    'Application.Configuration_ApplyRowLevelSecurity', 
    'BASELINE', 
    @StartTime3, 
    @EndTime3,
    DATEDIFF(MILLISECOND, @StartTime3, @EndTime3),
    @CPUEnd3 - @CPUStart3,
    @ReadsEnd3 - @ReadsStart3,
    0,
    @WritesEnd3 - @WritesStart3,
    'No parameters'
);

PRINT 'Configuration_ApplyRowLevelSecurity completed in ' + CAST(DATEDIFF(MILLISECOND, @StartTime3, @EndTime3) AS VARCHAR) + ' ms';
GO

-- =====================================================================
-- TEST 4: Website.InvoiceCustomerOrders
-- =====================================================================
PRINT '';
PRINT '-------------------------------------------------------------';
PRINT 'TEST 4: Website.InvoiceCustomerOrders';
PRINT '-------------------------------------------------------------';

-- First, find orders that can be invoiced (picked but not yet invoiced)
DECLARE @OrdersToInvoice Website.OrderIDList;

-- Get orders that are picked but not invoiced (limit to 100 for testing)
INSERT INTO @OrdersToInvoice (OrderID)
SELECT TOP 100 o.OrderID
FROM Sales.Orders o
WHERE o.PickingCompletedWhen IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM Sales.Invoices i WHERE i.OrderID = o.OrderID);

DECLARE @OrderCount INT = (SELECT COUNT(*) FROM @OrdersToInvoice);
PRINT 'Found ' + CAST(@OrderCount AS VARCHAR) + ' orders to invoice';

-- If no orders to invoice, we need to create test data
IF @OrderCount = 0
BEGIN
    PRINT 'No uninvoiced orders found. Testing with empty set.';
END

DECLARE @TestRunID4 UNIQUEIDENTIFIER = NEWID();
DECLARE @StartTime4 DATETIME2(7) = SYSDATETIME();
DECLARE @EndTime4 DATETIME2(7);
DECLARE @CPUStart4 INT, @CPUEnd4 INT;
DECLARE @ReadsStart4 BIGINT, @ReadsEnd4 BIGINT;
DECLARE @WritesStart4 BIGINT, @WritesEnd4 BIGINT;

-- Clear caches
DBCC FREEPROCCACHE;
DBCC DROPCLEANBUFFERS;
CHECKPOINT;

-- Get starting metrics
SELECT @CPUStart4 = cpu_time FROM sys.dm_exec_sessions WHERE session_id = @@SPID;
SELECT @ReadsStart4 = SUM(num_of_reads), @WritesStart4 = SUM(num_of_writes)
FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL);

-- Execute the procedure (in a transaction we'll roll back to preserve data)
BEGIN TRAN;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

BEGIN TRY
    EXEC Website.InvoiceCustomerOrders 
        @OrdersToInvoice = @OrdersToInvoice,
        @PackedByPersonID = 1,
        @InvoicedByPersonID = 1;
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

ROLLBACK TRAN;

-- Get ending metrics
SET @EndTime4 = SYSDATETIME();
SELECT @CPUEnd4 = cpu_time FROM sys.dm_exec_sessions WHERE session_id = @@SPID;
SELECT @ReadsEnd4 = SUM(num_of_reads), @WritesEnd4 = SUM(num_of_writes)
FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL);

-- Record results
INSERT INTO PerformanceTest.TestResults (
    TestRunID, ProcedureName, TestPhase, StartTime, EndTime,
    ExecutionTimeMs, CPUTimeMs, LogicalReads, PhysicalReads, Writes,
    TestParameters
)
VALUES (
    @TestRunID4, 
    'Website.InvoiceCustomerOrders', 
    'BASELINE', 
    @StartTime4, 
    @EndTime4,
    DATEDIFF(MILLISECOND, @StartTime4, @EndTime4),
    @CPUEnd4 - @CPUStart4,
    @ReadsEnd4 - @ReadsStart4,
    0,
    @WritesEnd4 - @WritesStart4,
    '@OrderCount=' + CAST(@OrderCount AS VARCHAR)
);

PRINT 'InvoiceCustomerOrders completed in ' + CAST(DATEDIFF(MILLISECOND, @StartTime4, @EndTime4) AS VARCHAR) + ' ms';
GO

-- =====================================================================
-- TEST 5: DataLoadSimulation.DailyProcessToCreateHistory (Limited Test)
-- =====================================================================
PRINT '';
PRINT '-------------------------------------------------------------';
PRINT 'TEST 5: DataLoadSimulation.DailyProcessToCreateHistory';
PRINT '-------------------------------------------------------------';
PRINT 'Note: Testing with 3-day range to avoid long execution time';

DECLARE @TestRunID5 UNIQUEIDENTIFIER = NEWID();
DECLARE @StartTime5 DATETIME2(7) = SYSDATETIME();
DECLARE @EndTime5 DATETIME2(7);
DECLARE @CPUStart5 INT, @CPUEnd5 INT;
DECLARE @ReadsStart5 BIGINT, @ReadsEnd5 BIGINT;
DECLARE @WritesStart5 BIGINT, @WritesEnd5 BIGINT;

-- Clear caches
DBCC FREEPROCCACHE;
DBCC DROPCLEANBUFFERS;
CHECKPOINT;

-- Get starting metrics
SELECT @CPUStart5 = cpu_time FROM sys.dm_exec_sessions WHERE session_id = @@SPID;
SELECT @ReadsStart5 = SUM(num_of_reads), @WritesStart5 = SUM(num_of_writes)
FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL);

-- Get current max date and test with next 3 days
DECLARE @CurrentMaxDate DATE = (SELECT MAX(OrderDate) FROM Sales.Orders);
DECLARE @TestStartDate DATE = DATEADD(DAY, 1, @CurrentMaxDate);
DECLARE @TestEndDate DATE = DATEADD(DAY, 3, @CurrentMaxDate);

PRINT 'Testing date range: ' + CAST(@TestStartDate AS VARCHAR) + ' to ' + CAST(@TestEndDate AS VARCHAR);

-- Execute the procedure
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

BEGIN TRY
    EXEC DataLoadSimulation.DailyProcessToCreateHistory
        @StartDate = @TestStartDate,
        @EndDate = @TestEndDate,
        @AverageNumberOfCustomerOrdersPerDay = 30,
        @SaturdayPercentageOfNormalWorkDay = 50,
        @SundayPercentageOfNormalWorkDay = 25,
        @UpdateCustomFields = 0,
        @IsSilentMode = 1,
        @AreDatesPrinted = 0;
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- Get ending metrics
SET @EndTime5 = SYSDATETIME();
SELECT @CPUEnd5 = cpu_time FROM sys.dm_exec_sessions WHERE session_id = @@SPID;
SELECT @ReadsEnd5 = SUM(num_of_reads), @WritesEnd5 = SUM(num_of_writes)
FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL);

-- Record results
INSERT INTO PerformanceTest.TestResults (
    TestRunID, ProcedureName, TestPhase, StartTime, EndTime,
    ExecutionTimeMs, CPUTimeMs, LogicalReads, PhysicalReads, Writes,
    TestParameters
)
VALUES (
    @TestRunID5, 
    'DataLoadSimulation.DailyProcessToCreateHistory', 
    'BASELINE', 
    @StartTime5, 
    @EndTime5,
    DATEDIFF(MILLISECOND, @StartTime5, @EndTime5),
    @CPUEnd5 - @CPUStart5,
    @ReadsEnd5 - @ReadsStart5,
    0,
    @WritesEnd5 - @WritesStart5,
    '@StartDate=' + CAST(@TestStartDate AS VARCHAR) + ', @EndDate=' + CAST(@TestEndDate AS VARCHAR) + ', @Days=3'
);

PRINT 'DailyProcessToCreateHistory completed in ' + CAST(DATEDIFF(MILLISECOND, @StartTime5, @EndTime5) AS VARCHAR) + ' ms';
GO

-- =====================================================================
-- TEST 6: DataLoadSimulation.PopulateDataToCurrentDate (Wrapper Test)
-- =====================================================================
PRINT '';
PRINT '-------------------------------------------------------------';
PRINT 'TEST 6: DataLoadSimulation.PopulateDataToCurrentDate';
PRINT '-------------------------------------------------------------';
PRINT 'Note: This is a wrapper for DailyProcessToCreateHistory';
PRINT 'Testing execution overhead only (no new data to process)';

DECLARE @TestRunID6 UNIQUEIDENTIFIER = NEWID();
DECLARE @StartTime6 DATETIME2(7) = SYSDATETIME();
DECLARE @EndTime6 DATETIME2(7);
DECLARE @CPUStart6 INT, @CPUEnd6 INT;
DECLARE @ReadsStart6 BIGINT, @ReadsEnd6 BIGINT;
DECLARE @WritesStart6 BIGINT, @WritesEnd6 BIGINT;

-- Clear caches
DBCC FREEPROCCACHE;
DBCC DROPCLEANBUFFERS;
CHECKPOINT;

-- Get starting metrics
SELECT @CPUStart6 = cpu_time FROM sys.dm_exec_sessions WHERE session_id = @@SPID;
SELECT @ReadsStart6 = SUM(num_of_reads), @WritesStart6 = SUM(num_of_writes)
FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL);

-- Execute the procedure
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

BEGIN TRY
    EXEC DataLoadSimulation.PopulateDataToCurrentDate
        @AverageNumberOfCustomerOrdersPerDay = 30,
        @SaturdayPercentageOfNormalWorkDay = 50,
        @SundayPercentageOfNormalWorkDay = 25,
        @IsSilentMode = 1,
        @AreDatesPrinted = 0;
END TRY
BEGIN CATCH
    PRINT 'Error: ' + ERROR_MESSAGE();
END CATCH

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

-- Get ending metrics
SET @EndTime6 = SYSDATETIME();
SELECT @CPUEnd6 = cpu_time FROM sys.dm_exec_sessions WHERE session_id = @@SPID;
SELECT @ReadsEnd6 = SUM(num_of_reads), @WritesEnd6 = SUM(num_of_writes)
FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL);

-- Record results
INSERT INTO PerformanceTest.TestResults (
    TestRunID, ProcedureName, TestPhase, StartTime, EndTime,
    ExecutionTimeMs, CPUTimeMs, LogicalReads, PhysicalReads, Writes,
    TestParameters
)
VALUES (
    @TestRunID6, 
    'DataLoadSimulation.PopulateDataToCurrentDate', 
    'BASELINE', 
    @StartTime6, 
    @EndTime6,
    DATEDIFF(MILLISECOND, @StartTime6, @EndTime6),
    @CPUEnd6 - @CPUStart6,
    @ReadsEnd6 - @ReadsStart6,
    0,
    @WritesEnd6 - @WritesStart6,
    '@AverageNumberOfCustomerOrdersPerDay=30'
);

PRINT 'PopulateDataToCurrentDate completed in ' + CAST(DATEDIFF(MILLISECOND, @StartTime6, @EndTime6) AS VARCHAR) + ' ms';
GO

-- =====================================================================
-- BASELINE RESULTS SUMMARY
-- =====================================================================
PRINT '';
PRINT '=================================================================';
PRINT 'BASELINE PERFORMANCE RESULTS SUMMARY';
PRINT '=================================================================';

SELECT 
    ProcedureName,
    ExecutionTimeMs,
    CPUTimeMs,
    LogicalReads,
    Writes,
    TestParameters,
    StartTime
FROM PerformanceTest.TestResults
WHERE TestPhase = 'BASELINE'
ORDER BY ProcedureName;

PRINT '';
PRINT 'Baseline tests completed at ' + CONVERT(VARCHAR, GETDATE(), 120);
GO
