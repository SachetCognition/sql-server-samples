-- Generate Sample Data for LendingClub Database
-- Creates ~100,000 realistic loan records for analysis

USE [LendingClub]
GO

SET NOCOUNT ON;

-- Create helper function for random date generation
DECLARE @StartDate DATE = '2012-01-01';
DECLARE @EndDate DATE = '2023-12-31';
DECLARE @BatchSize INT = 10000;
DECLARE @TotalRecords INT = 100000;
DECLARE @CurrentBatch INT = 0;

-- Lookup tables for realistic data
DECLARE @Grades TABLE (grade NVARCHAR(10), sub_grades NVARCHAR(100));
INSERT INTO @Grades VALUES 
    ('A', 'A1,A2,A3,A4,A5'),
    ('B', 'B1,B2,B3,B4,B5'),
    ('C', 'C1,C2,C3,C4,C5'),
    ('D', 'D1,D2,D3,D4,D5'),
    ('E', 'E1,E2,E3,E4,E5'),
    ('F', 'F1,F2,F3,F4,F5'),
    ('G', 'G1,G2,G3,G4,G5');

DECLARE @LoanStatuses TABLE (status NVARCHAR(50), weight INT);
INSERT INTO @LoanStatuses VALUES 
    ('Fully Paid', 50),
    ('Current', 25),
    ('Charged Off', 8),
    ('Late (31-120 days)', 5),
    ('Late (16-30 days)', 3),
    ('In Grace Period', 4),
    ('Default', 3),
    ('Does not meet the credit policy. Status:Fully Paid', 1),
    ('Does not meet the credit policy. Status:Charged Off', 1);

DECLARE @HomeOwnership TABLE (ownership NVARCHAR(50));
INSERT INTO @HomeOwnership VALUES ('RENT'), ('MORTGAGE'), ('OWN'), ('OTHER'), ('NONE');

DECLARE @Purposes TABLE (purpose NVARCHAR(100));
INSERT INTO @Purposes VALUES 
    ('debt_consolidation'), ('credit_card'), ('home_improvement'), 
    ('other'), ('major_purchase'), ('small_business'), ('car'),
    ('medical'), ('moving'), ('vacation'), ('house'), ('wedding'),
    ('renewable_energy'), ('educational');

DECLARE @States TABLE (state_code NVARCHAR(10));
INSERT INTO @States VALUES 
    ('CA'), ('TX'), ('NY'), ('FL'), ('IL'), ('PA'), ('OH'), ('GA'), ('NC'), ('MI'),
    ('NJ'), ('VA'), ('WA'), ('AZ'), ('MA'), ('TN'), ('IN'), ('MO'), ('MD'), ('WI'),
    ('CO'), ('MN'), ('SC'), ('AL'), ('LA'), ('KY'), ('OR'), ('OK'), ('CT'), ('UT'),
    ('NV'), ('AR'), ('MS'), ('KS'), ('NM'), ('NE'), ('WV'), ('HI'), ('NH'), ('ME'),
    ('RI'), ('MT'), ('DE'), ('SD'), ('ND'), ('AK'), ('VT'), ('WY'), ('DC');

DECLARE @VerificationStatus TABLE (status NVARCHAR(50));
INSERT INTO @VerificationStatus VALUES ('Verified'), ('Source Verified'), ('Not Verified');

DECLARE @EmpLengths TABLE (emp_length NVARCHAR(50));
INSERT INTO @EmpLengths VALUES 
    ('< 1 year'), ('1 year'), ('2 years'), ('3 years'), ('4 years'),
    ('5 years'), ('6 years'), ('7 years'), ('8 years'), ('9 years'), 
    ('10+ years'), ('n/a');

PRINT 'Starting data generation...';
PRINT 'Target: ' + CAST(@TotalRecords AS VARCHAR(20)) + ' records';

