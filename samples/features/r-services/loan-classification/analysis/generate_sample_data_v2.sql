-- Generate Sample Data for LendingClub Database (Fixed Version)
-- Creates ~100,000 realistic loan records for analysis

USE [LendingClub]
GO

SET NOCOUNT ON;

-- Clear existing data
TRUNCATE TABLE [dbo].[LoanStats];
TRUNCATE TABLE [dbo].[LoanStatsStaging];
TRUNCATE TABLE [dbo].[LoanStatsPredictions];
TRUNCATE TABLE [dbo].[LoanPredictionsWhatIf];
TRUNCATE TABLE [dbo].[RunTimeStats];
DELETE FROM [dbo].[DataLoadHistory];
GO

PRINT 'Starting data generation...';

-- Generate data in batches using a numbers table approach
DECLARE @i INT = 1;
DECLARE @BatchSize INT = 10000;
DECLARE @TotalRecords INT = 100000;

WHILE @i <= @TotalRecords
BEGIN
    INSERT INTO [dbo].[LoanStats] (
        [member_id], [loan_amnt], [funded_amnt], [funded_amnt_inv],
        [term], [int_rate], [installment], [grade], [sub_grade],
        [emp_title], [emp_length], [home_ownership], [annual_inc],
        [verification_status], [issue_d], [loan_status], [pymnt_plan],
        [purpose], [title], [zip_code], [addr_state], [dti],
        [delinq_2yrs], [earliest_cr_line], [inq_last_6mths],
        [mths_since_last_delinq], [mths_since_last_record], [open_acc],
        [pub_rec], [revol_bal], [revol_util], [total_acc],
        [initial_list_status], [out_prncp], [out_prncp_inv],
        [total_pymnt], [total_pymnt_inv], [total_rec_prncp],
        [total_rec_int], [total_rec_late_fee], [recoveries],
        [collection_recovery_fee], [last_pymnt_d], [last_pymnt_amnt],
        [collections_12_mths_ex_med], [policy_code], [application_type],
        [annual_inc_joint], [dti_joint], [acc_now_delinq],
        [tot_coll_amt], [tot_cur_bal], [is_bad], [created_at], [updated_at]
    )
    SELECT 
        -- member_id
        ABS(CHECKSUM(NEWID())) % 90000000 + 10000000,
        -- loan_amnt
        (ABS(CHECKSUM(NEWID())) % 39 + 1) * 1000,
        -- funded_amnt
        (ABS(CHECKSUM(NEWID())) % 39 + 1) * 1000,
        -- funded_amnt_inv
        (ABS(CHECKSUM(NEWID())) % 38 + 1) * 1000,
        -- term
        CASE WHEN ABS(CHECKSUM(NEWID())) % 3 = 0 THEN '60 months' ELSE '36 months' END,
        -- int_rate
        CAST(5.0 + (ABS(CHECKSUM(NEWID())) % 2500) / 100.0 AS FLOAT),
        -- installment
        CAST(100 + (ABS(CHECKSUM(NEWID())) % 1400) AS FLOAT),
        -- grade
        CHAR(65 + ABS(CHECKSUM(NEWID())) % 7),
        -- sub_grade
        CHAR(65 + ABS(CHECKSUM(NEWID())) % 7) + CAST(ABS(CHECKSUM(NEWID())) % 5 + 1 AS CHAR(1)),
        -- emp_title
        CASE ABS(CHECKSUM(NEWID())) % 10
            WHEN 0 THEN 'Manager' WHEN 1 THEN 'Teacher' WHEN 2 THEN 'Engineer'
            WHEN 3 THEN 'Nurse' WHEN 4 THEN 'Driver' WHEN 5 THEN 'Sales'
            WHEN 6 THEN 'Analyst' WHEN 7 THEN 'Tech' WHEN 8 THEN 'Owner' ELSE NULL
        END,
        -- emp_length
        CASE ABS(CHECKSUM(NEWID())) % 12
            WHEN 0 THEN '< 1 year' WHEN 1 THEN '1 year' WHEN 2 THEN '2 years'
            WHEN 3 THEN '3 years' WHEN 4 THEN '4 years' WHEN 5 THEN '5 years'
            WHEN 6 THEN '6 years' WHEN 7 THEN '7 years' WHEN 8 THEN '8 years'
            WHEN 9 THEN '9 years' WHEN 10 THEN '10+ years' ELSE 'n/a'
        END,
        -- home_ownership
        CASE ABS(CHECKSUM(NEWID())) % 5
            WHEN 0 THEN 'RENT' WHEN 1 THEN 'MORTGAGE' WHEN 2 THEN 'OWN'
            WHEN 3 THEN 'OTHER' ELSE 'NONE'
        END,
        -- annual_inc
        CAST(20000 + (ABS(CHECKSUM(NEWID())) % 480000) AS FLOAT),
        -- verification_status
        CASE ABS(CHECKSUM(NEWID())) % 3
            WHEN 0 THEN 'Verified' WHEN 1 THEN 'Source Verified' ELSE 'Not Verified'
        END,
        -- issue_d
        FORMAT(DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 4000, '2012-01-01'), 'MMM-yyyy'),
        -- loan_status
        CASE ABS(CHECKSUM(NEWID())) % 100
            WHEN 0 THEN 'Default' WHEN 1 THEN 'Default' WHEN 2 THEN 'Default'
            WHEN 3 THEN 'Late (16-30 days)' WHEN 4 THEN 'Late (16-30 days)'
            WHEN 5 THEN 'Late (31-120 days)' WHEN 6 THEN 'Late (31-120 days)'
            WHEN 7 THEN 'Late (31-120 days)' WHEN 8 THEN 'Late (31-120 days)'
            WHEN 9 THEN 'Charged Off' WHEN 10 THEN 'Charged Off'
            WHEN 11 THEN 'Charged Off' WHEN 12 THEN 'Charged Off'
            WHEN 13 THEN 'Charged Off' WHEN 14 THEN 'Charged Off'
            WHEN 15 THEN 'In Grace Period' WHEN 16 THEN 'In Grace Period'
            WHEN 17 THEN 'Current' WHEN 18 THEN 'Current' WHEN 19 THEN 'Current'
            WHEN 20 THEN 'Current' WHEN 21 THEN 'Current' WHEN 22 THEN 'Current'
            WHEN 23 THEN 'Current' WHEN 24 THEN 'Current' WHEN 25 THEN 'Current'
            ELSE 'Fully Paid'
        END,
        -- pymnt_plan
        CASE WHEN ABS(CHECKSUM(NEWID())) % 100 < 2 THEN 'y' ELSE 'n' END,
        -- purpose
        CASE ABS(CHECKSUM(NEWID())) % 10
            WHEN 0 THEN 'debt_consolidation' WHEN 1 THEN 'credit_card'
            WHEN 2 THEN 'home_improvement' WHEN 3 THEN 'other'
            WHEN 4 THEN 'major_purchase' WHEN 5 THEN 'small_business'
            WHEN 6 THEN 'car' WHEN 7 THEN 'medical' WHEN 8 THEN 'moving'
            ELSE 'vacation'
        END,
        -- title
        CASE ABS(CHECKSUM(NEWID())) % 8
            WHEN 0 THEN 'Debt consolidation' WHEN 1 THEN 'Credit card'
            WHEN 2 THEN 'Home improvement' WHEN 3 THEN 'Other'
            WHEN 4 THEN 'Major purchase' WHEN 5 THEN 'Business'
            WHEN 6 THEN 'Car financing' ELSE NULL
        END,
        -- zip_code
        RIGHT('00000' + CAST(ABS(CHECKSUM(NEWID())) % 100000 AS VARCHAR(5)), 5),
        -- addr_state
        CASE ABS(CHECKSUM(NEWID())) % 50
            WHEN 0 THEN 'CA' WHEN 1 THEN 'TX' WHEN 2 THEN 'NY' WHEN 3 THEN 'FL'
            WHEN 4 THEN 'IL' WHEN 5 THEN 'PA' WHEN 6 THEN 'OH' WHEN 7 THEN 'GA'
            WHEN 8 THEN 'NC' WHEN 9 THEN 'MI' WHEN 10 THEN 'NJ' WHEN 11 THEN 'VA'
            WHEN 12 THEN 'WA' WHEN 13 THEN 'AZ' WHEN 14 THEN 'MA' WHEN 15 THEN 'TN'
            WHEN 16 THEN 'IN' WHEN 17 THEN 'MO' WHEN 18 THEN 'MD' WHEN 19 THEN 'WI'
            WHEN 20 THEN 'CO' WHEN 21 THEN 'MN' WHEN 22 THEN 'SC' WHEN 23 THEN 'AL'
            WHEN 24 THEN 'LA' WHEN 25 THEN 'KY' WHEN 26 THEN 'OR' WHEN 27 THEN 'OK'
            WHEN 28 THEN 'CT' WHEN 29 THEN 'UT' WHEN 30 THEN 'NV' WHEN 31 THEN 'AR'
            ELSE 'CA'
        END,
        -- dti
        CAST((ABS(CHECKSUM(NEWID())) % 5000) / 100.0 AS FLOAT),
        -- delinq_2yrs
        ABS(CHECKSUM(NEWID())) % 11,
        -- earliest_cr_line
        FORMAT(DATEADD(YEAR, -(ABS(CHECKSUM(NEWID())) % 30 + 5), GETDATE()), 'MMM-yyyy'),
        -- inq_last_6mths
        ABS(CHECKSUM(NEWID())) % 9,
        -- mths_since_last_delinq
        CASE WHEN ABS(CHECKSUM(NEWID())) % 3 = 0 THEN NULL ELSE ABS(CHECKSUM(NEWID())) % 120 + 1 END,
        -- mths_since_last_record
        CASE WHEN ABS(CHECKSUM(NEWID())) % 5 = 0 THEN ABS(CHECKSUM(NEWID())) % 120 + 1 ELSE NULL END,
        -- open_acc
        ABS(CHECKSUM(NEWID())) % 40 + 1,
        -- pub_rec
        ABS(CHECKSUM(NEWID())) % 6,
        -- revol_bal
        ABS(CHECKSUM(NEWID())) % 200001,
        -- revol_util
        CAST((ABS(CHECKSUM(NEWID())) % 10001) / 100.0 AS FLOAT),
        -- total_acc
        ABS(CHECKSUM(NEWID())) % 99 + 2,
        -- initial_list_status
        CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'w' ELSE 'f' END,
        -- out_prncp
        CAST(ABS(CHECKSUM(NEWID())) % 40000 AS FLOAT),
        -- out_prncp_inv
        CAST(ABS(CHECKSUM(NEWID())) % 40000 AS FLOAT),
        -- total_pymnt
        CAST(ABS(CHECKSUM(NEWID())) % 60000 AS FLOAT),
        -- total_pymnt_inv
        CAST(ABS(CHECKSUM(NEWID())) % 60000 AS FLOAT),
        -- total_rec_prncp
        CAST(ABS(CHECKSUM(NEWID())) % 40000 AS FLOAT),
        -- total_rec_int
        CAST(ABS(CHECKSUM(NEWID())) % 20000 AS FLOAT),
        -- total_rec_late_fee
        CAST(ABS(CHECKSUM(NEWID())) % 500 AS FLOAT),
        -- recoveries
        CAST(ABS(CHECKSUM(NEWID())) % 5000 AS FLOAT),
        -- collection_recovery_fee
        CAST(ABS(CHECKSUM(NEWID())) % 1000 AS FLOAT),
        -- last_pymnt_d
        FORMAT(DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()), 'MMM-yyyy'),
        -- last_pymnt_amnt
        CAST(ABS(CHECKSUM(NEWID())) % 5000 AS FLOAT),
        -- collections_12_mths_ex_med
        ABS(CHECKSUM(NEWID())) % 6,
        -- policy_code
        ABS(CHECKSUM(NEWID())) % 2 + 1,
        -- application_type
        CASE WHEN ABS(CHECKSUM(NEWID())) % 10 = 0 THEN 'Joint App' ELSE 'Individual' END,
        -- annual_inc_joint
        CASE WHEN ABS(CHECKSUM(NEWID())) % 10 = 0 THEN CAST(40000 + ABS(CHECKSUM(NEWID())) % 460000 AS FLOAT) ELSE NULL END,
        -- dti_joint
        CASE WHEN ABS(CHECKSUM(NEWID())) % 10 = 0 THEN CAST((ABS(CHECKSUM(NEWID())) % 4000) / 100.0 AS FLOAT) ELSE NULL END,
        -- acc_now_delinq
        ABS(CHECKSUM(NEWID())) % 4,
        -- tot_coll_amt
        ABS(CHECKSUM(NEWID())) % 50001,
        -- tot_cur_bal
        ABS(CHECKSUM(NEWID())) % 500001,
        -- is_bad (will be updated)
        0,
        -- created_at
        DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()),
        -- updated_at
        GETDATE();
    
    SET @i = @i + 1;
    
    IF @i % 10000 = 0
        PRINT 'Generated ' + CAST(@i AS VARCHAR(20)) + ' records...';
