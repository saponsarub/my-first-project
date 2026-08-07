SELECT 
    Month(si.InvoiceDate) AS InvoiceYear,
    si.CustomerAccount,
    si.CustomerName,
    AVG(si.LineAmount) AS AVGtSell
FROM syndpdev001.dbo.tb_SalesInvoice si
WHERE si.SysCompanyId = 'DRPH'
GROUP BY 
    Month(si.InvoiceDate),
    si.CustomerAccount,
    si.CustomerName
ORDER BY InvoiceYear, si.CustomerAccount;
