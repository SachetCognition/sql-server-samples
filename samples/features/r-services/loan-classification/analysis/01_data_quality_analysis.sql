-- ============================================================================
-- LendingClub Database - Data Quality Analysis
-- ============================================================================
-- This script performs comprehensive data quality checks on the LendingClub
-- database including uniqueness, null checks, referential integrity, and
-- freshness analysis.
-- ============================================================================

USE [LendingClub]
GO

SET NOCOUNT ON;

PRINT '============================================================================';
PRINT 'LENDINGCLUB DATABASE - DATA QUALITY ANALYSIS REPORT';
PRINT 'Generated: ' + CONVERT(VARCHAR(30), GETDATE(), 120);
PRINT '============================================================================';
PRINT '';

-- ============================================================================
-- SECTION 1: TABLE OVERVIEW AND ROW COUNTS
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 1: TABLE OVERVIEW AND ROW COUNTS';
PRINT '----------------------------------------------------------------------------';

SELECT 
    t.name AS TableName,
    p.rows AS [RowCount],
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS DECIMAL(18,2)) AS TotalSpaceMB,
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS DECIMAL(18,2)) AS UsedSpaceMB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS DECIMAL(18,2)) AS UnusedSpaceMB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.is_ms_shipped = 0
GROUP BY t.name, p.rows
ORDER BY p.rows DESC;

PRINT '';

-- ============================================================================
-- SECTION 2: PRIMARY KEY AND UNIQUENESS CHECKS
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 2: PRIMARY KEY AND UNIQUENESS CHECKS';
PRINT '----------------------------------------------------------------------------';

-- Check for duplicate IDs in LoanStats (should be 0 - PK constraint)
PRINT '2.1 Checking for duplicate IDs in LoanStats table...';
SELECT 
    'LoanStats.id' AS ColumnChecked,
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT id) AS UniqueValues,
    COUNT(*) - COUNT(DISTINCT id) AS DuplicateCount,
    CASE WHEN COUNT(*) = COUNT(DISTINCT id) THEN 'PASS' ELSE 'FAIL' END AS Status
FROM [dbo].[LoanStats];

-- Check for duplicate member_ids (business key - may have duplicates)
PRINT '2.2 Checking member_id uniqueness in LoanStats...';
SELECT 
    'LoanStats.member_id' AS ColumnChecked,
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT member_id) AS UniqueValues,
    COUNT(*) - COUNT(DISTINCT member_id) AS DuplicateCount,
    CASE WHEN COUNT(*) - COUNT(DISTINCT member_id) > 1000 THEN 'WARNING - High duplicates' 
         WHEN COUNT(*) - COUNT(DISTINCT member_id) > 0 THEN 'INFO - Some duplicates exist'
         ELSE 'PASS' END AS Status
FROM [dbo].[LoanStats];

-- Show top duplicate member_ids
PRINT '2.3 Top 10 most duplicated member_ids:';
SELECT TOP 10
    member_id,
    COUNT(*) AS OccurrenceCount
FROM [dbo].[LoanStats]
GROUP BY member_id
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

-- Check uniqueness in staging table
PRINT '2.4 Checking uniqueness in LoanStatsStaging...';
SELECT 
    'LoanStatsStaging.id' AS ColumnChecked,
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT id) AS UniqueValues,
    COUNT(*) - COUNT(DISTINCT id) AS DuplicateCount,
    CASE WHEN COUNT(*) = COUNT(DISTINCT id) THEN 'PASS' ELSE 'FAIL' END AS Status
FROM [dbo].[LoanStatsStaging];

-- Check uniqueness in predictions table
PRINT '2.5 Checking uniqueness in LoanStatsPredictions...';
SELECT 
    'LoanStatsPredictions.id' AS ColumnChecked,
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT id) AS UniqueValues,
    COUNT(*) - COUNT(DISTINCT id) AS DuplicateCount,
    CASE WHEN COUNT(*) = COUNT(DISTINCT id) THEN 'PASS' ELSE 'WARNING - Duplicates exist' END AS Status
FROM [dbo].[LoanStatsPredictions];

PRINT '';

-- ============================================================================
-- SECTION 3: NULL VALUE ANALYSIS
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 3: NULL VALUE ANALYSIS';
PRINT '----------------------------------------------------------------------------';

