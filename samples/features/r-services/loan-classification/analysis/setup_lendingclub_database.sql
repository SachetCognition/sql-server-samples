-- LendingClub Database Setup Script
-- Creates the database structure and populates with sample data for analysis

USE [master]
GO

-- Drop existing database if exists
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'LendingClub')
BEGIN
    ALTER DATABASE [LendingClub] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [LendingClub];
END
GO

-- Create the LendingClub database
CREATE DATABASE [LendingClub]
GO

ALTER DATABASE [LendingClub] SET COMPATIBILITY_LEVEL = 130
GO

ALTER DATABASE [LendingClub] SET RECOVERY SIMPLE
GO

USE [LendingClub]
GO

-- Create the main LoanStats table (production table)
CREATE TABLE [dbo].[LoanStats](
    [id] [int] NOT NULL IDENTITY(1,1),
    [member_id] [int] NULL,
    [loan_amnt] [int] NULL,
    [funded_amnt] [int] NULL,
    [funded_amnt_inv] [int] NULL,
    [term] [nvarchar](50) NULL,
    [int_rate] [float] NULL,
    [installment] [float] NULL,
    [grade] [nvarchar](10) NULL,
    [sub_grade] [nvarchar](10) NULL,
    [emp_title] [nvarchar](255) NULL,
    [emp_length] [nvarchar](50) NULL,
    [home_ownership] [nvarchar](50) NULL,
    [annual_inc] [float] NULL,
    [verification_status] [nvarchar](50) NULL,
    [issue_d] [nvarchar](50) NULL,
    [loan_status] [nvarchar](50) NULL,
    [pymnt_plan] [nvarchar](10) NULL,
    [purpose] [nvarchar](100) NULL,
    [title] [nvarchar](255) NULL,
    [zip_code] [nvarchar](20) NULL,
    [addr_state] [nvarchar](10) NULL,
    [dti] [float] NULL,
    [delinq_2yrs] [int] NULL,
    [earliest_cr_line] [nvarchar](50) NULL,
    [inq_last_6mths] [int] NULL,
    [mths_since_last_delinq] [int] NULL,
    [mths_since_last_record] [int] NULL,
    [open_acc] [int] NULL,
    [pub_rec] [int] NULL,
    [revol_bal] [int] NULL,
    [revol_util] [float] NULL,
    [total_acc] [int] NULL,
    [initial_list_status] [nvarchar](10) NULL,
    [out_prncp] [float] NULL,
    [out_prncp_inv] [float] NULL,
    [total_pymnt] [float] NULL,
    [total_pymnt_inv] [float] NULL,
    [total_rec_prncp] [float] NULL,
    [total_rec_int] [float] NULL,
    [total_rec_late_fee] [float] NULL,
    [recoveries] [float] NULL,
    [collection_recovery_fee] [float] NULL,
    [last_pymnt_d] [nvarchar](50) NULL,
    [last_pymnt_amnt] [float] NULL,
    [next_pymnt_d] [nvarchar](50) NULL,
    [last_credit_pull_d] [nvarchar](50) NULL,
    [collections_12_mths_ex_med] [int] NULL,
    [mths_since_last_major_derog] [int] NULL,
    [policy_code] [int] NULL,
    [application_type] [nvarchar](50) NULL,
    [annual_inc_joint] [float] NULL,
    [dti_joint] [float] NULL,
    [verification_status_joint] [nvarchar](50) NULL,
    [acc_now_delinq] [int] NULL,
    [tot_coll_amt] [int] NULL,
    [tot_cur_bal] [int] NULL,
    [open_acc_6m] [int] NULL,
    [open_il_6m] [int] NULL,
    [open_il_12m] [int] NULL,
    [open_il_24m] [int] NULL,
    [mths_since_rcnt_il] [int] NULL,
    [total_bal_il] [int] NULL,
    [il_util] [float] NULL,
    [open_rv_12m] [int] NULL,
    [open_rv_24m] [int] NULL,
    [max_bal_bc] [int] NULL,
    [all_util] [float] NULL,
    [total_rev_hi_lim] [int] NULL,
    [inq_fi] [int] NULL,
    [total_cu_tl] [int] NULL,
    [inq_last_12m] [int] NULL,
    [acc_open_past_24mths] [int] NULL,
    [avg_cur_bal] [int] NULL,
    [bc_open_to_buy] [int] NULL,
    [bc_util] [float] NULL,
    [chargeoff_within_12_mths] [int] NULL,
    [delinq_amnt] [int] NULL,
    [mo_sin_old_il_acct] [int] NULL,
    [mo_sin_old_rev_tl_op] [int] NULL,
    [mo_sin_rcnt_rev_tl_op] [int] NULL,
    [mo_sin_rcnt_tl] [int] NULL,
    [mort_acc] [int] NULL,
    [mths_since_recent_bc] [int] NULL,
    [mths_since_recent_bc_dlq] [int] NULL,
    [mths_since_recent_inq] [int] NULL,
    [mths_since_recent_revol_delinq] [int] NULL,
    [num_accts_ever_120_pd] [int] NULL,
    [num_actv_bc_tl] [int] NULL,
    [num_actv_rev_tl] [int] NULL,
    [num_bc_sats] [int] NULL,
    [num_bc_tl] [int] NULL,
    [num_il_tl] [int] NULL,
    [num_op_rev_tl] [int] NULL,
    [num_rev_accts] [int] NULL,
    [num_rev_tl_bal_gt_0] [int] NULL,
    [num_sats] [int] NULL,
    [num_tl_120dpd_2m] [int] NULL,
    [num_tl_30dpd] [int] NULL,
    [num_tl_90g_dpd_24m] [int] NULL,
    [num_tl_op_past_12m] [int] NULL,
    [pct_tl_nvr_dlq] [float] NULL,
    [percent_bc_gt_75] [float] NULL,
    [pub_rec_bankruptcies] [int] NULL,
    [tax_liens] [int] NULL,
    [tot_hi_cred_lim] [int] NULL,
    [total_bal_ex_mort] [int] NULL,
    [total_bc_limit] [int] NULL,
    [total_il_high_credit_limit] [int] NULL,
    [is_bad] [int] NULL,
    [created_at] [datetime] NULL DEFAULT GETDATE(),
    [updated_at] [datetime] NULL DEFAULT GETDATE(),
    CONSTRAINT [PK__LoanStat] PRIMARY KEY CLUSTERED ([id] ASC)
) ON [PRIMARY]
GO

