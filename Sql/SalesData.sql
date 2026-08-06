SELECT 
    YEAR(si.InvoiceDate) AS InvoiceYear,
    si.CustomerAccount,
    si.CustomerName,
    AVG(si.LineAmount) AS AVGSell
FROM syndpdev001.dbo.tb_SalesInvoice si
WHERE si.SysCompanyId = 'DRPH'
GROUP BY 
    YEAR(si.InvoiceDate),
    si.CustomerAccount,
    si.CustomerName
ORDER BY InvoiceYear, si.CustomerAccount;