WHILE @CurrentBatch * @BatchSize < @TotalRecords
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
    SELECT TOP (@BatchSize)
        -- member_id: unique identifier
        ABS(CHECKSUM(NEWID())) % 90000000 + 10000000,
        
        -- loan_amnt: $1,000 to $40,000
        (ABS(CHECKSUM(NEWID())) % 39) * 1000 + 1000,
        
        -- funded_amnt: same as loan_amnt
        (ABS(CHECKSUM(NEWID())) % 39) * 1000 + 1000,
        
        -- funded_amnt_inv: slightly less than funded_amnt
        (ABS(CHECKSUM(NEWID())) % 38) * 1000 + 1000,
        
        -- term: 36 or 60 months
        CASE WHEN ABS(CHECKSUM(NEWID())) % 3 = 0 THEN ' 60 months' ELSE ' 36 months' END,
        
        -- int_rate: 5% to 30%
        CAST(5.0 + (ABS(CHECKSUM(NEWID())) % 2500) / 100.0 AS FLOAT),
        
        -- installment: calculated based on loan amount
        CAST(100 + (ABS(CHECKSUM(NEWID())) % 1400) AS FLOAT),
        
        -- grade: A through G
        CASE ABS(CHECKSUM(NEWID())) % 7
            WHEN 0 THEN 'A' WHEN 1 THEN 'B' WHEN 2 THEN 'C'
            WHEN 3 THEN 'D' WHEN 4 THEN 'E' WHEN 5 THEN 'F' ELSE 'G'
        END,
        
        -- sub_grade
        CASE ABS(CHECKSUM(NEWID())) % 7
            WHEN 0 THEN 'A' + CAST(ABS(CHECKSUM(NEWID())) % 5 + 1 AS VARCHAR(1))
            WHEN 1 THEN 'B' + CAST(ABS(CHECKSUM(NEWID())) % 5 + 1 AS VARCHAR(1))
            WHEN 2 THEN 'C' + CAST(ABS(CHECKSUM(NEWID())) % 5 + 1 AS VARCHAR(1))
            WHEN 3 THEN 'D' + CAST(ABS(CHECKSUM(NEWID())) % 5 + 1 AS VARCHAR(1))
            WHEN 4 THEN 'E' + CAST(ABS(CHECKSUM(NEWID())) % 5 + 1 AS VARCHAR(1))
            WHEN 5 THEN 'F' + CAST(ABS(CHECKSUM(NEWID())) % 5 + 1 AS VARCHAR(1))
            ELSE 'G' + CAST(ABS(CHECKSUM(NEWID())) % 5 + 1 AS VARCHAR(1))
        END,
        
        -- emp_title
        CASE ABS(CHECKSUM(NEWID())) % 10
            WHEN 0 THEN 'Manager' WHEN 1 THEN 'Teacher' WHEN 2 THEN 'Engineer'
            WHEN 3 THEN 'Nurse' WHEN 4 THEN 'Driver' WHEN 5 THEN 'Sales'
            WHEN 6 THEN 'Analyst' WHEN 7 THEN 'Technician' WHEN 8 THEN 'Owner'
            ELSE NULL
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
        
        -- annual_inc: $20,000 to $500,000
        CAST(20000 + (ABS(CHECKSUM(NEWID())) % 480000) AS FLOAT),
        
        -- verification_status
        CASE ABS(CHECKSUM(NEWID())) % 3
            WHEN 0 THEN 'Verified' WHEN 1 THEN 'Source Verified' ELSE 'Not Verified'
        END,
        
        -- issue_d: date string
        FORMAT(DATEADD(DAY, ABS(CHECKSUM(NEWID())) % DATEDIFF(DAY, @StartDate, @EndDate), @StartDate), 'MMM-yyyy'),
        
        -- loan_status
        CASE ABS(CHECKSUM(NEWID())) % 100
            WHEN 0 THEN 'Default'
            WHEN 1 THEN 'Default'
            WHEN 2 THEN 'Default'
            WHEN 3 THEN 'Late (16-30 days)'
            WHEN 4 THEN 'Late (16-30 days)'
            WHEN 5 THEN 'Late (16-30 days)'
            WHEN 6 THEN 'Late (31-120 days)'
            WHEN 7 THEN 'Late (31-120 days)'
            WHEN 8 THEN 'Late (31-120 days)'
            WHEN 9 THEN 'Late (31-120 days)'
            WHEN 10 THEN 'Late (31-120 days)'
            WHEN 11 THEN 'Charged Off'
            WHEN 12 THEN 'Charged Off'
            WHEN 13 THEN 'Charged Off'
            WHEN 14 THEN 'Charged Off'
            WHEN 15 THEN 'Charged Off'
            WHEN 16 THEN 'Charged Off'
            WHEN 17 THEN 'Charged Off'
            WHEN 18 THEN 'Charged Off'
            WHEN 19 THEN 'In Grace Period'
            WHEN 20 THEN 'In Grace Period'
            WHEN 21 THEN 'In Grace Period'
            WHEN 22 THEN 'In Grace Period'
            WHEN 23 THEN 'Current'
            WHEN 24 THEN 'Current'
            WHEN 25 THEN 'Current'
            WHEN 26 THEN 'Current'
            WHEN 27 THEN 'Current'
            WHEN 28 THEN 'Current'
            WHEN 29 THEN 'Current'
            WHEN 30 THEN 'Current'
            WHEN 31 THEN 'Current'
            WHEN 32 THEN 'Current'
            WHEN 33 THEN 'Current'
            WHEN 34 THEN 'Current'
            WHEN 35 THEN 'Current'
            WHEN 36 THEN 'Current'
            WHEN 37 THEN 'Current'
            WHEN 38 THEN 'Current'
            WHEN 39 THEN 'Current'
            WHEN 40 THEN 'Current'
            WHEN 41 THEN 'Current'
            WHEN 42 THEN 'Current'
            WHEN 43 THEN 'Current'
            WHEN 44 THEN 'Current'
            WHEN 45 THEN 'Current'
            WHEN 46 THEN 'Current'
            WHEN 47 THEN 'Current'
            ELSE 'Fully Paid'
        END,
        
        -- pymnt_plan
        CASE WHEN ABS(CHECKSUM(NEWID())) % 100 < 2 THEN 'y' ELSE 'n' END,
        
        -- purpose
        CASE ABS(CHECKSUM(NEWID())) % 14
            WHEN 0 THEN 'debt_consolidation' WHEN 1 THEN 'credit_card'
            WHEN 2 THEN 'home_improvement' WHEN 3 THEN 'other'
            WHEN 4 THEN 'major_purchase' WHEN 5 THEN 'small_business'
            WHEN 6 THEN 'car' WHEN 7 THEN 'medical' WHEN 8 THEN 'moving'
            WHEN 9 THEN 'vacation' WHEN 10 THEN 'house' WHEN 11 THEN 'wedding'
            WHEN 12 THEN 'renewable_energy' ELSE 'educational'
        END,
        
        -- title
        CASE ABS(CHECKSUM(NEWID())) % 10
            WHEN 0 THEN 'Debt consolidation' WHEN 1 THEN 'Credit card refinancing'
            WHEN 2 THEN 'Home improvement' WHEN 3 THEN 'Other'
            WHEN 4 THEN 'Major purchase' WHEN 5 THEN 'Business'
            WHEN 6 THEN 'Car financing' WHEN 7 THEN 'Medical expenses'
            WHEN 8 THEN 'Moving and relocation' ELSE NULL
        END,
        
        -- zip_code
        RIGHT('00000' + CAST(ABS(CHECKSUM(NEWID())) % 100000 AS VARCHAR(5)), 5) + 'xx',
        
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
            WHEN 32 THEN 'MS' WHEN 33 THEN 'KS' WHEN 34 THEN 'NM' WHEN 35 THEN 'NE'
            WHEN 36 THEN 'WV' WHEN 37 THEN 'HI' WHEN 38 THEN 'NH' WHEN 39 THEN 'ME'
            WHEN 40 THEN 'RI' WHEN 41 THEN 'MT' WHEN 42 THEN 'DE' WHEN 43 THEN 'SD'
            WHEN 44 THEN 'ND' WHEN 45 THEN 'AK' WHEN 46 THEN 'VT' WHEN 47 THEN 'WY'
            WHEN 48 THEN 'DC' ELSE 'CA'
        END,
        
        -- dti: 0 to 50
        CAST((ABS(CHECKSUM(NEWID())) % 5000) / 100.0 AS FLOAT),
        
        -- delinq_2yrs: 0 to 10
        ABS(CHECKSUM(NEWID())) % 11,
        
        -- earliest_cr_line
        FORMAT(DATEADD(YEAR, -(ABS(CHECKSUM(NEWID())) % 30 + 5), GETDATE()), 'MMM-yyyy'),
        
        -- inq_last_6mths: 0 to 8
        ABS(CHECKSUM(NEWID())) % 9,
        
        -- mths_since_last_delinq: NULL or 1-120
        CASE WHEN ABS(CHECKSUM(NEWID())) % 3 = 0 THEN NULL ELSE ABS(CHECKSUM(NEWID())) % 120 + 1 END,
        
        -- mths_since_last_record: NULL or 1-120
        CASE WHEN ABS(CHECKSUM(NEWID())) % 5 = 0 THEN ABS(CHECKSUM(NEWID())) % 120 + 1 ELSE NULL END,
        
        -- open_acc: 1 to 40
        ABS(CHECKSUM(NEWID())) % 40 + 1,
        
        -- pub_rec: 0 to 5
        ABS(CHECKSUM(NEWID())) % 6,
        
        -- revol_bal: 0 to 200000
        ABS(CHECKSUM(NEWID())) % 200001,
        
        -- revol_util: 0 to 100
        CAST((ABS(CHECKSUM(NEWID())) % 10001) / 100.0 AS FLOAT),
        
        -- total_acc: 2 to 100
        ABS(CHECKSUM(NEWID())) % 99 + 2,
        
        -- initial_list_status
        CASE WHEN ABS(CHECKSUM(NEWID())) % 2 = 0 THEN 'w' ELSE 'f' END,
        
        -- out_prncp: 0 to loan amount
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
        
        -- collections_12_mths_ex_med: 0 to 5
        ABS(CHECKSUM(NEWID())) % 6,
        
        -- policy_code: 1 or 2
        ABS(CHECKSUM(NEWID())) % 2 + 1,
        
        -- application_type
        CASE WHEN ABS(CHECKSUM(NEWID())) % 10 = 0 THEN 'Joint App' ELSE 'Individual' END,
        
        -- annual_inc_joint: NULL or value for joint apps
        CASE WHEN ABS(CHECKSUM(NEWID())) % 10 = 0 THEN CAST(40000 + ABS(CHECKSUM(NEWID())) % 460000 AS FLOAT) ELSE NULL END,
        
        -- dti_joint: NULL or value for joint apps
        CASE WHEN ABS(CHECKSUM(NEWID())) % 10 = 0 THEN CAST((ABS(CHECKSUM(NEWID())) % 4000) / 100.0 AS FLOAT) ELSE NULL END,
        
        -- acc_now_delinq: 0 to 3
        ABS(CHECKSUM(NEWID())) % 4,
        
        -- tot_coll_amt: 0 to 50000
        ABS(CHECKSUM(NEWID())) % 50001,
        
        -- tot_cur_bal: 0 to 500000
        ABS(CHECKSUM(NEWID())) % 500001,
        
        -- is_bad: calculated based on loan_status (will be updated later)
        0,
        
        -- created_at
        DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()),
        
        -- updated_at
        GETDATE()
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
    WHERE a.object_id > 0 AND b.object_id > 0;
    
    SET @CurrentBatch = @CurrentBatch + 1;
    PRINT 'Batch ' + CAST(@CurrentBatch AS VARCHAR(10)) + ' completed. Records: ' + CAST(@CurrentBatch * @BatchSize AS VARCHAR(20));