-- Create the LoanStatsStaging table (memory-optimized staging table simulation)
-- Note: Memory-optimized tables require specific filegroup setup, using regular table for compatibility
CREATE TABLE [dbo].[LoanStatsStaging](
    [id] [int] NULL,
    [member_id] [int] NULL,
    [loan_amnt] [int] NULL,
    [funded_amnt] [int] NULL,
    [funded_amnt_inv] [int] NULL,
    [term] [nvarchar](50) NULL,
    [int_rate] [nvarchar](50) NULL,
    [installment] [float] NULL,
    [grade] [nvarchar](10) NULL,
    [sub_grade] [nvarchar](10) NULL,
    [emp_title] [nvarchar](255) NULL,
    [emp_length] [nvarchar](50) NULL,
    [home_ownership] [nvarchar](50) NULL,
    [annual_inc] [float] NULL,
    [verification_status] [nvarchar](50) NULL,
    [issue_d] [nvarchar](50) NULL,
    [loan_status] [nvarchar](50) NULL,
    [pymnt_plan] [nvarchar](10) NULL,
    [purpose] [nvarchar](100) NULL,
    [title] [nvarchar](255) NULL,
    [zip_code] [nvarchar](20) NULL,
    [addr_state] [nvarchar](10) NULL,
    [dti] [float] NULL,
    [delinq_2yrs] [int] NULL,
    [earliest_cr_line] [nvarchar](50) NULL,
    [inq_last_6mths] [int] NULL,
    [mths_since_last_delinq] [int] NULL,
    [mths_since_last_record] [int] NULL,
    [open_acc] [int] NULL,
    [pub_rec] [int] NULL,
    [revol_bal] [int] NULL,
    [revol_util] [nvarchar](50) NULL,
    [total_acc] [int] NULL,
    [initial_list_status] [nvarchar](10) NULL,
    [out_prncp] [float] NULL,
    [out_prncp_inv] [float] NULL,
    [total_pymnt] [float] NULL,
    [total_pymnt_inv] [float] NULL,
    [total_rec_prncp] [float] NULL,
    [total_rec_int] [float] NULL,
    [total_rec_late_fee] [float] NULL,
    [recoveries] [float] NULL,
    [collection_recovery_fee] [float] NULL,
    [last_pymnt_d] [nvarchar](50) NULL,
    [last_pymnt_amnt] [float] NULL,
    [next_pymnt_d] [nvarchar](50) NULL,
    [last_credit_pull_d] [nvarchar](50) NULL,
    [collections_12_mths_ex_med] [int] NULL,
    [mths_since_last_major_derog] [int] NULL,
    [policy_code] [int] NULL,
    [application_type] [nvarchar](50) NULL,
    [annual_inc_joint] [float] NULL,
    [dti_joint] [float] NULL,
    [verification_status_joint] [nvarchar](50) NULL,
    [acc_now_delinq] [int] NULL,
    [tot_coll_amt] [int] NULL,
    [tot_cur_bal] [int] NULL,
    [staging_id] [int] IDENTITY(1,1) PRIMARY KEY
)
GO

