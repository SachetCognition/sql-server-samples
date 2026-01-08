
CREATE PROCEDURE Website.InvoiceCustomerOrders
@OrdersToInvoice Website.OrderIDList READONLY,
@PackedByPersonID int,
@InvoicedByPersonID int
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Performance Optimization: Replaced table variable with temp table for better statistics
    -- and query plan optimization. Also pre-computed item counts using a single aggregation
    -- instead of correlated subqueries.
    
    CREATE TABLE #InvoicesToGenerate
    (
        OrderID int PRIMARY KEY,
        InvoiceID int NOT NULL,
        TotalDryItems int NOT NULL,
        TotalChillerItems int NOT NULL
    );

    BEGIN TRY;

        -- Performance Optimization: Pre-compute dry and chiller item counts in a single pass
        -- instead of using correlated subqueries that execute for each order.
        -- This reduces the number of table scans from 2N to 1 (where N = number of orders).
        ;WITH OrderItemCounts AS (
            SELECT 
                ol.OrderID,
                SUM(CASE WHEN si.IsChillerStock = 0 THEN 1 ELSE 0 END) AS TotalDryItems,
                SUM(CASE WHEN si.IsChillerStock <> 0 THEN 1 ELSE 0 END) AS TotalChillerItems
            FROM @OrdersToInvoice AS oti
            INNER JOIN Sales.OrderLines AS ol ON oti.OrderID = ol.OrderID
            INNER JOIN Warehouse.StockItems AS si ON ol.StockItemID = si.StockItemID
            GROUP BY ol.OrderID
        )
        INSERT #InvoicesToGenerate (OrderID, InvoiceID, TotalDryItems, TotalChillerItems)
        SELECT oti.OrderID,
               NEXT VALUE FOR Sequences.InvoiceID,
               COALESCE(oic.TotalDryItems, 0),
               COALESCE(oic.TotalChillerItems, 0)
        FROM @OrdersToInvoice AS oti
        INNER JOIN Sales.Orders AS o
            ON oti.OrderID = o.OrderID
        LEFT JOIN OrderItemCounts AS oic
            ON oti.OrderID = oic.OrderID
        WHERE NOT EXISTS (SELECT 1 FROM Sales.Invoices AS i
                                   WHERE i.OrderID = oti.OrderID)
        AND o.PickingCompletedWhen IS NOT NULL;

        IF EXISTS (SELECT 1 FROM @OrdersToInvoice AS oti WHERE NOT EXISTS (SELECT 1 FROM #InvoicesToGenerate AS itg WHERE itg.OrderID = oti.OrderID))
        BEGIN
            PRINT N'At least one order ID either does not exist, is not picked, or is already invoiced';
            THROW 51000, N'At least one orderID either does not exist, is not picked, or is already invoiced', 1;
        END;

        BEGIN TRAN;

        INSERT Sales.Invoices
            (InvoiceID, CustomerID, BillToCustomerID, OrderID, DeliveryMethodID, ContactPersonID, AccountsPersonID,
             SalespersonPersonID, PackedByPersonID, InvoiceDate, CustomerPurchaseOrderNumber,
             IsCreditNote, CreditNoteReason, Comments, DeliveryInstructions, InternalComments,
             TotalDryItems, TotalChillerItems,  DeliveryRun, RunPosition,
             ReturnedDeliveryData,
             LastEditedBy, LastEditedWhen)
        SELECT itg.InvoiceID, c.CustomerID, c.BillToCustomerID, itg.OrderID, c.DeliveryMethodID, o.ContactPersonID, btc.PrimaryContactPersonID,
               o.SalespersonPersonID, @PackedByPersonID, SYSDATETIME(), o.CustomerPurchaseOrderNumber,
               0, NULL, NULL, c.DeliveryAddressLine1 + N', ' + c.DeliveryAddressLine2, NULL,
               itg.TotalDryItems, itg.TotalChillerItems, c.DeliveryRun, c.RunPosition,
               JSON_MODIFY(N'{"Events": []}', N'append $.Events',
                   JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(N'{ }', N'$.Event', N'Ready for collection'),
                   N'$.EventTime', CONVERT(nvarchar(20), SYSDATETIME(), 126)),
                   N'$.ConNote', N'EAN-125-' + CAST(itg.InvoiceID + 1050 AS nvarchar(20)))),
               @InvoicedByPersonID, SYSDATETIME()
        FROM #InvoicesToGenerate AS itg
        INNER JOIN Sales.Orders AS o
            ON itg.OrderID = o.OrderID
        INNER JOIN Sales.Customers AS c
            ON o.CustomerID = c.CustomerID
        INNER JOIN Sales.Customers AS btc
            ON btc.CustomerID = c.BillToCustomerID;

        INSERT Sales.InvoiceLines
            (InvoiceID, StockItemID, [Description], PackageTypeID,
             Quantity, UnitPrice, TaxRate, TaxAmount, LineProfit, ExtendedPrice,
             LastEditedBy, LastEditedWhen)
        SELECT itg.InvoiceID, ol.StockItemID, ol.[Description], ol.PackageTypeID,
               ol.PickedQuantity, ol.UnitPrice, ol.TaxRate,
               ROUND(ol.PickedQuantity * ol.UnitPrice * ol.TaxRate / 100.0, 2),
               ROUND(ol.PickedQuantity * (ol.UnitPrice - sih.LastCostPrice), 2),
               ROUND(ol.PickedQuantity * ol.UnitPrice, 2)
                 + ROUND(ol.PickedQuantity * ol.UnitPrice * ol.TaxRate / 100.0, 2),
               @InvoicedByPersonID, SYSDATETIME()
        FROM #InvoicesToGenerate AS itg
        INNER JOIN Sales.OrderLines AS ol
            ON itg.OrderID = ol.OrderID
        INNER JOIN Warehouse.StockItems AS si
            ON ol.StockItemID = si.StockItemID
        INNER JOIN Warehouse.StockItemHoldings AS sih
            ON si.StockItemID = sih.StockItemID
        ORDER BY ol.OrderID, ol.OrderLineID;

        -- Performance Optimization: Cache TransactionTypeID lookup to avoid repeated scalar subqueries
        DECLARE @StockIssueTransactionTypeID INT;
        SELECT @StockIssueTransactionTypeID = TransactionTypeID 
        FROM [Application].TransactionTypes 
        WHERE TransactionTypeName = N'Stock Issue';

        INSERT Warehouse.StockItemTransactions
            (StockItemID, TransactionTypeID, CustomerID, InvoiceID, SupplierID, PurchaseOrderID,
             TransactionOccurredWhen, Quantity, LastEditedBy, LastEditedWhen)
        SELECT il.StockItemID, @StockIssueTransactionTypeID,
               i.CustomerID, i.InvoiceID, NULL, NULL,
               SYSDATETIME(), 0 - il.Quantity, @InvoicedByPersonID, SYSDATETIME()
        FROM #InvoicesToGenerate AS itg
        INNER JOIN Sales.InvoiceLines AS il
            ON itg.InvoiceID = il.InvoiceID
        INNER JOIN Sales.Invoices AS i
            ON il.InvoiceID = i.InvoiceID
        ORDER BY il.InvoiceID, il.InvoiceLineID;

        WITH StockItemTotals
        AS
        (
            SELECT il.StockItemID, SUM(il.Quantity) AS TotalQuantity
            FROM Sales.InvoiceLines aS il
            WHERE il.InvoiceID IN (SELECT InvoiceID FROM #InvoicesToGenerate)
            GROUP BY il.StockItemID
        )
        UPDATE sih
        SET sih.QuantityOnHand -= sit.TotalQuantity,
            sih.LastEditedBy = @InvoicedByPersonID,
            sih.LastEditedWhen = SYSDATETIME()
        FROM Warehouse.StockItemHoldings AS sih
        INNER JOIN StockItemTotals AS sit
        ON sih.StockItemID = sit.StockItemID;

        -- Performance Optimization: Pre-compute invoice totals in a single aggregation
        -- instead of using 4 correlated subqueries that each scan the InvoiceLines table.
        -- Also cache the TransactionTypeID lookup to avoid repeated scalar subqueries.
        DECLARE @CustomerInvoiceTransactionTypeID INT;
        SELECT @CustomerInvoiceTransactionTypeID = TransactionTypeID 
        FROM [Application].TransactionTypes 
        WHERE TransactionTypeName = N'Customer Invoice';

        ;WITH InvoiceTotals AS (
            SELECT 
                il.InvoiceID,
                SUM(il.ExtendedPrice - il.TaxAmount) AS AmountExcludingTax,
                SUM(il.TaxAmount) AS TaxAmount,
                SUM(il.ExtendedPrice) AS TotalAmount
            FROM Sales.InvoiceLines AS il
            WHERE il.InvoiceID IN (SELECT InvoiceID FROM #InvoicesToGenerate)
            GROUP BY il.InvoiceID
        )
        INSERT Sales.CustomerTransactions
            (CustomerID, TransactionTypeID, InvoiceID, PaymentMethodID,
             TransactionDate, AmountExcludingTax, TaxAmount, TransactionAmount,
             OutstandingBalance, FinalizationDate, LastEditedBy, LastEditedWhen)
        SELECT i.BillToCustomerID,
               @CustomerInvoiceTransactionTypeID,
               itg.InvoiceID,
               NULL,
               SYSDATETIME(),
               COALESCE(it.AmountExcludingTax, 0),
               COALESCE(it.TaxAmount, 0),
               COALESCE(it.TotalAmount, 0),
               COALESCE(it.TotalAmount, 0),
               NULL,
               @InvoicedByPersonID,
               SYSDATETIME()
        FROM #InvoicesToGenerate AS itg
        INNER JOIN Sales.Invoices AS i
            ON itg.InvoiceID = i.InvoiceID
        LEFT JOIN InvoiceTotals AS it
            ON itg.InvoiceID = it.InvoiceID;

        COMMIT;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        PRINT N'Unable to invoice these orders';
        THROW;
        RETURN -1;
    END CATCH;

    RETURN 0;
END;
