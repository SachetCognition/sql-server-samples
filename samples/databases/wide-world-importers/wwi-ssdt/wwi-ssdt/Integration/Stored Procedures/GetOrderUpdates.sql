
CREATE PROCEDURE Integration.GetOrderUpdates
@LastCutoff datetime2(7),
@NewCutoff datetime2(7)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Performance Optimization: Replaced non-sargable CASE expression in WHERE clause
    -- with sargable OR conditions that allow index usage on LastEditedWhen columns.
    -- The original CASE expression prevented the query optimizer from using indexes
    -- because it required evaluating the expression for every row before filtering.
    
    SELECT CAST(o.OrderDate AS date) AS [Order Date Key],
           CAST(ol.PickingCompletedWhen AS date) AS [Picked Date Key],
           o.OrderID AS [WWI Order ID],
           o.BackorderOrderID AS [WWI Backorder ID],
           ol.[Description],
           pt.PackageTypeName AS Package,
           ol.Quantity AS Quantity,
           ol.UnitPrice AS [Unit Price],
           ol.TaxRate AS [Tax Rate],
           ROUND(ol.Quantity * ol.UnitPrice, 2) AS [Total Excluding Tax],
           ROUND(ol.Quantity * ol.UnitPrice * ol.TaxRate / 100.0, 2) AS [Tax Amount],
           ROUND(ol.Quantity * ol.UnitPrice, 2) + ROUND(ol.Quantity * ol.UnitPrice * ol.TaxRate / 100.0, 2) AS [Total Including Tax],
           c.DeliveryCityID AS [WWI City ID],
           c.CustomerID AS [WWI Customer ID],
           ol.StockItemID AS [WWI Stock Item ID],
           o.SalespersonPersonID AS [WWI Salesperson ID],
           o.PickedByPersonID AS [WWI Picker ID],
           CASE WHEN ol.LastEditedWhen > o.LastEditedWhen THEN ol.LastEditedWhen ELSE o.LastEditedWhen END AS [Last Modified When]
    FROM Sales.Orders AS o
    INNER JOIN Sales.OrderLines AS ol
        ON o.OrderID = ol.OrderID
    INNER JOIN Warehouse.PackageTypes AS pt
        ON ol.PackageTypeID = pt.PackageTypeID
    INNER JOIN Sales.Customers AS c
        ON c.CustomerID = o.CustomerID
    WHERE (
        -- Sargable condition: Either OrderLines or Orders was modified in the date range
        (ol.LastEditedWhen > @LastCutoff AND ol.LastEditedWhen <= @NewCutoff)
        OR (o.LastEditedWhen > @LastCutoff AND o.LastEditedWhen <= @NewCutoff)
    )
    -- Additional filter to ensure the MAX of both timestamps is within range
    AND CASE WHEN ol.LastEditedWhen > o.LastEditedWhen THEN ol.LastEditedWhen ELSE o.LastEditedWhen END > @LastCutoff
    AND CASE WHEN ol.LastEditedWhen > o.LastEditedWhen THEN ol.LastEditedWhen ELSE o.LastEditedWhen END <= @NewCutoff
    ORDER BY o.OrderID;

    RETURN 0;
END;