-- Critical fields null check
PRINT '3.1 Null analysis for critical financial fields:';
SELECT 
    'loan_amnt' AS ColumnName,
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN loan_amnt IS NULL THEN 1 ELSE 0 END) AS NullCount,
    CAST(100.0 * SUM(CASE WHEN loan_amnt IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS NullPercentage,
    CASE WHEN SUM(CASE WHEN loan_amnt IS NULL THEN 1 ELSE 0 END) > 0 THEN 'FAIL - Critical field has NULLs' ELSE 'PASS' END AS Status
FROM [dbo].[LoanStats]
UNION ALL
SELECT 
    'int_rate',
    COUNT(*),
    SUM(CASE WHEN int_rate IS NULL THEN 1 ELSE 0 END),
    CAST(100.0 * SUM(CASE WHEN int_rate IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)),
    CASE WHEN SUM(CASE WHEN int_rate IS NULL THEN 1 ELSE 0 END) > 0 THEN 'FAIL - Critical field has NULLs' ELSE 'PASS' END
FROM [dbo].[LoanStats]
UNION ALL
SELECT 
    'annual_inc',
    COUNT(*),
    SUM(CASE WHEN annual_inc IS NULL THEN 1 ELSE 0 END),
    CAST(100.0 * SUM(CASE WHEN annual_inc IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)),
    CASE WHEN SUM(CASE WHEN annual_inc IS NULL THEN 1 ELSE 0 END) > 0 THEN 'WARNING - Income has NULLs' ELSE 'PASS' END
FROM [dbo].[LoanStats]
UNION ALL
SELECT 
    'installment',
    COUNT(*),
    SUM(CASE WHEN installment IS NULL THEN 1 ELSE 0 END),
    CAST(100.0 * SUM(CASE WHEN installment IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)),
    CASE WHEN SUM(CASE WHEN installment IS NULL THEN 1 ELSE 0 END) > 0 THEN 'FAIL - Critical field has NULLs' ELSE 'PASS' END
FROM [dbo].[LoanStats]
UNION ALL
SELECT 
    'dti',
    COUNT(*),
    SUM(CASE WHEN dti IS NULL THEN 1 ELSE 0 END),
    CAST(100.0 * SUM(CASE WHEN dti IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)),
    CASE WHEN SUM(CASE WHEN dti IS NULL THEN 1 ELSE 0 END) > 0 THEN 'WARNING - DTI has NULLs' ELSE 'PASS' END
FROM [dbo].[LoanStats]
UNION ALL
SELECT 
    'loan_status',
    COUNT(*),
    SUM(CASE WHEN loan_status IS NULL THEN 1 ELSE 0 END),
    CAST(100.0 * SUM(CASE WHEN loan_status IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)),
    CASE WHEN SUM(CASE WHEN loan_status IS NULL THEN 1 ELSE 0 END) > 0 THEN 'FAIL - Critical field has NULLs' ELSE 'PASS' END
FROM [dbo].[LoanStats]
UNION ALL
SELECT 
    'grade',
    COUNT(*),
    SUM(CASE WHEN grade IS NULL THEN 1 ELSE 0 END),
    CAST(100.0 * SUM(CASE WHEN grade IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)),
    CASE WHEN SUM(CASE WHEN grade IS NULL THEN 1 ELSE 0 END) > 0 THEN 'WARNING - Grade has NULLs' ELSE 'PASS' END
FROM [dbo].[LoanStats];

-- Comprehensive null analysis for all columns
PRINT '3.2 Complete null analysis for LoanStats table:';
SELECT 
    'member_id' AS ColumnName, SUM(CASE WHEN member_id IS NULL THEN 1 ELSE 0 END) AS NullCount FROM [dbo].[LoanStats]
UNION ALL SELECT 'funded_amnt', SUM(CASE WHEN funded_amnt IS NULL THEN 1 ELSE 0 END) FROM [dbo].[LoanStats]
UNION ALL SELECT 'funded_amnt_inv', SUM(CASE WHEN funded_amnt_inv IS NULL THEN 1 ELSE 0 END) FROM [dbo].[LoanStats]
UNION ALL SELECT 'term', SUM(CASE WHEN term IS NULL THEN 1 ELSE 0 END) FROM [dbo].[LoanStats]
UNION ALL SELECT 'sub_grade', SUM(CASE WHEN sub_grade IS NULL THEN 1 ELSE 0 END) FROM [dbo].[LoanStats]
UNION ALL SELECT 'emp_title', SUM(CASE WHEN emp_title IS NULL THEN 1 ELSE 0 END) FROM [dbo].[LoanStats]
UNION ALL SELECT 'emp_length', SUM(CASE WHEN emp_length IS NULL THEN 1 ELSE 0 END) FROM [dbo].[LoanStats]
UNION ALL SELECT 'home_ownership', SUM(CASE WHEN home_ownership IS NULL THEN 1 ELSE 0 END) FROM [dbo].[LoanStats]
UNION ALL SELECT 'verification_status', SUM(CASE WHEN verification_status IS NULL THEN 1 ELSE 0 END) FROM [dbo].[LoanStats]
UNION ALL SELECT 'purpose', SUM(CASE WHEN purpose IS NULL THEN 1 ELSE 0 END) FROM [dbo].[LoanStats]
UNION ALL SELECT 'addr_state', SUM(CASE WHEN addr_state IS NULL THEN 1 ELSE 0 END) FROM [dbo].[LoanStats]
UNION ALL SELECT 'is_bad', SUM(CASE WHEN is_bad IS NULL THEN 1 ELSE 0 END) FROM [dbo].[LoanStats]
ORDER BY NullCount DESC;

PRINT '';

-- ============================================================================
-- SECTION 4: DATA RANGE AND OUTLIER ANALYSIS
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 4: DATA RANGE AND OUTLIER ANALYSIS';
PRINT '----------------------------------------------------------------------------';

-- Loan amount statistics
PRINT '4.1 Loan amount statistics:';
SELECT 
    'loan_amnt' AS Metric,
    MIN(loan_amnt) AS MinValue,
    MAX(loan_amnt) AS MaxValue,
    AVG(loan_amnt) AS AvgValue,
    STDEV(loan_amnt) AS StdDev,
    COUNT(CASE WHEN loan_amnt < 1000 THEN 1 END) AS BelowMin,
    COUNT(CASE WHEN loan_amnt > 40000 THEN 1 END) AS AboveMax,
    CASE WHEN MIN(loan_amnt) < 0 OR MAX(loan_amnt) > 100000 THEN 'WARNING - Outliers detected' ELSE 'PASS' END AS Status
FROM [dbo].[LoanStats]
WHERE loan_amnt IS NOT NULL;

-- Interest rate statistics
PRINT '4.2 Interest rate statistics:';
SELECT 
    'int_rate' AS Metric,
    MIN(int_rate) AS MinValue,
    MAX(int_rate) AS MaxValue,
    AVG(int_rate) AS AvgValue,
    STDEV(int_rate) AS StdDev,
    COUNT(CASE WHEN int_rate < 0 THEN 1 END) AS BelowZero,
    COUNT(CASE WHEN int_rate > 35 THEN 1 END) AS AboveMax,
    CASE WHEN MIN(int_rate) < 0 OR MAX(int_rate) > 50 THEN 'WARNING - Outliers detected' ELSE 'PASS' END AS Status
FROM [dbo].[LoanStats]
WHERE int_rate IS NOT NULL;

-- Annual income statistics
PRINT '4.3 Annual income statistics:';
SELECT 
    'annual_inc' AS Metric,
    MIN(annual_inc) AS MinValue,
    MAX(annual_inc) AS MaxValue,
    AVG(annual_inc) AS AvgValue,
    STDEV(annual_inc) AS StdDev,
    COUNT(CASE WHEN annual_inc < 10000 THEN 1 END) AS VeryLowIncome,
    COUNT(CASE WHEN annual_inc > 1000000 THEN 1 END) AS VeryHighIncome,
    CASE WHEN MAX(annual_inc) > 5000000 THEN 'WARNING - Extreme outliers detected' ELSE 'PASS' END AS Status
FROM [dbo].[LoanStats]
WHERE annual_inc IS NOT NULL;

-- DTI statistics
PRINT '4.4 DTI (Debt-to-Income) statistics:';
SELECT 
    'dti' AS Metric,
    MIN(dti) AS MinValue,
    MAX(dti) AS MaxValue,
    AVG(dti) AS AvgValue,
    STDEV(dti) AS StdDev,
    COUNT(CASE WHEN dti < 0 THEN 1 END) AS NegativeValues,
    COUNT(CASE WHEN dti > 100 THEN 1 END) AS Above100,
    CASE WHEN MIN(dti) < 0 OR MAX(dti) > 200 THEN 'WARNING - Outliers detected' ELSE 'PASS' END AS Status
FROM [dbo].[LoanStats]
WHERE dti IS NOT NULL;

-- Identify specific outlier records
PRINT '4.5 Records with extreme outlier values:';
SELECT TOP 20
    id,
    loan_amnt,
    int_rate,
    annual_inc,
    dti,
    loan_status,
    'Potential outlier' AS Flag
FROM [dbo].[LoanStats]
WHERE annual_inc > 1000000 
   OR dti > 100 
   OR int_rate > 35
   OR loan_amnt > 50000
ORDER BY annual_inc DESC;

PRINT '';

-- ============================================================================
-- SECTION 5: CATEGORICAL DATA VALIDATION
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 5: CATEGORICAL DATA VALIDATION';
PRINT '----------------------------------------------------------------------------';

-- Grade distribution
PRINT '5.1 Grade distribution:';
SELECT 
    grade,
    COUNT(*) AS Count,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS Percentage
FROM [dbo].[LoanStats]
GROUP BY grade
ORDER BY grade;

-- Loan status distribution
PRINT '5.2 Loan status distribution:';
SELECT 
    loan_status,
    COUNT(*) AS Count,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS Percentage
FROM [dbo].[LoanStats]
GROUP BY loan_status
ORDER BY COUNT(*) DESC;

-- Home ownership distribution
PRINT '5.3 Home ownership distribution:';
SELECT 
    home_ownership,
    COUNT(*) AS Count,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS Percentage
FROM [dbo].[LoanStats]
GROUP BY home_ownership
ORDER BY COUNT(*) DESC;

-- Verification status distribution
PRINT '5.4 Verification status distribution:';
SELECT 
    verification_status,
    COUNT(*) AS Count,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS Percentage
FROM [dbo].[LoanStats]
GROUP BY verification_status
ORDER BY COUNT(*) DESC;

-- Term distribution
PRINT '5.5 Term distribution:';
SELECT 
    term,
    COUNT(*) AS Count,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS Percentage
FROM [dbo].[LoanStats]
GROUP BY term
ORDER BY term;

-- State distribution (top 10)
PRINT '5.6 Top 10 states by loan count:';
SELECT TOP 10
    addr_state,
    COUNT(*) AS Count,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS Percentage
FROM [dbo].[LoanStats]
GROUP BY addr_state
ORDER BY COUNT(*) DESC;

PRINT '';

-- ============================================================================
-- SECTION 6: REFERENTIAL INTEGRITY CHECKS
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 6: REFERENTIAL INTEGRITY CHECKS';
PRINT '----------------------------------------------------------------------------';

-- Check staging to production relationship
PRINT '6.1 Staging table records not in production (orphaned staging records):';
SELECT 
    COUNT(*) AS OrphanedStagingRecords,
    CASE WHEN COUNT(*) > 0 THEN 'INFO - Staging has unprocessed records' ELSE 'PASS' END AS Status
FROM [dbo].[LoanStatsStaging] s
WHERE NOT EXISTS (
    SELECT 1 FROM [dbo].[LoanStats] l 
    WHERE l.member_id = s.member_id
);

-- Check predictions to loans relationship
PRINT '6.2 Predictions referencing non-existent loans:';
SELECT 
    COUNT(*) AS OrphanedPredictions,
    CASE WHEN COUNT(*) > 0 THEN 'FAIL - Orphaned predictions exist' ELSE 'PASS' END AS Status
FROM [dbo].[LoanStatsPredictions] p
WHERE NOT EXISTS (
    SELECT 1 FROM [dbo].[LoanStats] l 
    WHERE l.id = p.id
);

-- Check WhatIf predictions to loans relationship
PRINT '6.3 WhatIf predictions referencing non-existent loans:';
SELECT 
    COUNT(*) AS OrphanedWhatIfPredictions,
    CASE WHEN COUNT(*) > 0 THEN 'FAIL - Orphaned WhatIf predictions exist' ELSE 'PASS' END AS Status
FROM [dbo].[LoanPredictionsWhatIf] w
WHERE NOT EXISTS (
    SELECT 1 FROM [dbo].[LoanStats] l 
    WHERE l.id = w.id
);

-- Check loans without predictions (coverage analysis)
PRINT '6.4 Loans without predictions (prediction coverage):';
SELECT 
    COUNT(*) AS LoansWithoutPredictions,
    (SELECT COUNT(*) FROM [dbo].[LoanStats]) AS TotalLoans,
    CAST(100.0 * COUNT(*) / (SELECT COUNT(*) FROM [dbo].[LoanStats]) AS DECIMAL(5,2)) AS UncoveredPercentage
FROM [dbo].[LoanStats] l
WHERE NOT EXISTS (
    SELECT 1 FROM [dbo].[LoanStatsPredictions] p 
    WHERE p.id = l.id
);

PRINT '';

-- ============================================================================
-- SECTION 7: DATA FRESHNESS ANALYSIS
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 7: DATA FRESHNESS ANALYSIS';
PRINT '----------------------------------------------------------------------------';

-- Last data load information
PRINT '7.1 Data load history:';
SELECT 
    load_id,
    source_file,
    load_start_time,
    load_end_time,
    DATEDIFF(MINUTE, load_start_time, load_end_time) AS LoadDurationMinutes,
    rows_loaded,
    status
FROM [dbo].[DataLoadHistory]
ORDER BY load_start_time DESC;

-- Most recent data in LoanStats
PRINT '7.2 Data freshness in LoanStats:';
SELECT 
    'LoanStats' AS TableName,
    MAX(created_at) AS MostRecentRecord,
    MIN(created_at) AS OldestRecord,
    DATEDIFF(DAY, MAX(created_at), GETDATE()) AS DaysSinceLastRecord,
    CASE 
        WHEN DATEDIFF(DAY, MAX(created_at), GETDATE()) > 7 THEN 'WARNING - Data may be stale'
        WHEN DATEDIFF(DAY, MAX(created_at), GETDATE()) > 30 THEN 'FAIL - Data is stale'
        ELSE 'PASS'
    END AS FreshnessStatus
FROM [dbo].[LoanStats];

-- Runtime stats freshness
PRINT '7.3 Runtime stats freshness:';
SELECT 
    'RunTimeStats' AS TableName,
    MAX(RunTime) AS MostRecentOperation,
    DATEDIFF(HOUR, MAX(RunTime), GETDATE()) AS HoursSinceLastOperation,
    CASE 
        WHEN DATEDIFF(HOUR, MAX(RunTime), GETDATE()) > 24 THEN 'WARNING - No recent operations'
        ELSE 'PASS'
    END AS Status
FROM [dbo].[RunTimeStats];

-- Predictions freshness
PRINT '7.4 Predictions freshness:';
SELECT 
    'LoanStatsPredictions' AS TableName,
    MAX(prediction_date) AS MostRecentPrediction,
    DATEDIFF(HOUR, MAX(prediction_date), GETDATE()) AS HoursSinceLastPrediction,
    CASE 
        WHEN DATEDIFF(HOUR, MAX(prediction_date), GETDATE()) > 24 THEN 'WARNING - Predictions may be stale'
        ELSE 'PASS'
    END AS Status
FROM [dbo].[LoanStatsPredictions];

PRINT '';

-- ============================================================================
-- SECTION 8: DATA CONSISTENCY CHECKS
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 8: DATA CONSISTENCY CHECKS';
PRINT '----------------------------------------------------------------------------';

-- Check is_bad flag consistency with loan_status
PRINT '8.1 is_bad flag consistency with loan_status:';
SELECT 
    loan_status,
    is_bad,
    COUNT(*) AS Count,
    CASE 
        WHEN loan_status IN ('Late (16-30 days)', 'Late (31-120 days)', 'Default', 'Charged Off') AND is_bad = 0 THEN 'INCONSISTENT'
        WHEN loan_status NOT IN ('Late (16-30 days)', 'Late (31-120 days)', 'Default', 'Charged Off') AND is_bad = 1 THEN 'INCONSISTENT'
        ELSE 'CONSISTENT'
    END AS ConsistencyStatus
FROM [dbo].[LoanStats]
GROUP BY loan_status, is_bad
ORDER BY loan_status;

-- Check funded_amnt vs loan_amnt consistency
PRINT '8.2 Funded amount vs loan amount consistency:';
SELECT 
    COUNT(*) AS TotalRecords,
    SUM(CASE WHEN funded_amnt > loan_amnt THEN 1 ELSE 0 END) AS FundedExceedsLoan,
    SUM(CASE WHEN funded_amnt < loan_amnt * 0.5 THEN 1 ELSE 0 END) AS FundedLessThanHalf,
    CASE 
        WHEN SUM(CASE WHEN funded_amnt > loan_amnt THEN 1 ELSE 0 END) > 0 THEN 'WARNING - Some funded amounts exceed loan amounts'
        ELSE 'PASS'
    END AS Status
FROM [dbo].[LoanStats]
WHERE loan_amnt IS NOT NULL AND funded_amnt IS NOT NULL;

-- Check grade vs sub_grade consistency
PRINT '8.3 Grade vs sub_grade consistency:';
SELECT 
    grade,
    sub_grade,
    COUNT(*) AS Count,
    CASE 
        WHEN LEFT(sub_grade, 1) != grade THEN 'INCONSISTENT'
        ELSE 'CONSISTENT'
    END AS ConsistencyStatus
FROM [dbo].[LoanStats]
WHERE grade IS NOT NULL AND sub_grade IS NOT NULL
GROUP BY grade, sub_grade
HAVING LEFT(sub_grade, 1) != grade
ORDER BY grade;

PRINT '';

-- ============================================================================
-- SECTION 9: DATA QUALITY SUMMARY
-- ============================================================================
PRINT '----------------------------------------------------------------------------';
PRINT 'SECTION 9: DATA QUALITY SUMMARY';
PRINT '----------------------------------------------------------------------------';

-- Overall data quality score
PRINT '9.1 Overall Data Quality Metrics:';
SELECT 
    (SELECT COUNT(*) FROM [dbo].[LoanStats]) AS TotalRecords,
    (SELECT COUNT(*) FROM [dbo].[LoanStats] WHERE loan_amnt IS NULL) AS NullLoanAmounts,
    (SELECT COUNT(*) FROM [dbo].[LoanStats] WHERE int_rate IS NULL) AS NullInterestRates,
    (SELECT COUNT(*) FROM [dbo].[LoanStats] WHERE annual_inc IS NULL) AS NullAnnualIncome,
    (SELECT COUNT(*) - COUNT(DISTINCT member_id) FROM [dbo].[LoanStats]) AS DuplicateMemberIds,
    (SELECT COUNT(*) FROM [dbo].[LoanStats] WHERE annual_inc > 1000000) AS ExtremeIncomeOutliers,
    (SELECT COUNT(*) FROM [dbo].[LoanStats] WHERE dti > 100) AS ExtremeDTIOutliers;

-- Data quality issues summary
PRINT '9.2 Data Quality Issues Summary:';
SELECT 
    'NULL loan_amnt' AS Issue,
    COUNT(*) AS AffectedRecords,
    'HIGH' AS Severity
FROM [dbo].[LoanStats] WHERE loan_amnt IS NULL
UNION ALL
SELECT 'NULL int_rate', COUNT(*), 'HIGH' FROM [dbo].[LoanStats] WHERE int_rate IS NULL
UNION ALL
SELECT 'NULL annual_inc', COUNT(*), 'MEDIUM' FROM [dbo].[LoanStats] WHERE annual_inc IS NULL
UNION ALL
SELECT 'Duplicate member_id', COUNT(*) - COUNT(DISTINCT member_id), 'LOW' FROM [dbo].[LoanStats]
UNION ALL
SELECT 'Extreme income outliers (>$1M)', COUNT(*), 'MEDIUM' FROM [dbo].[LoanStats] WHERE annual_inc > 1000000
UNION ALL
SELECT 'Extreme DTI outliers (>100)', COUNT(*), 'MEDIUM' FROM [dbo].[LoanStats] WHERE dti > 100
ORDER BY Severity;

PRINT '';
PRINT '============================================================================';
PRINT 'DATA QUALITY ANALYSIS COMPLETE';
PRINT '============================================================================';
GO
