SELECT 
    YEAR(si.InvoiceDate) AS InvoiceYear,
    si.CustomerAccount,
    si.CustomerName,
    SUM(si.LineAmount) AS SumSell
FROM syndpdev001.dbo.tb_SalesInvoice si
WHERE si.SysCompanyId = 'DRPH'
GROUP BY 
    YEAR(si.InvoiceDate),
    si.CustomerAccount,
    si.CustomerName
ORDER BY InvoiceYear, si.CustomerAccount;