-- Create LoanStatsPredictions table
CREATE TABLE [dbo].[LoanStatsPredictions](
    [prediction_id] [int] IDENTITY(1,1) PRIMARY KEY,
    [is_bad_Pred] [float] NULL,
    [id] [int] NULL,
    [prediction_date] [datetime] DEFAULT GETDATE()
)
GO

-- Create LoanPredictionsWhatIf table
CREATE TABLE [dbo].[LoanPredictionsWhatIf](
    [prediction_id] [int] IDENTITY(1,1) PRIMARY KEY,
    [is_bad_Pred] [float] NULL,
    [id] [int] NULL,
    [scenario_rate] [float] NULL,
    [prediction_date] [datetime] DEFAULT GETDATE()
)
GO

-- Create RunTimeStats table for performance monitoring
CREATE TABLE [dbo].[RunTimeStats](
    [stat_id] [int] IDENTITY(1,1) PRIMARY KEY,
    [SessionID] [int] NOT NULL,
    [RunTime] [datetime] NOT NULL,
    [Operation] [varchar](255) NOT NULL,
    [Duration_ms] [int] NULL,
    [RowsAffected] [int] NULL,
    [QueryText] [nvarchar](max) NULL
)
GO

-- Create WhatIf configuration table
CREATE TABLE [dbo].[WhatIf](
    [config_id] [int] IDENTITY(1,1) PRIMARY KEY,
    [Rate] [float] NULL,
    [created_at] [datetime] DEFAULT GETDATE()
)
GO

INSERT INTO [dbo].[WhatIf] ([Rate]) VALUES (0.0)
GO

-- Create models table for ML model storage
CREATE TABLE [dbo].[models](
    [model_id] [int] IDENTITY(1,1) PRIMARY KEY,
    [model_name] [nvarchar](100) NULL,
    [model] [varbinary](max) NULL,
    [created_at] [datetime] DEFAULT GETDATE()
)
GO

-- Create DataLoadHistory table for tracking ETL operations
CREATE TABLE [dbo].[DataLoadHistory](
    [load_id] [int] IDENTITY(1,1) PRIMARY KEY,
    [load_start_time] [datetime] NOT NULL,
    [load_end_time] [datetime] NULL,
    [source_file] [nvarchar](500) NULL,
    [rows_loaded] [int] NULL,
    [status] [varchar](50) NULL,
    [error_message] [nvarchar](max) NULL
)
GO

PRINT 'Database structure created successfully'
GO