END

-- Update is_bad flag based on loan_status
UPDATE [dbo].[LoanStats]
SET [is_bad] = CASE 
    WHEN loan_status IN ('Late (16-30 days)', 'Late (31-120 days)', 'Default', 'Charged Off') THEN 1 
    ELSE 0 
END;

PRINT 'is_bad flag updated';

-- Add some intentional data quality issues for testing
-- 1. Add some NULL values in critical fields
UPDATE TOP (500) [dbo].[LoanStats]
SET loan_amnt = NULL
WHERE id % 200 = 0;

UPDATE TOP (300) [dbo].[LoanStats]
SET int_rate = NULL
WHERE id % 333 = 0;

UPDATE TOP (200) [dbo].[LoanStats]
SET annual_inc = NULL
WHERE id % 500 = 0;

-- 2. Add some duplicate member_ids (intentional data quality issue)
UPDATE TOP (100) [dbo].[LoanStats]
SET member_id = 12345678
WHERE id BETWEEN 1000 AND 1100;

-- 3. Add some outlier values
UPDATE TOP (50) [dbo].[LoanStats]
SET annual_inc = 9999999
WHERE id % 2000 = 0;

UPDATE TOP (50) [dbo].[LoanStats]
SET dti = 999
WHERE id % 2001 = 0;

