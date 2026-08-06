SELECT 
    YEAR(si.InvoiceDate) AS InvoiceYear,
    si.CustomerAccount,
    si.CustomerName,
    COUNT(si.LineAmount) AS CountSell
FROM syndpdev001.dbo.tb_SalesInvoice si
WHERE si.SysCompanyId = 'DRPH'
GROUP BY 
    YEAR(si.InvoiceDate),
    si.CustomerAccount,
    si.CustomerName
ORDER BY InvoiceYear, si.CustomerAccount;
