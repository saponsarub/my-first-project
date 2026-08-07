SELECT 
    Year(si.InvoiceDate) AS InvoiceYear,
    si.CustomerAccount,
    si.CustomerName,
    Sum(si.LineAmount) AS SUMtSell
FROM syndpdev001.dbo.tb_SalesInvoice si
WHERE si.SysCompanyId = 'DRPH'
GROUP BY 
    Year(si.InvoiceDate),
    si.CustomerAccount,
    si.CustomerName
ORDER BY InvoiceYear, si.CustomerAccount;