END

PRINT 'Base data generation complete. Updating is_bad flag...';

-- Update is_bad flag based on loan_status
UPDATE [dbo].[LoanStats]
SET [is_bad] = CASE 
    WHEN loan_status IN ('Late (16-30 days)', 'Late (31-120 days)', 'Default', 'Charged Off') THEN 1 
    ELSE 0 
END;

PRINT 'Adding intentional data quality issues for testing...';

-- Add some intentional data quality issues for testing
-- 1. Add some NULL values in critical fields
UPDATE [dbo].[LoanStats]
SET loan_amnt = NULL
WHERE id % 200 = 0;

UPDATE [dbo].[LoanStats]
SET int_rate = NULL
WHERE id % 333 = 0;

UPDATE [dbo].[LoanStats]
SET annual_inc = NULL
WHERE id % 500 = 0;

-- 2. Add some duplicate member_ids (intentional data quality issue)
UPDATE [dbo].[LoanStats]
SET member_id = 12345678
WHERE id BETWEEN 1000 AND 1100;

-- 3. Add some outlier values
UPDATE [dbo].[LoanStats]
SET annual_inc = 9999999
WHERE id % 2000 = 0 AND annual_inc IS NOT NULL;

UPDATE [dbo].[LoanStats]
SET dti = 999
WHERE id % 2001 = 0;

