-- ============================================================================
-- LendingClub Database - Query Optimization Analysis
-- ============================================================================
-- This script demonstrates query optimization techniques including:
-- - Identifying slow queries
-- - Analyzing execution plans
-- - Creating appropriate indexes
-- - Measuring performance improvements
-- ============================================================================

USE [LendingClub]
GO

SET NOCOUNT ON;
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

PRINT '============================================================================';
PRINT 'LENDINGCLUB DATABASE - QUERY OPTIMIZATION ANALYSIS';
PRINT 'Generated: ' + CONVERT(VARCHAR(30), GETDATE(), 120);
PRINT '============================================================================';
PRINT '';

-- ============================================================================
-- SECTION 1: BASELINE - IDENTIFY SLOW ANALYTICS QUERIES
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 1: BASELINE SLOW QUERY ANALYSIS';
PRINT '----------------------------------------------------------------------------';

-- Clear the procedure cache to get accurate measurements
DBCC FREEPROCCACHE;
DBCC DROPCLEANBUFFERS;
GO

-- Record start time
DECLARE @StartTime DATETIME = GETDATE();
DECLARE @EndTime DATETIME;
DECLARE @Duration INT;

PRINT '';
PRINT '1.1 SLOW QUERY #1: Complex Loan Risk Analysis by State and Grade';
PRINT '    This query performs aggregations across multiple dimensions without indexes';
PRINT '';

