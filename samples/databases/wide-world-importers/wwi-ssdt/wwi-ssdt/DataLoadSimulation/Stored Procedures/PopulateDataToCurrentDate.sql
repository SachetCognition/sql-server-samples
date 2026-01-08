
CREATE PROCEDURE DataLoadSimulation.PopulateDataToCurrentDate
@AverageNumberOfCustomerOrdersPerDay int,
@SaturdayPercentageOfNormalWorkDay int,
@SundayPercentageOfNormalWorkDay int,
@IsSilentMode bit,
@AreDatesPrinted bit
AS
BEGIN
    -- Performance Optimization Notes:
    -- This is a wrapper procedure that delegates to DailyProcessToCreateHistory.
    -- The main optimizations are in DailyProcessToCreateHistory:
    -- 1. Pre-computed weekend percentage multipliers
    -- 2. Pre-computed daily variation factor
    -- 3. Cached weekday calculations
    -- 4. Optimized seasonal/yearly effect calculations
    
    SET NOCOUNT ON;

    -- Performance Optimization: Use a single SYSDATETIME() call and cache the result
    DECLARE @CurrentSystemDate date = CAST(SYSDATETIME() AS date);
    DECLARE @CurrentMaximumDate date = COALESCE((SELECT MAX(OrderDate) FROM Sales.Orders), '20191231');
    DECLARE @StartingDate date = DATEADD(day, 1, @CurrentMaximumDate);
    DECLARE @EndingDate date = DATEADD(day, -1, @CurrentSystemDate);

    -- Early exit if no days to process
    IF @StartingDate > @EndingDate
    BEGIN
        IF @IsSilentMode = 0
            PRINT N'No days to process - data is already current.';
        RETURN;
    END;

    EXEC DataLoadSimulation.DailyProcessToCreateHistory
        @StartDate = @StartingDate,
        @EndDate = @EndingDate,
        @AverageNumberOfCustomerOrdersPerDay = @AverageNumberOfCustomerOrdersPerDay,
        @SaturdayPercentageOfNormalWorkDay = @SaturdayPercentageOfNormalWorkDay,
        @SundayPercentageOfNormalWorkDay = @SundayPercentageOfNormalWorkDay,
        @UpdateCustomFields = 0, -- they were done in the initial load
        @IsSilentMode = @IsSilentMode,
        @AreDatesPrinted = @AreDatesPrinted;

END;