PRINT 'Data quality issues added for testing';

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
    CAST(int_rate AS NVARCHAR(50)) + '%',
    grade,
    loan_status,
    home_ownership,
    annual_inc,
    purpose,
    addr_state
FROM [dbo].[LoanStats]
WHERE id <= 1000;

PRINT 'Staging data created';

-- Insert sample predictions
INSERT INTO [dbo].[LoanStatsPredictions] ([is_bad_Pred], [id])
SELECT TOP 5000
    CAST(ABS(CHECKSUM(NEWID())) % 100 / 100.0 AS FLOAT),
    id
FROM [dbo].[LoanStats]
WHERE id <= 5000;

PRINT 'Sample predictions created';

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

PRINT 'Runtime stats created';

-- Insert data load history
INSERT INTO [dbo].[DataLoadHistory] ([load_start_time], [load_end_time], [source_file], [rows_loaded], [status])
VALUES 
    (DATEADD(DAY, -7, GETDATE()), DATEADD(DAY, -7, GETDATE()) + '00:15:00', 'LoanStats_2023_Q1.csv', 25000, 'Success'),
    (DATEADD(DAY, -6, GETDATE()), DATEADD(DAY, -6, GETDATE()) + '00:12:00', 'LoanStats_2023_Q2.csv', 25000, 'Success'),
    (DATEADD(DAY, -5, GETDATE()), DATEADD(DAY, -5, GETDATE()) + '00:14:00', 'LoanStats_2023_Q3.csv', 25000, 'Success'),
    (DATEADD(DAY, -4, GETDATE()), DATEADD(DAY, -4, GETDATE()) + '00:13:00', 'LoanStats_2023_Q4.csv', 25000, 'Success');

PRINT 'Data load history created';

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