PRINT 'Creating staging data...';

-- Insert some staging data for referential integrity testing
INSERT INTO [dbo].[LoanStatsStaging] (
    [id], [member_id], [loan_amnt], [funded_amnt], [term], [int_rate],
    [grade], [loan_status], [home_ownership], [annual_inc], [purpose], [addr_state]
)
SELECT TOP 1000
    id + 1000000,
    member_id,
    loan_amnt,
    funded_amnt,
    term,
    CAST(int_rate AS NVARCHAR(50)),
    grade,
    loan_status,
    home_ownership,
    annual_inc,
    purpose,
    addr_state
FROM [dbo].[LoanStats]
WHERE id <= 1000;

PRINT 'Creating sample predictions...';

-- Insert sample predictions
INSERT INTO [dbo].[LoanStatsPredictions] ([is_bad_Pred], [id])
SELECT TOP 5000
    CAST(ABS(CHECKSUM(NEWID())) % 100 / 100.0 AS FLOAT),
    id
FROM [dbo].[LoanStats]
WHERE id <= 5000;

PRINT 'Creating runtime stats...';

-- Insert sample runtime stats
INSERT INTO [dbo].[RunTimeStats] ([SessionID], [RunTime], [Operation], [Duration_ms], [RowsAffected])
VALUES 
    (51, DATEADD(HOUR, -24, GETDATE()), 'Start', NULL, NULL),
    (51, DATEADD(HOUR, -24, GETDATE()) + '00:00:05', 'End', 5000, 10000),
    (52, DATEADD(HOUR, -12, GETDATE()), 'Start', NULL, NULL),
    (52, DATEADD(HOUR, -12, GETDATE()) + '00:00:08', 'End', 8000, 15000),
    (53, DATEADD(HOUR, -6, GETDATE()), 'Start', NULL, NULL),
    (53, DATEADD(HOUR, -6, GETDATE()) + '00:00:03', 'End', 3000, 5000),
    (54, DATEADD(HOUR, -1, GETDATE()), 'Start', NULL, NULL),
    (54, DATEADD(HOUR, -1, GETDATE()) + '00:00:10', 'End', 10000, 20000);