-- Slow Query #1: Complex aggregation without proper indexes
SELECT 
    addr_state,
    grade,
    loan_status,
    COUNT(*) AS LoanCount,
    SUM(loan_amnt) AS TotalLoanAmount,
    AVG(int_rate) AS AvgInterestRate,
    AVG(annual_inc) AS AvgAnnualIncome,
    AVG(dti) AS AvgDTI,
    SUM(CASE WHEN is_bad = 1 THEN 1 ELSE 0 END) AS BadLoans,
    CAST(100.0 * SUM(CASE WHEN is_bad = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS BadLoanPercentage
FROM [dbo].[LoanStats]
WHERE loan_amnt IS NOT NULL
  AND int_rate IS NOT NULL
  AND annual_inc IS NOT NULL
GROUP BY addr_state, grade, loan_status
ORDER BY addr_state, grade, loan_status;

SET @EndTime = GETDATE();
SET @Duration = DATEDIFF(MILLISECOND, @StartTime, @EndTime);
PRINT 'Query 1 Duration: ' + CAST(@Duration AS VARCHAR(20)) + ' ms';
PRINT '';

-- Record baseline for Query 1
INSERT INTO [dbo].[RunTimeStats] ([SessionID], [RunTime], [Operation], [Duration_ms], [QueryText])
VALUES (@@SPID, GETDATE(), 'Query1_Baseline', @Duration, 'Complex Loan Risk Analysis by State and Grade');

GO

-- Slow Query #2: Loan Performance Trend Analysis
DECLARE @StartTime2 DATETIME = GETDATE();
DECLARE @EndTime2 DATETIME;
DECLARE @Duration2 INT;

PRINT '1.2 SLOW QUERY #2: Loan Performance Trend Analysis';
PRINT '    This query analyzes loan performance over time with multiple joins';
PRINT '';

SELECT 
    SUBSTRING(issue_d, 1, 3) AS IssueMonth,
    RIGHT(issue_d, 4) AS IssueYear,
    purpose,
    verification_status,
    COUNT(*) AS LoanCount,
    SUM(loan_amnt) AS TotalFunded,
    AVG(int_rate) AS AvgRate,
    SUM(total_pymnt) AS TotalPayments,
    SUM(total_rec_prncp) AS TotalPrincipalReceived,
    SUM(total_rec_int) AS TotalInterestReceived,
    SUM(recoveries) AS TotalRecoveries,
    AVG(CASE WHEN is_bad = 1 THEN int_rate ELSE NULL END) AS AvgRateBadLoans,
    AVG(CASE WHEN is_bad = 0 THEN int_rate ELSE NULL END) AS AvgRateGoodLoans
FROM [dbo].[LoanStats]
WHERE issue_d IS NOT NULL
GROUP BY SUBSTRING(issue_d, 1, 3), RIGHT(issue_d, 4), purpose, verification_status
ORDER BY RIGHT(issue_d, 4), SUBSTRING(issue_d, 1, 3), purpose;

SET @EndTime2 = GETDATE();
SET @Duration2 = DATEDIFF(MILLISECOND, @StartTime2, @EndTime2);
PRINT 'Query 2 Duration: ' + CAST(@Duration2 AS VARCHAR(20)) + ' ms';
PRINT '';

INSERT INTO [dbo].[RunTimeStats] ([SessionID], [RunTime], [Operation], [Duration_ms], [QueryText])
VALUES (@@SPID, GETDATE(), 'Query2_Baseline', @Duration2, 'Loan Performance Trend Analysis');

GO

-- Slow Query #3: High-Risk Borrower Identification
DECLARE @StartTime3 DATETIME = GETDATE();
DECLARE @EndTime3 DATETIME;
DECLARE @Duration3 INT;

PRINT '1.3 SLOW QUERY #3: High-Risk Borrower Identification';
PRINT '    This query identifies high-risk borrowers using multiple filter conditions';
PRINT '';

SELECT 
    id,
    member_id,
    loan_amnt,
    int_rate,
    annual_inc,
    dti,
    grade,
    loan_status,
    delinq_2yrs,
    pub_rec,
    revol_util,
    is_bad
FROM [dbo].[LoanStats]
WHERE (dti > 30 OR int_rate > 20 OR delinq_2yrs > 2)
  AND annual_inc < 50000
  AND loan_amnt > 10000
ORDER BY int_rate DESC, dti DESC;

SET @EndTime3 = GETDATE();
SET @Duration3 = DATEDIFF(MILLISECOND, @StartTime3, @EndTime3);
PRINT 'Query 3 Duration: ' + CAST(@Duration3 AS VARCHAR(20)) + ' ms';
PRINT '';

INSERT INTO [dbo].[RunTimeStats] ([SessionID], [RunTime], [Operation], [Duration_ms], [QueryText])
VALUES (@@SPID, GETDATE(), 'Query3_Baseline', @Duration3, 'High-Risk Borrower Identification');

GO

-- ============================================================================
-- SECTION 2: ANALYZE CURRENT INDEX STRUCTURE
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 2: CURRENT INDEX ANALYSIS';
PRINT '----------------------------------------------------------------------------';

PRINT '2.1 Current indexes on LoanStats table:';
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    i.is_primary_key AS IsPrimaryKey,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS IndexColumns
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('dbo.LoanStats')
GROUP BY i.name, i.type_desc, i.is_unique, i.is_primary_key
ORDER BY i.name;

PRINT '';
PRINT '2.2 Missing index recommendations from SQL Server:';
SELECT 
    mig.index_group_handle,
    mid.statement AS TableName,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns,
    migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) AS ImprovementMeasure
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE mid.database_id = DB_ID()
ORDER BY ImprovementMeasure DESC;

GO

-- ============================================================================
-- SECTION 3: CREATE OPTIMIZED INDEXES
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 3: CREATE OPTIMIZED INDEXES';
PRINT '----------------------------------------------------------------------------';

-- Index 1: For state/grade/status aggregations
PRINT '3.1 Creating index for state/grade/status aggregations...';
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoanStats_State_Grade_Status' AND object_id = OBJECT_ID('dbo.LoanStats'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_LoanStats_State_Grade_Status]
    ON [dbo].[LoanStats] ([addr_state], [grade], [loan_status])
    INCLUDE ([loan_amnt], [int_rate], [annual_inc], [dti], [is_bad]);
    PRINT '   Index IX_LoanStats_State_Grade_Status created successfully';
END
ELSE
    PRINT '   Index IX_LoanStats_State_Grade_Status already exists';

-- Index 2: For time-based trend analysis
PRINT '3.2 Creating index for time-based trend analysis...';
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoanStats_IssueDate_Purpose' AND object_id = OBJECT_ID('dbo.LoanStats'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_LoanStats_IssueDate_Purpose]
    ON [dbo].[LoanStats] ([issue_d], [purpose], [verification_status])
    INCLUDE ([loan_amnt], [int_rate], [total_pymnt], [total_rec_prncp], [total_rec_int], [recoveries], [is_bad]);
    PRINT '   Index IX_LoanStats_IssueDate_Purpose created successfully';
END
ELSE
    PRINT '   Index IX_LoanStats_IssueDate_Purpose already exists';

-- Index 3: For high-risk borrower identification
PRINT '3.3 Creating index for high-risk borrower queries...';
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoanStats_RiskFactors' AND object_id = OBJECT_ID('dbo.LoanStats'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_LoanStats_RiskFactors]
    ON [dbo].[LoanStats] ([dti], [int_rate], [annual_inc], [loan_amnt])
    INCLUDE ([member_id], [grade], [loan_status], [delinq_2yrs], [pub_rec], [revol_util], [is_bad]);
    PRINT '   Index IX_LoanStats_RiskFactors created successfully';
END
ELSE
    PRINT '   Index IX_LoanStats_RiskFactors already exists';

-- Index 4: For is_bad classification queries (ML scoring)
PRINT '3.4 Creating index for ML scoring queries...';
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoanStats_Scoring' AND object_id = OBJECT_ID('dbo.LoanStats'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_LoanStats_Scoring]
    ON [dbo].[LoanStats] ([id])
    INCLUDE ([revol_util], [int_rate], [mths_since_last_record], [annual_inc_joint], [dti_joint], [total_rec_prncp], [all_util], [is_bad]);
    PRINT '   Index IX_LoanStats_Scoring created successfully';
END
ELSE
    PRINT '   Index IX_LoanStats_Scoring already exists';

-- Index 5: For member_id lookups
PRINT '3.5 Creating index for member lookups...';
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoanStats_MemberId' AND object_id = OBJECT_ID('dbo.LoanStats'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_LoanStats_MemberId]
    ON [dbo].[LoanStats] ([member_id])
    INCLUDE ([loan_amnt], [int_rate], [loan_status], [grade]);
    PRINT '   Index IX_LoanStats_MemberId created successfully';
END
ELSE
    PRINT '   Index IX_LoanStats_MemberId already exists';

PRINT '';
PRINT 'All indexes created successfully';
GO

-- ============================================================================
-- SECTION 4: RE-RUN QUERIES WITH NEW INDEXES
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 4: OPTIMIZED QUERY PERFORMANCE';
PRINT '----------------------------------------------------------------------------';

-- Clear cache again for fair comparison
DBCC FREEPROCCACHE;
DBCC DROPCLEANBUFFERS;
GO

-- Re-run Query 1 with new indexes
DECLARE @StartTime4 DATETIME = GETDATE();
DECLARE @EndTime4 DATETIME;
DECLARE @Duration4 INT;

PRINT '';
PRINT '4.1 OPTIMIZED QUERY #1: Complex Loan Risk Analysis by State and Grade';
PRINT '';

SELECT 
    addr_state,
    grade,
    loan_status,
    COUNT(*) AS LoanCount,
    SUM(loan_amnt) AS TotalLoanAmount,
    AVG(int_rate) AS AvgInterestRate,
    AVG(annual_inc) AS AvgAnnualIncome,
    AVG(dti) AS AvgDTI,
    SUM(CASE WHEN is_bad = 1 THEN 1 ELSE 0 END) AS BadLoans,
    CAST(100.0 * SUM(CASE WHEN is_bad = 1 THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS BadLoanPercentage
FROM [dbo].[LoanStats]
WHERE loan_amnt IS NOT NULL
  AND int_rate IS NOT NULL
  AND annual_inc IS NOT NULL
GROUP BY addr_state, grade, loan_status
ORDER BY addr_state, grade, loan_status;

SET @EndTime4 = GETDATE();
SET @Duration4 = DATEDIFF(MILLISECOND, @StartTime4, @EndTime4);
PRINT 'Optimized Query 1 Duration: ' + CAST(@Duration4 AS VARCHAR(20)) + ' ms';

INSERT INTO [dbo].[RunTimeStats] ([SessionID], [RunTime], [Operation], [Duration_ms], [QueryText])
VALUES (@@SPID, GETDATE(), 'Query1_Optimized', @Duration4, 'Complex Loan Risk Analysis by State and Grade - Optimized');

GO

-- Re-run Query 2 with new indexes
DECLARE @StartTime5 DATETIME = GETDATE();
DECLARE @EndTime5 DATETIME;
DECLARE @Duration5 INT;

PRINT '';
PRINT '4.2 OPTIMIZED QUERY #2: Loan Performance Trend Analysis';
PRINT '';

SELECT 
    SUBSTRING(issue_d, 1, 3) AS IssueMonth,
    RIGHT(issue_d, 4) AS IssueYear,
    purpose,
    verification_status,
    COUNT(*) AS LoanCount,
    SUM(loan_amnt) AS TotalFunded,
    AVG(int_rate) AS AvgRate,
    SUM(total_pymnt) AS TotalPayments,
    SUM(total_rec_prncp) AS TotalPrincipalReceived,
    SUM(total_rec_int) AS TotalInterestReceived,
    SUM(recoveries) AS TotalRecoveries,
    AVG(CASE WHEN is_bad = 1 THEN int_rate ELSE NULL END) AS AvgRateBadLoans,
    AVG(CASE WHEN is_bad = 0 THEN int_rate ELSE NULL END) AS AvgRateGoodLoans
FROM [dbo].[LoanStats]
WHERE issue_d IS NOT NULL
GROUP BY SUBSTRING(issue_d, 1, 3), RIGHT(issue_d, 4), purpose, verification_status
ORDER BY RIGHT(issue_d, 4), SUBSTRING(issue_d, 1, 3), purpose;

SET @EndTime5 = GETDATE();
SET @Duration5 = DATEDIFF(MILLISECOND, @StartTime5, @EndTime5);
PRINT 'Optimized Query 2 Duration: ' + CAST(@Duration5 AS VARCHAR(20)) + ' ms';

INSERT INTO [dbo].[RunTimeStats] ([SessionID], [RunTime], [Operation], [Duration_ms], [QueryText])
VALUES (@@SPID, GETDATE(), 'Query2_Optimized', @Duration5, 'Loan Performance Trend Analysis - Optimized');

GO

-- Re-run Query 3 with new indexes
DECLARE @StartTime6 DATETIME = GETDATE();
DECLARE @EndTime6 DATETIME;
DECLARE @Duration6 INT;

PRINT '';
PRINT '4.3 OPTIMIZED QUERY #3: High-Risk Borrower Identification';
PRINT '';

SELECT 
    id,
    member_id,
    loan_amnt,
    int_rate,
    annual_inc,
    dti,
    grade,
    loan_status,
    delinq_2yrs,
    pub_rec,
    revol_util,
    is_bad
FROM [dbo].[LoanStats]
WHERE (dti > 30 OR int_rate > 20 OR delinq_2yrs > 2)
  AND annual_inc < 50000
  AND loan_amnt > 10000
ORDER BY int_rate DESC, dti DESC;

SET @EndTime6 = GETDATE();
SET @Duration6 = DATEDIFF(MILLISECOND, @StartTime6, @EndTime6);
PRINT 'Optimized Query 3 Duration: ' + CAST(@Duration6 AS VARCHAR(20)) + ' ms';

INSERT INTO [dbo].[RunTimeStats] ([SessionID], [RunTime], [Operation], [Duration_ms], [QueryText])
VALUES (@@SPID, GETDATE(), 'Query3_Optimized', @Duration6, 'High-Risk Borrower Identification - Optimized');

GO

-- ============================================================================
-- SECTION 5: PERFORMANCE COMPARISON SUMMARY
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 5: PERFORMANCE COMPARISON SUMMARY';
PRINT '----------------------------------------------------------------------------';

PRINT '';
PRINT '5.1 Query Performance Before vs After Optimization:';

SELECT 
    CASE 
        WHEN Operation LIKE '%Baseline' THEN 'Before Optimization'
        ELSE 'After Optimization'
    END AS Phase,
    CASE 
        WHEN Operation LIKE 'Query1%' THEN 'Query 1: State/Grade Analysis'
        WHEN Operation LIKE 'Query2%' THEN 'Query 2: Trend Analysis'
        WHEN Operation LIKE 'Query3%' THEN 'Query 3: Risk Identification'
    END AS QueryName,
    Duration_ms AS DurationMs,
    RunTime
FROM [dbo].[RunTimeStats]
WHERE Operation LIKE 'Query%'
ORDER BY 
    CASE WHEN Operation LIKE 'Query1%' THEN 1 WHEN Operation LIKE 'Query2%' THEN 2 ELSE 3 END,
    CASE WHEN Operation LIKE '%Baseline' THEN 1 ELSE 2 END;

PRINT '';
PRINT '5.2 Index Usage Statistics:';

SELECT 
    OBJECT_NAME(s.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    s.user_seeks AS UserSeeks,
    s.user_scans AS UserScans,
    s.user_lookups AS UserLookups,
    s.user_updates AS UserUpdates,
    s.last_user_seek AS LastSeek,
    s.last_user_scan AS LastScan
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
  AND OBJECT_NAME(s.object_id) = 'LoanStats'
ORDER BY s.user_seeks + s.user_scans DESC;

PRINT '';
PRINT '5.3 Current Index Structure:';

SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    CAST(ps.used_page_count * 8.0 / 1024 AS DECIMAL(10,2)) AS IndexSizeMB,
    ps.row_count AS RowCount
FROM sys.indexes i
INNER JOIN sys.dm_db_partition_stats ps ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE i.object_id = OBJECT_ID('dbo.LoanStats')
ORDER BY ps.used_page_count DESC;

GO

-- ============================================================================
-- SECTION 6: QUERY REWRITE RECOMMENDATIONS
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 6: QUERY REWRITE RECOMMENDATIONS';
PRINT '----------------------------------------------------------------------------';

PRINT '';
PRINT '6.1 Original vs Optimized Query Pattern Examples:';
PRINT '';
PRINT 'RECOMMENDATION 1: Use filtered indexes for common WHERE clauses';
PRINT '   Original:  SELECT ... WHERE is_bad = 1';
PRINT '   Optimized: Create filtered index: CREATE INDEX IX_BadLoans ON LoanStats(id) WHERE is_bad = 1';
PRINT '';
PRINT 'RECOMMENDATION 2: Avoid functions on indexed columns in WHERE clause';
PRINT '   Original:  WHERE YEAR(issue_d) = 2023';
PRINT '   Optimized: WHERE issue_d >= ''2023-01-01'' AND issue_d < ''2024-01-01''';
PRINT '';
PRINT 'RECOMMENDATION 3: Use covering indexes to avoid key lookups';
PRINT '   Include frequently selected columns in the INCLUDE clause of indexes';
PRINT '';
PRINT 'RECOMMENDATION 4: Consider columnstore indexes for analytics workloads';
PRINT '   The existing ncci_LoanStats columnstore index is ideal for aggregation queries';
PRINT '';

-- Create a filtered index for bad loans (common query pattern)
PRINT '6.2 Creating filtered index for bad loans analysis...';
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_LoanStats_BadLoans_Filtered' AND object_id = OBJECT_ID('dbo.LoanStats'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_LoanStats_BadLoans_Filtered]
    ON [dbo].[LoanStats] ([grade], [addr_state])
    INCLUDE ([loan_amnt], [int_rate], [annual_inc])
    WHERE is_bad = 1;
    PRINT '   Filtered index IX_LoanStats_BadLoans_Filtered created successfully';
END
ELSE
    PRINT '   Filtered index IX_LoanStats_BadLoans_Filtered already exists';

GO

-- ============================================================================
-- SECTION 7: EXECUTION PLAN ANALYSIS QUERIES
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 7: EXECUTION PLAN ANALYSIS';
PRINT '----------------------------------------------------------------------------';

PRINT '';
PRINT '7.1 To view execution plans, run these queries in SSMS with:';
PRINT '    SET SHOWPLAN_XML ON or SET SHOWPLAN_TEXT ON';
PRINT '';
PRINT '7.2 Key metrics to look for in execution plans:';
PRINT '    - Table Scan vs Index Seek (prefer Index Seek)';
PRINT '    - Key Lookups (minimize with covering indexes)';
PRINT '    - Sort operations (can be expensive for large datasets)';
PRINT '    - Hash Match vs Nested Loops (depends on data size)';
PRINT '    - Estimated vs Actual rows (large differences indicate stale statistics)';
PRINT '';

-- Update statistics for accurate execution plans
PRINT '7.3 Updating statistics for accurate query optimization...';
UPDATE STATISTICS [dbo].[LoanStats];
PRINT '   Statistics updated successfully';

GO

PRINT '';
PRINT '============================================================================';
PRINT 'QUERY OPTIMIZATION ANALYSIS COMPLETE';
PRINT '============================================================================';

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
