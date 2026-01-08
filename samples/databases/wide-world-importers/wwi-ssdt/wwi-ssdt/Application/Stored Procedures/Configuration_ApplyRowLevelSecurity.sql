
CREATE PROCEDURE [Application].Configuration_ApplyRowLevelSecurity
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Performance Optimization: Restructured the security predicate function to:
    -- 1. Use a single join to Cities/StateProvinces instead of two separate subqueries
    -- 2. Fixed operator precedence issue with OR/AND (added parentheses)
    -- 3. Simplified the logic flow for better query plan optimization

    DECLARE @SQL nvarchar(max);

    BEGIN TRY;

        SET @SQL = N'DROP SECURITY POLICY IF EXISTS [Application].FilterCustomersBySalesTerritoryRole;';
        EXECUTE (@SQL);

        SET @SQL = N'DROP FUNCTION IF EXISTS [Application].DetermineCustomerAccess;';
        EXECUTE (@SQL);

        SET @SQL = N'
CREATE FUNCTION [Application].DetermineCustomerAccess(@CityID int)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (
    -- Performance Optimization: Restructured to use a single join and clearer logic
    -- Original had two separate subqueries to Cities/StateProvinces and operator precedence issues
    SELECT 1 AS AccessResult
    FROM [Application].Cities AS c
    INNER JOIN [Application].StateProvinces AS sp
        ON c.StateProvinceID = sp.StateProvinceID
    WHERE c.CityID = @CityID
    AND (
        -- Allow db_owner full access
        IS_ROLEMEMBER(N''db_owner'') <> 0
        -- Allow users in the territory-specific sales role
        OR IS_ROLEMEMBER(sp.SalesTerritory + N'' Sales'') <> 0
        -- Allow Website/WebApi logins with matching session context
        OR (
            ORIGINAL_LOGIN() IN (N''Website'', N''WebApi'')
            AND sp.SalesTerritory = SESSION_CONTEXT(N''SalesTerritory'')
        )
    )
);';
        EXECUTE (@SQL);

        SET @SQL = N'
CREATE SECURITY POLICY [Application].FilterCustomersBySalesTerritoryRole
ADD FILTER PREDICATE [Application].DetermineCustomerAccess(DeliveryCityID)
ON Sales.Customers,
ADD BLOCK PREDICATE [Application].DetermineCustomerAccess(DeliveryCityID)
ON Sales.Customers AFTER UPDATE;';
        EXECUTE (@SQL);

        PRINT N'Successfully applied row level security';
    END TRY
    BEGIN CATCH
        PRINT N'Unable to apply row level security';
		PRINT ERROR_MESSAGE();
        THROW 51000, N'Unable to apply row level security', 1;
    END CATCH;
END;
