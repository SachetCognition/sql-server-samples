
CREATE PROCEDURE Integration.GetSaleUpdates
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
    -- Also removed redundant join to Sales.Customers AS bt since BillToCustomerID
    -- data is already available from the Invoices table.

    SELECT CAST(i.InvoiceDate AS date) AS [Invoice Date Key],
           CAST(i.ConfirmedDeliveryTime AS date) AS [Delivery Date Key],
           i.InvoiceID AS [WWI Invoice ID],
           il.[Description],
           pt.PackageTypeName AS Package,
           il.Quantity,
           il.UnitPrice AS [Unit Price],
           il.TaxRate AS [Tax Rate],
           il.ExtendedPrice - il.TaxAmount AS [Total Excluding Tax],
           il.TaxAmount AS [Tax Amount],
           il.LineProfit AS Profit,
           il.ExtendedPrice AS [Total Including Tax],
           CASE WHEN si.IsChillerStock = 0 THEN il.Quantity ELSE 0 END AS [Total Dry Items],
           CASE WHEN si.IsChillerStock <> 0 THEN il.Quantity ELSE 0 END AS [Total Chiller Items],
           c.DeliveryCityID AS [WWI City ID],
           i.CustomerID AS [WWI Customer ID],
           i.BillToCustomerID AS [WWI Bill To Customer ID],
           il.StockItemID AS [WWI Stock Item ID],
           i.SalespersonPersonID AS [WWI Saleperson ID],
           CASE WHEN il.LastEditedWhen > i.LastEditedWhen THEN il.LastEditedWhen ELSE i.LastEditedWhen END AS [Last Modified When]
    FROM Sales.Invoices AS i
    INNER JOIN Sales.InvoiceLines AS il
        ON i.InvoiceID = il.InvoiceID
    INNER JOIN Warehouse.StockItems AS si
        ON il.StockItemID = si.StockItemID
    INNER JOIN Warehouse.PackageTypes AS pt
        ON il.PackageTypeID = pt.PackageTypeID
    INNER JOIN Sales.Customers AS c
        ON i.CustomerID = c.CustomerID
    WHERE (
        -- Sargable condition: Either InvoiceLines or Invoices was modified in the date range
        (il.LastEditedWhen > @LastCutoff AND il.LastEditedWhen <= @NewCutoff)
        OR (i.LastEditedWhen > @LastCutoff AND i.LastEditedWhen <= @NewCutoff)
    )
    -- Additional filter to ensure the MAX of both timestamps is within range
    AND CASE WHEN il.LastEditedWhen > i.LastEditedWhen THEN il.LastEditedWhen ELSE i.LastEditedWhen END > @LastCutoff
    AND CASE WHEN il.LastEditedWhen > i.LastEditedWhen THEN il.LastEditedWhen ELSE i.LastEditedWhen END <= @NewCutoff
    ORDER BY i.InvoiceID, il.InvoiceLineID;

    RETURN 0;
END;