PRINT 'Creating data load history...';

-- Insert data load history
INSERT INTO [dbo].[DataLoadHistory] ([load_start_time], [load_end_time], [source_file], [rows_loaded], [status])
VALUES 
    (DATEADD(DAY, -7, GETDATE()), DATEADD(DAY, -7, GETDATE()) + '00:15:00', 'LoanStats_2023_Q1.csv', 25000, 'Success'),
    (DATEADD(DAY, -6, GETDATE()), DATEADD(DAY, -6, GETDATE()) + '00:12:00', 'LoanStats_2023_Q2.csv', 25000, 'Success'),
    (DATEADD(DAY, -5, GETDATE()), DATEADD(DAY, -5, GETDATE()) + '00:14:00', 'LoanStats_2023_Q3.csv', 25000, 'Success'),
    (DATEADD(DAY, -4, GETDATE()), DATEADD(DAY, -4, GETDATE()) + '00:13:00', 'LoanStats_2023_Q4.csv', 25000, 'Success');

PRINT 'Final record counts:';

-- Final count
SELECT 'LoanStats' AS TableName, COUNT(*) AS RecordCount FROM [dbo].[LoanStats]
UNION ALL
SELECT 'LoanStatsStaging', COUNT(*) FROM [dbo].[LoanStatsStaging]
UNION ALL
SELECT 'LoanStatsPredictions', COUNT(*) FROM [dbo].[LoanStatsPredictions]
UNION ALL
SELECT 'RunTimeStats', COUNT(*) FROM [dbo].[RunTimeStats]
UNION ALL
SELECT 'DataLoadHistory', COUNT(*) FROM [dbo].[DataLoadHistory];

PRINT 'Data generation completed successfully!';
GO
