-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
Use LoanInventory
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
-- Exec sp_ESS @ReportDate ='20181031'

Alter PROCEDURE [dbo].sp_ESS (@ReportDate as varchar(20))-- ='20180930' )
AS
BEGIN

insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '0/24 ESS Monthly Report - uploading LAR data to staging server' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, '' 

--declare @ReportDate as varchar(20) = '20181031' 
exec [dbo].[sp_lar_daily] @ReportDate = @ReportDate,  @ProcessType = 'Upload LAR Daily',  @UserID  = 'ESS monthly process', @RunLog = 1

insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '1/24 ESS Monthly Report - updating Service Fees Amount  in [PLSBuyBack]' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, '' 

UPDATE    LoanInventory.dbo.PLSBuyBack
SET              [Service Fees Amount Prime] = b.TotalServicingFee
FROM         LoanInventory.dbo.PLSBuyBack LEFT OUTER JOIN
(
SELECT     ReportDate, LoanNumber, OldLoanNumber, TotalServicingFee
FROM          [lar_daily] AS a
WHERE      (ReportDate = @ReportDate) AND (ABS(TotalServicingFee) <> 0)
) AS b ON LoanInventory.dbo.PLSBuyBack.[Primary Portfolio Loan #] = b.LoanNumber



UPDATE    LoanInventory.dbo.PLSBuyBack
SET              [Service Fees Amount Secondary] = b.TotalServicingFee
--select *
FROM         LoanInventory.dbo.PLSBuyBack LEFT OUTER JOIN
(
SELECT     ReportDate, LoanNumber, OldLoanNumber, TotalServicingFee
FROM           [lar_daily] AS a
WHERE      (ReportDate = @ReportDate) AND (ABS(TotalServicingFee) <> 0)
) AS b ON LoanInventory.dbo.PLSBuyBack.[Secondary Portfolio Loan #] = b.LoanNumber
where  ABS(isnull([Service Fees Amount Prime],0)) = 0 

insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '2/24 ESS Monthly Report - updating  [Primary Portfolio XSIO Remittance]  and [Secondary Portfolio XSIO Remittance] in [PLSBuyBack]' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, ''

update [LoanInventory].[dbo].[PLSBuyBack]	
set  [Primary Portfolio XSIO Remittance] = 0,	[Secondary Portfolio XSIO Remittance] =0--, [Primary Portfolio XSIO Remittance] =0  -- ,[Secondary Portfolio XSIO Remittance] 

Update [LoanInventory].[dbo].[PLSBuyBack]
set  [Primary Portfolio XSIO Remittance]  = (cast([PMH S F%] as float)/cast([FirstServiceFeeRt] as float))*cast([Service Fees Amount Prime] as float)
where cast([Service Fees Amount Prime] as float) <> 0 

Update [LoanInventory].[dbo].[PLSBuyBack]
set  [Secondary Portfolio XSIO Remittance]  = (cast([PMH S F%] as float)/cast([Servicing Fee Rate - Secondary] as float))*cast([Service Fees Amount Secondary] as float)
where cast([Service Fees Amount Secondary] as float) <> 0 
	
insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '3/24 ESS Monthly Report - uploading new new data (new Strips#) into PLS_TRSESSConsolidatedFile' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, ''

 INSERT INTO PLS_TRSESSConsolidatedFile
                      ([New MSP Loan # as of August 2014], [Strip #], [File Source Code])
SELECT     b.[Loan Number], b.[Strip #], b.[File Source Code]
FROM         PLS_TRSESSConsolidatedFile AS a RIGHT OUTER JOIN
                      ESS_New AS b ON CASE WHEN isnull(CAST(a.[New MSP Loan # as of August 2014] AS float), 0) 
                      <> 0 THEN a.[New MSP Loan # as of August 2014] ELSE a.[Secondary Portfolio Loan #] END = b.[Loan Number]
WHERE     (a.[Strip #] IS NULL)

------------------------------Update UPB in ESS-----------------------------------
insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '4/24 ESS Monthly Report - updating UPB in PLS_TRSESSConsolidatedFile' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, ''

--declare @ReportDate as varchar(20) ='20180930' 
UPDATE   LoanInventory.dbo.PLS_TRSESSConsolidatedFile 
SET [Investor Cut-off UPB - Primary Portfolio] = 0, [Investor Cut-off UPB - Secondary  Portfolio] = 0

UPDATE    PLS_TRSESSConsolidatedFile
SET   [Primary Portfolio XSIO Remittance]   = b.[Primary Portfolio XSIO Remittance]
	, [Secondary Portfolio XSIO Remittance] = b.[Secondary Portfolio XSIO Remittance]
-- select *
FROM        
 PLS_TRSESSConsolidatedFile INNER JOIN PLSBuyBack AS b 

ON PLS_TRSESSConsolidatedFile.[New MSP Loan # as of August 2014] = b.[New MSP Loan # as of August 2014] AND 
    PLS_TRSESSConsolidatedFile.[Secondary Portfolio Loan #] = b.[Secondary Portfolio Loan #] AND 
	PLS_TRSESSConsolidatedFile.[Strip #] = b.[Strip #] AND 
    PLS_TRSESSConsolidatedFile.[File Source Code] = 2

--declare @ReportDate as varchar(20) ='20180930'

insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '5/24 ESS Monthly Report - updating [Investor Cut-off UPB] in PLS_TRSESSConsolidatedFile from LAR' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, ''

UPDATE   a
SET             a.[Investor Cut-off UPB - Secondary  Portfolio] = b.UPB
--declare @ReportDate as varchar(20) ='20180930' select *
FROM         LoanInventory.dbo.PLS_TRSESSConsolidatedFile a LEFT OUTER JOIN
(
SELECT     ReportDate, LoanNumber, OldLoanNumber, CurrentCombinedUPB as UPB
FROM         [lar_daily] AS a
WHERE      (ReportDate = @ReportDate) 
) AS b 
ON isnull(CAST(a.[Secondary Portfolio Loan #] AS float), 0) = b.LoanNumber
where len(a.[Secondary Portfolio Loan #]) > 1 -- and [Secondary Portfolio Loan #]='8018101811'

UPDATE   a
SET             a.[Investor Cut-off UPB - Primary Portfolio] = b.UPB
--declare @ReportDate as varchar(20) ='20180930' select *
FROM         LoanInventory.dbo.PLS_TRSESSConsolidatedFile a LEFT OUTER JOIN
(
SELECT     ReportDate, LoanNumber, OldLoanNumber, CurrentCombinedUPB as UPB
FROM         [lar_daily] AS a
WHERE      (ReportDate = @ReportDate) 
) AS b 
ON isnull(CAST(a.[New MSP Loan # as of August 2014] AS float), 0) = b.LoanNumber


-----------------------------------Update new population from secondary-----------------------------------------------
insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '6/24 ESS Monthly Report - updating [Secondary Portfolio Loan] in PLS_TRSESSConsolidatedFile from LAR LoanNumber' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, ''
UPDATE    PLS_TRSESSConsolidatedFile
SET              [Secondary Portfolio Loan #] = b_1.LoanNumber
--select * 
FROM         PLS_TRSESSConsolidatedFile INNER JOIN
(
SELECT     LoanNumber, OldLoanNumber
FROM          [lar_daily] AS a
WHERE      
(LoanNumber IN
(
SELECT distinct a.[Secondary Portfolio Loan #]
FROM         ESS a  left JOIN
                      PLS_TRSESSConsolidatedFile b ON a.[Strip #] = b.[Strip #] AND 
                      a.[File Source] = b.[File Source Code] AND 
                      --a.[New MSP Loan # as of August 2014] = b.[New MSP Loan # as of August 2014] 
                      isnull(cast(a.[Secondary Portfolio Loan #] as float),0) = isnull(cast(b.[Secondary Portfolio Loan #] as float),0)
where isnull(cast(a.[Secondary Portfolio Loan #] as float),0) <> 0 and isnull(cast(b.[Secondary Portfolio Loan #] as float),0) = 0  
)
) AND (ReportDate = @ReportDate)
) AS b_1 ON 
PLS_TRSESSConsolidatedFile.[New MSP Loan # as of August 2014] = b_1.OldLoanNumber and [File Source Code] = 1


insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '7/24 ESS Monthly Report - creating [##Main] table from PLS_TRSESSConsolidatedFile table for Strip# [ESS]' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, ''

drop table ##Main
select distinct 
[Strip #]
, [New MSP Loan # as of August 2014]
into ##Main
from [LoanInventory].[dbo].[PLS_TRSESSConsolidatedFile]

--------------------------------------------------------------------
insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '8/24 ESS Monthly Report - drop and create ESS table from Excel input files' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, ''
drop table  ESS

select *
into ESS
from
(

SELECT     [Strip #], [File Source], [File Source Name], [New MSP Loan # as of August 2014], [Secondary Portfolio Loan #], SUM([Primary Portfolio XSIO Remittance]) AS [Primary Portfolio XSIO Remittance], 
                      SUM([Secondary Portfolio XSIO Remittance]) AS[Secondary Portfolio XSIO Remittance], source
FROM         (SELECT     b.[Strip #], 1 AS [File Source], 'GNMA' AS [File Source Name], a.LoanNumber AS [New MSP Loan # as of August 2014], 0 AS [Secondary Portfolio Loan #], 
                                              a.[PMH Excess S/F Amt] AS [Primary Portfolio XSIO Remittance], 0 AS [Secondary Portfolio XSIO Remittance], 'ESSMonthlyPMSR' AS source
                       FROM          ESSMonthlyPMSR AS a LEFT OUTER JOIN
                                                  (SELECT DISTINCT [Strip #], [New MSP Loan # as of August 2014], [Investor Cut-off UPB - Primary Portfolio]
                                                    FROM          PLS_TRSESSConsolidatedFile) AS b ON a.LoanNumber = b.[New MSP Loan # as of August 2014]
                       WHERE      (a.[PMH Excess S/F Amt] <> 0) OR
                                              (CAST(b.[Investor Cut-off UPB - Primary Portfolio] AS float) <> 0)) AS P
GROUP BY [Strip #], [File Source], [File Source Name], [New MSP Loan # as of August 2014], [Secondary Portfolio Loan #], source

union all

SELECT     [Strip #], [File Source], [File Source Name], [New MSP Loan # as of August 2014], SUM([Secondary Portfolio Loan #]) AS Expr1, 
                      SUM([Primary Portfolio XSIO Remittance]) AS Expr2, [Secondary Portfolio XSIO Remittance], source
FROM         (SELECT     b.[Strip #], 3 AS [File Source], 'FHLMC' AS [File Source Name], a.LoanNumber AS [New MSP Loan # as of August 2014], 0 AS [Secondary Portfolio Loan #], 
                                              a.PMHSFeeAmt AS [Primary Portfolio XSIO Remittance], 0 AS [Secondary Portfolio XSIO Remittance], 'ESFeeReportFHLMCConsolidated' AS source
                       FROM          ESFeeReportFHLMCConsolidated AS a LEFT OUTER JOIN
                                                  (SELECT DISTINCT [Strip #], [New MSP Loan # as of August 2014], [Investor Cut-off UPB - Primary Portfolio]
                                                    FROM          PLS_TRSESSConsolidatedFile) AS b ON a.LoanNumber = b.[New MSP Loan # as of August 2014]
                       WHERE      (a.PMHSFeeAmt <> 0) OR
                                              (CAST(b.[Investor Cut-off UPB - Primary Portfolio] AS float) <> 0)) AS P
GROUP BY [Strip #], [File Source], [File Source Name], [New MSP Loan # as of August 2014], [Secondary Portfolio XSIO Remittance], source

union all

SELECT     
[Strip #]
, [File Source]
, [File Source Name]
, [New MSP Loan # as of August 2014]
, [Secondary Portfolio Loan #]
, SUM([Primary Portfolio XSIO Remittance]) AS [Primary Portfolio XSIO Remittance]
, SUM([Secondary Portfolio XSIO Remittance]) AS [Secondary Portfolio XSIO Remittance]
, source
FROM         
(
SELECT     b.[Strip #], 4 AS [File Source], 'Callable' AS [File Source Name], a.Loanid AS [New MSP Loan # as of August 2014], 0 AS [Secondary Portfolio Loan #], 
a.[Callable Strip Amt] AS [Primary Portfolio XSIO Remittance], 0 AS [Secondary Portfolio XSIO Remittance], 'FNMASecuritization' AS source
FROM          FNMASecuritization AS a LEFT OUTER JOIN
(
SELECT DISTINCT [Strip #], [New MSP Loan # as of August 2014], [Investor Cut-off UPB - Primary Portfolio]
FROM          PLS_TRSESSConsolidatedFile
) AS b ON a.Loanid = b.[New MSP Loan # as of August 2014]
WHERE      (a.[Callable Strip Amt] <> 0) OR
(CAST(b.[Investor Cut-off UPB - Primary Portfolio] AS float) <> 0)
) AS P
GROUP BY [Strip #], [File Source], [File Source Name], [New MSP Loan # as of August 2014], [Secondary Portfolio Loan #], source

union all

SELECT   
  [Strip #]
  , [File Source]
  , [File Source Name]
  , [New MSP Loan # as of August 2014]
  , [Secondary Portfolio Loan #]
  , SUM([Primary Portfolio XSIO Remittance]) AS [Primary Portfolio XSIO Remittance]
  , SUM([Secondary Portfolio XSIO Remittance]) AS [Secondary Portfolio XSIO Remittance]
  , source
FROM         
(
SELECT     b.[Strip #], 3 AS [File Source], 'FNMA' AS [File Source Name], a.Loanid AS [New MSP Loan # as of August 2014], 0 AS [Secondary Portfolio Loan #], 
a.[Sold MSR Excess S/F Amt] AS [Primary Portfolio XSIO Remittance], 0 AS [Secondary Portfolio XSIO Remittance], 'FNMASecuritization' AS source
FROM          FNMASecuritization AS a LEFT OUTER JOIN
(
SELECT DISTINCT [Strip #], [New MSP Loan # as of August 2014], [Investor Cut-off UPB - Primary Portfolio]
FROM          PLS_TRSESSConsolidatedFile
) 
AS b ON a.Loanid = b.[New MSP Loan # as of August 2014]
WHERE      (a.[Sold MSR Excess S/F Amt] <> 0) OR
(CAST(b.[Investor Cut-off UPB - Primary Portfolio] AS float) <> 0)
) 
AS P
GROUP BY [Strip #], [File Source], [File Source Name], [New MSP Loan # as of August 2014], [Secondary Portfolio Loan #], source

union all

 SELECT 
   a.[Strip #]
 , 2 [File Source]
 , 'PLS Buyback' as [File Source Name]
 , cast([New MSP Loan # as of August 2014] as float) [New MSP Loan # as of August 2014]
 , cast([Secondary Portfolio Loan #] as float)  [Secondary Portfolio Loan #]
 , cast([Primary Portfolio XSIO Remittance] as float) [Primary Portfolio XSIO Remittance]
 , cast([Secondary Portfolio XSIO Remittance] as float) [Secondary Portfolio XSIO Remittance]
 , 'PLS Buyback' source
 FROM [dbo].[PLSBuyBack]  a

 union all

SELECT     [Strip #], [File Source], [File Source Name], [New MSP Loan # as of August 2014], [Secondary Portfolio Loan #], SUM([Primary Portfolio XSIO Remittance]) AS Expr1, 
                      SUM([Secondary Portfolio XSIO Remittance]) AS Expr2, source
FROM         (SELECT     b.[Strip #], 1 AS [File Source], 'GNMA' AS [File Source Name], 0 AS [New MSP Loan # as of August 2014], a.LoanNumber AS [Secondary Portfolio Loan #], 
                                              0 AS [Primary Portfolio XSIO Remittance], CAST(a.[PMH Excess S/F Amt] AS float) AS [Secondary Portfolio XSIO Remittance], 
                                              'ESSMonthlySecondaryReport' AS source
                       FROM          ESSMonthlySecondaryReport AS a LEFT OUTER JOIN
                                                  (SELECT DISTINCT [Strip #], [Secondary Portfolio Loan #] AS [New MSP Loan # as of August 2014], [Investor Cut-off UPB - Secondary  Portfolio]
                                                    FROM          PLS_TRSESSConsolidatedFile) AS b ON a.LoanNumber = b.[New MSP Loan # as of August 2014]
                       WHERE      (a.[PMH Excess S/F Amt] <> 0) OR
                                              (CAST(b.[Investor Cut-off UPB - Secondary  Portfolio] AS float) <> 0)) AS P
GROUP BY [Strip #], [File Source], [File Source Name], [New MSP Loan # as of August 2014], [Secondary Portfolio Loan #], source

 ) ESS

insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '9/24 ESS Monthly Report - uploading new new data (new Strips#) into ESS' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, ''
 
INSERT INTO ESS
                      ([New MSP Loan # as of August 2014], [Strip #], [File Source], [File Source Name], source)

SELECT  distinct   b.[Loan Number], b.[Strip #], b.[File Source Code], case when [File Source Code] = 3 then 'FNMA' when [File Source Code] = 4 then 'Callable' WHEN [File Source Code] = 2 THEN 'PLS Buyback' else 'N/A' end, 'ESS New' source
FROM         ESS AS a  right JOIN
ESS_New AS b ON CASE WHEN isnull(CAST(a.[New MSP Loan # as of August 2014] AS float), 0) <> 0 THEN a.[New MSP Loan # as of August 2014] ELSE a.[Secondary Portfolio Loan #] END = b.[Loan Number]
WHERE   (a.[Strip #] IS NULL)

------------------------deleting 3 loans from output and using Rod data for these 3 loans--------------------------------------
delete
FROM  ESS
WHERE     ([New MSP Loan # as of August 2014] IN ('8000093355', '8000082818', '8000550612'))

-- select * from ESS_new where [Strip #] = 47    select * from ESS where [Strip #] = '47'   select 7437 - 6594  (select 8786 + 843)

 ----------------------------New Strips--------------------------------------------------
 --select *  FROM [dbo].[ESSMonthlySecondaryReport] where loanNumber = 7000221261 
-- UPDATE    ESS
--SET              [Strip #] = b.[Strip #]
----select *
--FROM         ESS LEFT OUTER JOIN
--ESS_New AS b ON ESS.[New MSP Loan # as of August 2014] = b.[Loan Number] AND ESS.[File Source] = b.[File Source Code]
--WHERE     (ESS.[Strip #] IS NULL) AND (b.[Strip #] IS not NULL)

-- UPDATE    ESS
--SET              [Strip #] = b.[Strip #]
----select distinct *
--FROM         ESS a JOIN
--                      ESS_New AS b ON a.[Secondary Portfolio Loan #] = b.[Loan Number] AND a.[File Source] = b.[File Source Code]
--WHERE     (a.[Strip #] IS NULL) AND (b.[Strip #] IS not NULL)

insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '10/24 ESS Monthly Report - updating Strips# in ESS' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, ''
 UPDATE    ESS
SET [Strip #] = b.[Strip #]
--select  ESS.[New MSP Loan # as of August 2014] , ESS.[Strip #], b.[Strip #]
FROM         ESS  JOIN
PLS_TRSESSConsolidatedFile AS b 
ON 
ESS.[New MSP Loan # as of August 2014] = b.[New MSP Loan # as of August 2014] AND 
ESS.[File Source] = b.[File Source Code]
WHERE     (ESS.[Strip #] IS NULL) AND (b.[Strip #] IS not NULL) and ESS.[New MSP Loan # as of August 2014] <> 0 

 UPDATE    ESS
SET              [Strip #] = b.[Strip #]
--select  a.[Strip #], b.[Strip #]
FROM         ESS a JOIN
PLS_TRSESSConsolidatedFile AS b ON 
a.[Secondary Portfolio Loan #] = b.[Secondary Portfolio Loan #] AND 
a.[File Source] = b.[File Source Code]
WHERE LEN(a.[Secondary Portfolio Loan #] ) >1  and   (a.[Strip #] IS NULL) AND (b.[Strip #] IS not NULL)  


-----------------------------------Added new population from income Excel ESS file for secondary population to static table-----------------------------------------------
--declare @ReportDate as varchar(20) ='20180831' 

ALTER TABLE dbo.ESS ADD [UPB] float(53) NULL, [UPB Second] float(53) NULL;

insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '11/24 ESS Monthly Report - Added new population from income Excel ESS file for secondary population to static table' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, ''

INSERT INTO PLS_TRSESSConsolidatedFile
                      ([Strip #], [File Source Code], [New MSP Loan # as of August 2014], [Secondary Portfolio Loan #], [Primary Portfolio XSIO Remittance], 
                      [Secondary Portfolio XSIO Remittance], [Investor Cut-off UPB - Primary Portfolio], [Investor Cut-off UPB - Secondary  Portfolio])
SELECT distinct  
'Not Available' AS Expr1
, a.[File Source]
, a.[New MSP Loan # as of August 2014]
, round(cast(a.[Secondary Portfolio Loan #] as bigint),0)
, a.[Primary Portfolio XSIO Remittance], 
a.[Secondary Portfolio XSIO Remittance]
, a.UPB
, a.[UPB Second]
FROM         ESS AS a LEFT OUTER JOIN
                      PLS_TRSESSConsolidatedFile AS b 
ON --a.[Strip #] = b.[Strip #] AND 
--a.[File Source] = b.[File Source Code] AND 
ISNULL(a.[Secondary Portfolio Loan #] , '') = ISNULL(b.[Secondary Portfolio Loan #] , '') 
WHERE    len(a.[Secondary Portfolio Loan #]) > 1 and  ISNULL(CAST(b.[Secondary Portfolio Loan #] AS float), 0) = 0

-----------------------------------Update UPB income Excel ESS file -----------------------------------------------
--declare @ReportDate as varchar(20) ='20180930'
insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '12/24 ESS Monthly Report - Updating UPB in ESS table' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, ''

UPDATE   LoanInventory.dbo.ESS
SET [UPB] = 0, [UPB Second] = 0

UPDATE   a
SET             a. [UPB Second] = b.UPB
--declare @ReportDate as varchar(20) ='20180930' select *
FROM        ESS a LEFT OUTER JOIN
(
SELECT     ReportDate, LoanNumber, OldLoanNumber, CurrentCombinedUPB as UPB
FROM         [lar_daily] AS a
WHERE      (ReportDate = @ReportDate) 
) AS b 
ON isnull(CAST(a.[Secondary Portfolio Loan #] AS float), 0) = b.LoanNumber
where len(a.[Secondary Portfolio Loan #]) >1 -- and [Secondary Portfolio Loan #]='8018101811'

UPDATE   a
SET             a. [UPB]= b.UPB
--declare @ReportDate as varchar(20) ='20180930' select *
FROM         LoanInventory.dbo.ESS a LEFT OUTER JOIN
(
SELECT     ReportDate, LoanNumber, OldLoanNumber, CurrentCombinedUPB as UPB
FROM         [lar_daily] AS a
WHERE      (ReportDate = @ReportDate) 
) AS b 
ON isnull(CAST(a.[New MSP Loan # as of August 2014] AS float), 0) = b.LoanNumber

----------------------------------Update Data from excel upload to static table------------------------------------------------
insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '13/24 ESS Monthly Report - Updating  [Secondary Portfolio Loan #] from LAR LoanNumber in ESS table' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, ''

UPDATE    ESS
SET              [Secondary Portfolio Loan #] = b_1.LoanNumber
--declare @ReportDate as varchar(20) ='20180930' select *
FROM         ESS INNER JOIN
(
SELECT     LoanNumber, OldLoanNumber
FROM          [lar_daily] AS a
WHERE      (LoanNumber IN
(SELECT DISTINCT a.LoanNumber
    FROM          ESSMonthlySecondaryReport AS a LEFT OUTER JOIN
                        ESS AS b ON a.LoanNumber = b.[Secondary Portfolio Loan #]
    WHERE      (b.[Secondary Portfolio Loan #] IS NULL))) AND (ReportDate = @ReportDate)
) AS b_1 ON 
ESS.[New MSP Loan # as of August 2014] = b_1.OldLoanNumber;

insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '14/24 ESS Monthly Report - Updating [Secondary Portfolio XSIO Remittance] and Second UPB in PLS_TRSESSConsolidatedFile  table from ESS' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, '';

update  PLS_TRSESSConsolidatedFile
Set [Primary Portfolio XSIO Remittance] =0,	[Secondary Portfolio XSIO Remittance] = 0

update  b
Set 	b.[Secondary Portfolio XSIO Remittance] = c.[Secondary Portfolio XSIO Remittance],  [Investor Cut-off UPB - Secondary  Portfolio] =  c.[UPB Second]
--SELECT     c.[Secondary Portfolio Loan #], c.[Secondary Portfolio XSIO Remittance], b.[Secondary Portfolio Loan #], b.[UPB Second]
FROM         PLS_TRSESSConsolidatedFile AS b INNER JOIN
(
SELECT     [Strip #], [File Source], [File Source Name], [Secondary Portfolio Loan #], SUM([Secondary Portfolio XSIO Remittance])  AS [Secondary Portfolio XSIO Remittance], [UPB Second]
FROM          ESS
GROUP BY [Strip #], [File Source], [File Source Name], [Secondary Portfolio Loan #], [UPB Second]
) AS c ON 
b.[Strip #] = c.[Strip #] AND 
b.[File Source Code] = c.[File Source] AND 
isnull(cast(b.[Secondary Portfolio Loan #] as float),0) = isnull(cast(c.[Secondary Portfolio Loan #] as float),0)
WHERE   isnull(cast(c.[Secondary Portfolio Loan #] as float),0) <> 0;

insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '15/24 ESS Monthly Report - Updating [Prime Portfolio XSIO Remittance] and UPB in PLS_TRSESSConsolidatedFile  table from ESS' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, ''

update  b
Set 	b.[Primary Portfolio XSIO Remittance] = c.[Primary Portfolio XSIO Remittance], b.[Investor Cut-off UPB - Primary Portfolio] = c.[UPB] 

----declare @ReportDate as varchar(20) ='20180930' select     	b.[Primary Portfolio XSIO Remittance] , c.[Primary Portfolio XSIO Remittance], b.[Investor Cut-off UPB - Primary Portfolio] , c.[UPB]
FROM         PLS_TRSESSConsolidatedFile AS b INNER JOIN
(
SELECT     [Strip #], [File Source], [File Source Name], [New MSP Loan # as of August 2014] , SUM([Primary Portfolio XSIO Remittance]) AS [Primary Portfolio XSIO Remittance],  [UPB] 
FROM          ESS
GROUP BY [Strip #], [File Source], [File Source Name], [New MSP Loan # as of August 2014],   [UPB] 
) AS c ON 
b.[Strip #] = c.[Strip #] AND 
b.[File Source Code] = c.[File Source] AND 
isnull(cast(b.[New MSP Loan # as of August 2014] as float),0) = isnull(cast(c.[New MSP Loan # as of August 2014] as float),0)
WHERE   isnull(cast(c.[New MSP Loan # as of August 2014] as float),0) <> 0 ;

insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '16/24 ESS Monthly Report - Updating [New MSP Loan # as of August 2014] from PLS_TRSESSConsolidatedFile table' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, ''

UPDATE    ESS
SET              [New MSP Loan # as of August 2014] = PLS_TRSESSConsolidatedFile.[New MSP Loan # as of August 2014]
----declare @ReportDate as varchar(20) ='20180930'  select  ESS.[New MSP Loan # as of August 2014] , PLS_TRSESSConsolidatedFile.[New MSP Loan # as of August 2014]
FROM         PLS_TRSESSConsolidatedFile INNER JOIN
ESS 
ON PLS_TRSESSConsolidatedFile.[Strip #] = ESS.[Strip #] AND 
PLS_TRSESSConsolidatedFile.[File Source Code] = ESS.[File Source] AND 
ISNULL(CAST(PLS_TRSESSConsolidatedFile.[Secondary Portfolio Loan #] AS float), 0) = ISNULL(CAST(ESS.[Secondary Portfolio Loan #] AS float), 0)
WHERE     (ISNULL(PLS_TRSESSConsolidatedFile.[New MSP Loan # as of August 2014], '') <> '') AND (ISNULL(CAST(ESS.[Secondary Portfolio Loan #] AS float), 0) <> 0) AND 
(ESS.[New MSP Loan # as of August 2014] = 0);
-----------------------------------------------------------------------------------------------------------------------
insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '17/24 ESS Monthly Report - Creating temp ##temp_ess table where fees = 0 but UPB <>0' as ProcessType 
, @ReportDate as ReportDate, 'SQL Sp' as UserId, ''

--declare @ReportDate as varchar(20) ='20180930' 
IF 0 < OBJECT_ID('tempdb.dbo.##temp_ess') DROP TABLE  tempdb.dbo.##temp_ess

select a.* 
into  ##temp_ess
from PLS_TRSESSConsolidatedFile a
 left join
(
select * from ESS b where  b.[File Source] is null
)
b
on ISNULL(cast(a.[New MSP Loan # as of August 2014]  as float),0) =  ISNULL(cast(b.[New MSP Loan # as of August 2014]  as float),0)
where  cast(a.[Investor Cut-off UPB - Primary Portfolio]  as float) <> 0 and 
cast(a.[Primary Portfolio XSIO Remittance] as float) = 0 and 
cast(a.[Secondary Portfolio XSIO Remittance] as float) = 0 

-- select * from   ##temp_ess where  [New MSP Loan # as of August 2014] = '1001926212'
-------------------------------------------------------------------------------------------------------------------------------------------------------------
--declare @ReportDate as varchar(20) ='20181031' 
insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '18/24 ESS Monthly Report - uploading records where fees = 0 but UPB <>0 to ESS table' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, ''

INSERT INTO ESS
                      ([Strip #], [File Source], [New MSP Loan # as of August 2014], [Secondary Portfolio Loan #], [Primary Portfolio XSIO Remittance], [Secondary Portfolio XSIO Remittance], 
                      UPB, [UPB Second],source, [File Source Name])
SELECT  a.[Strip #], a.[File Source Code], a.[New MSP Loan # as of August 2014], a.[Secondary Portfolio Loan #], a.[Primary Portfolio XSIO Remittance], 
                      a.[Secondary Portfolio XSIO Remittance], a.[Investor Cut-off UPB - Primary Portfolio], a.[Investor Cut-off UPB - Secondary  Portfolio], 'Static file' AS Expr1
					  , case when a.[File Source Code] = 1 then 'GNMA' when a.[File Source Code] = 3 then 'FNMA' when a.[File Source Code] = 4 then 'Callable' WHEN a.[File Source Code] = 2 THEN 'PLS Buyback' else 'N/A'  end
					  --, ESS.*
					  --,  ABS(ABS(ESS.[UPB]) -  ABS(a.[Investor Cut-off UPB - Primary Portfolio]))
FROM         tempdb.dbo.[##temp_ess] a
left join
ESS
on a.[New MSP Loan # as of August 2014] = ESS.[New MSP Loan # as of August 2014]
where    ABS(ABS(isnull(ESS.[UPB],0)) -  ABS(isnull(a.[Investor Cut-off UPB - Primary Portfolio],0))) > 1 
--and ESS.[New MSP Loan # as of August 2014] = 8000166764


insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '19/24 ESS Monthly Report - uploading secondary where fees = 0 but UPB <>0 to ESS table' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, ''

INSERT INTO ESS
                      ([Strip #], [File Source], [New MSP Loan # as of August 2014], [Secondary Portfolio Loan #], [Primary Portfolio XSIO Remittance], [Secondary Portfolio XSIO Remittance], 
                      UPB, [UPB Second], source, [File Source Name])
SELECT   a.[Strip #], a.[File Source Code], a.[New MSP Loan # as of August 2014], a.[Secondary Portfolio Loan #], a.[Primary Portfolio XSIO Remittance], 
                      a.[Secondary Portfolio XSIO Remittance], a.[Investor Cut-off UPB - Primary Portfolio], a.[Investor Cut-off UPB - Secondary  Portfolio], 'Static file' AS Expr1, 
                      CASE WHEN [File Source Code] = 1 THEN 'GNMA' WHEN [File Source Code] = 3 THEN 'FNMA' WHEN [File Source Code] = 4 THEN 'Callable' WHEN [File Source Code] = 2 THEN 'PLS Buyback' else 'N/A' END AS Expr2
FROM         PLS_TRSESSConsolidatedFile AS a LEFT OUTER JOIN
                      ESS AS b ON CAST(a.[Secondary Portfolio Loan #] AS float) = CAST(b.[Secondary Portfolio Loan #] AS float)
WHERE     (CAST(a.[Investor Cut-off UPB - Secondary  Portfolio] AS float) <> 0) AND (CAST(a.[Primary Portfolio XSIO Remittance] AS float) = 0) AND 
                      (CAST(a.[Secondary Portfolio XSIO Remittance] AS float) = 0) and isnull(CAST(b.[Secondary Portfolio Loan #] AS float),0) = 0
-------------------------------------------------------------------------------------------------------------------------------------------------------------
insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '20/24 ESS Monthly Report - updating  [Strip #] = [Not Available] ESS table' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, ''

UPDATE    ESS
SET              [Strip #] = 'Not Available'
--select * from ESS 
WHERE     (ISNULL([Strip #], '') = '')

--declare @ReportDate as varchar(20) ='20180930'

insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '21/24 ESS Monthly Report - deleting prior upload from archive table - ess_monthly_dataset' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, ''

delete from ess_monthly_dataset where ReportMonth = case when len(Cast(Month(@ReportDate) as varchar(10))) =1 then '_0' + Cast(Month(@ReportDate) as varchar(10)) else Cast(Month(@ReportDate) as varchar(10)) end 

insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '22/24 ESS Monthly Report - uploading reporting month to archive table - ess_monthly_dataset' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, ''

--declare @ReportDate as varchar(20) ='20180930'
INSERT INTO  LoanInventory.dbo.ess_monthly_dataset
                      ([Strip #], [File Source], [File Source Name], [New MSP Loan # as of August 2014], [Secondary Portfolio Loan #], [Primary Portfolio XSIO Remittance], 
                      [Secondary Portfolio XSIO Remittance], source, UPB, [UPB Second], ReportMonth)
--declare @ReportDate as varchar(20) ='20180930'
SELECT     [Strip #], [File Source], [File Source Name], [New MSP Loan # as of August 2014], [Secondary Portfolio Loan #], [Primary Portfolio XSIO Remittance], 
                      [Secondary Portfolio XSIO Remittance], source, UPB, [UPB Second], cast(Year(@ReportDate) as varchar(10)) + '_' + 
					  case when len(Cast(Month(@ReportDate) as varchar(10))) =1 then '_0' + Cast(Month(@ReportDate) as varchar(10)) else Cast(Month(@ReportDate) as varchar(10)) end  AS ReportMonth
FROM  LoanInventory.dbo.ESS

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '23/24 ESS Monthly Report - Update [New MSP Loan # as of August 2014] from LAR' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, ''

UPDATE    PLS_TRSESSConsolidatedFile
SET              
  [Strip #] = P.[Strip #]
, [File Source Code] = P.[File Source Code] 
, [New MSP Loan # as of August 2014] = P.[New MSP Loan # as of August 2014]
FROM         PLS_TRSESSConsolidatedFile INNER JOIN
(
SELECT     a.[Strip #], a.[File Source Code], a.[New MSP Loan # as of August 2014], P.[Secondary Portfolio Loan #]
FROM          PLS_TRSESSConsolidatedFile AS a INNER JOIN
(
SELECT     L.OldLoanNumber, b.[New MSP Loan # as of August 2014], b.[Secondary Portfolio Loan #]
FROM          PLS_TRSESSConsolidatedFile AS b INNER JOIN
(
SELECT     ReportDate, LoanNumber, OldLoanNumber, CurrentCombinedUPB AS UPB
FROM          FINSQLPROD1.dw_fin_datamart.dbo.ConsolidatedLoanFinanceActivity AS a
WHERE      (ReportDate = @ReportDate)
) AS L 
ON ISNULL(CAST(b.[Secondary Portfolio Loan #] AS float), 0) = L.LoanNumber
WHERE      (LEN(b.[New MSP Loan # as of August 2014]) < 2) AND (L.LoanNumber IS NOT NULL) AND (LEN(b.[Secondary Portfolio Loan #]) > 0) AND 
(LEN(L.OldLoanNumber) = 10)
) AS P 
ON a.[New MSP Loan # as of August 2014] = P.OldLoanNumber
) AS P ON 
ISNULL(CAST(PLS_TRSESSConsolidatedFile.[Secondary Portfolio Loan #] AS float), 0) = ISNULL(CAST(P.[Secondary Portfolio Loan #] AS float), 0)

UPDATE    ESS
SET              
  [Strip #] = P.[Strip #]
, [File Source] = P.[File Source Code] 
, [New MSP Loan # as of August 2014] = P.[New MSP Loan # as of August 2014]
--select a.[Strip #], 	a.[File Source], 	a.[New MSP Loan # as of August 2014], P.[Strip #], 	P.[File Source Code], 	P.[New MSP Loan # as of August 2014]
 FROM [LoanInventory].[dbo].[ESS] a
 join
 (
SELECT 
a.[Strip #], 	a.[File Source Code], 	a.[New MSP Loan # as of August 2014], P.[Secondary Portfolio Loan #]
 FROM [LoanInventory].[dbo].PLS_TRSESSConsolidatedFile a
 join
 (
SELECT L.OldLoanNumber , b.[New MSP Loan # as of August 2014], b.[Secondary Portfolio Loan #]
 FROM [LoanInventory].[dbo].[ESS] b
join
(
SELECT     ReportDate, LoanNumber, OldLoanNumber, CurrentCombinedUPB as UPB
FROM         [FINSQLPROD1].dw_fin_datamart.dbo.ConsolidatedLoanFinanceActivity AS a
WHERE      (ReportDate = '20181031' --and LoanNumber = 7002414426 
) 
) L
on 
isnull(CAST(b.[Secondary Portfolio Loan #] AS float), 0)= L.LoanNumber
where len(b.[New MSP Loan # as of August 2014]) < 2  and L.LoanNumber is not null
 and len(b.[Secondary Portfolio Loan #]) > 0 and LEN(L.OldLoanNumber) = 10
 ) P
 on 
  isnull(CAST(a.[Secondary Portfolio Loan #]  AS float), 0) = isnull(CAST(P.[Secondary Portfolio Loan #]  AS float), 0)
  where len(a.[New MSP Loan # as of August 2014]) > 2
 ) P
 on 
 isnull(CAST(a.[Secondary Portfolio Loan #] AS float), 0)= isnull(CAST(P.[Secondary Portfolio Loan #] AS float), 0)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

insert into lids_auto_upload_activity_log select  GETDATE() as BeginningTime, '24/24 ESS Monthly Report - End' as ProcessType , @ReportDate as ReportDate, 'SQL Sp' as UserId, ''

UPDATE    lids_auto_upload_activity_log
SET              EndTime = GETDATE()
--select * from  lids_auto_upload_activity_log
WHERE     (BeginningTime >=
                          (SELECT     MAX(BeginningTime) AS Expr1
                            FROM          lids_auto_upload_activity_log AS lids_auto_upload_activity_log_1
                            WHERE      (ProcessType LIKE '0/24 ESS Monthly Report - uploading LAR data to staging server')))
						--order by BeginningTime desc
							
END

---------------------------------QC-------------------------------------------------------------

--SELECT     SUM(CAST([Primary Portfolio XSIO Remittance] AS float)) AS [Primary Portfolio XSIO Remittance],   SUM(CAST([Secondary Portfolio XSIO Remittance] AS float)) 
--                      AS [Secondary Portfolio XSIO Remittance], SUM(CAST([UPB ]  AS float)) AS [UPB],
--					  SUM(CAST([UPB Second]  AS float)) AS [UPB Second],  [File Source]
--FROM         ESS
--GROUP BY  [File Source]

--SELECT     SUM(CAST([Primary Portfolio XSIO Remittance] AS float)) AS [Primary Portfolio XSIO Remittance], SUM(CAST([Secondary Portfolio XSIO Remittance] AS float)) 
--                      AS [Secondary Portfolio XSIO Remittance], [File Source Code]
--, SUM(CAST([Investor Cut-off UPB - Primary Portfolio]  AS float))
--, SUM(CAST([Investor Cut-off UPB - Secondary  Portfolio]  AS float))
--FROM         PLS_TRSESSConsolidatedFile
--GROUP BY [File Source Code]


--SELECT     [Strip #], SUM(UPB) AS UPB, SUM([UPB Second]) AS [UPB 2]
--FROM         ESS AS a
--GROUP BY [Strip #]

--SELECT     [Strip #]
--, SUM(CAST([Investor Cut-off UPB - Primary Portfolio]  AS float))
--, SUM(CAST([Investor Cut-off UPB - Secondary  Portfolio]  AS float))
--FROM  PLS_TRSESSConsolidatedFile AS a
--GROUP BY [Strip #]


--SELECT   *
--FROM         ESS 
--where  [Strip #]= '10' and UPB  <> 0


--SELECT   *
--FROM         PLS_TRSESSConsolidatedFile 
--where  [Strip #]= '10' and CAST([Investor Cut-off UPB - Primary Portfolio]  AS float)  <> 0

-------------------------------------------------------------------------------------------------------------
--SELECT     ESS.[Strip #], ESS.[File Source], ESS.[File Source Name], ESS.[New MSP Loan # as of August 2014], ESS.[Secondary Portfolio Loan #], 
--                      ESS.[Primary Portfolio XSIO Remittance], ESS.[Secondary Portfolio XSIO Remittance], ESS.source, ESS.UPB, ESS.[UPB Second]
--, a.[New MSP Loan # as of August 2014]
--, a.[Investor Cut-off UPB - Primary Portfolio], a.[Investor Cut-off UPB - Secondary  Portfolio]
--FROM         ESS LEFT OUTER JOIN
--                          (SELECT     [Strip #], [File Source Code], [New MSP Loan # as of August 2014], [Secondary Portfolio Loan #], [Primary Portfolio XSIO Remittance], 
--                                                   [Secondary Portfolio XSIO Remittance], [Investor Cut-off UPB - Primary Portfolio], [Investor Cut-off UPB - Secondary  Portfolio]
--                            FROM          PLS_TRSESSConsolidatedFile
--                            WHERE      ([Strip #] = '10') AND (CAST([Investor Cut-off UPB - Primary Portfolio] AS float) <> 0)) AS a ON 
--                      ESS.[New MSP Loan # as of August 2014] = a.[New MSP Loan # as of August 2014] AND ESS.[Strip #] = a.[Strip #]
--WHERE     (ESS.[Strip #] = '10') AND (ESS.UPB <> 0) --AND (a.[New MSP Loan # as of August 2014] IS NULL)


--SELECT   a.*
--FROM         ESS right OUTER JOIN
--                          (SELECT     [Strip #], [File Source Code], [New MSP Loan # as of August 2014], [Secondary Portfolio Loan #], [Primary Portfolio XSIO Remittance], 
--                                                   [Secondary Portfolio XSIO Remittance], [Investor Cut-off UPB - Primary Portfolio], [Investor Cut-off UPB - Secondary  Portfolio]
--                            FROM          PLS_TRSESSConsolidatedFile
--                            WHERE       (CAST([Investor Cut-off UPB - Primary Portfolio] AS float) <> 0)) AS a ON 
--                      ESS.[New MSP Loan # as of August 2014] = a.[New MSP Loan # as of August 2014] AND ESS.[Strip #] = a.[Strip #]
--WHERE     (cast(a.[Investor Cut-off UPB - Primary Portfolio] as float) <> 0) AND (ESS.[New MSP Loan # as of August 2014] IS NULL)


--SELECT  a.[Strip #], a.[File Source Code], a.[New MSP Loan # as of August 2014], a.[Secondary Portfolio Loan #], a.[Primary Portfolio XSIO Remittance], 
--                      a.[Secondary Portfolio XSIO Remittance], a.[Investor Cut-off UPB - Primary Portfolio], a.[Investor Cut-off UPB - Secondary  Portfolio], 'Static file' AS Expr1
--					  , case when a.[File Source Code] = 1 then 'GNMA' when a.[File Source Code] = 3 then 'FNMA' when a.[File Source Code] = 4 then 'Callable' WHEN a.[File Source Code] = 2 THEN 'PLS Buyback' else 'N/A'  end
--					  , ESS.*
--					  ,  ABS(ABS(isnull(ESS.[UPB],0)) -  ABS(isnull(a.[Investor Cut-off UPB - Primary Portfolio],0)))
--FROM         tempdb.dbo.[##temp_ess] a
--left join
--ESS
--on a.[New MSP Loan # as of August 2014] = ESS.[New MSP Loan # as of August 2014]
--where   ABS(ABS(isnull(ESS.[UPB],0)) -  ABS(isnull(a.[Investor Cut-off UPB - Primary Portfolio],0))) > 1 
--and  a.[New MSP Loan # as of August 2014] = 8005730136
-------------------------------------------------------------------------------------------------------------------


--SELECT   *
--FROM         ESS 
--where  [New MSP Loan # as of August 2014] = 1001926212

--SELECT   *
--FROM         PLS_TRSESSConsolidatedFile 
--where  [New MSP Loan # as of August 2014] = '1001926212'

--select * from   ##temp_ess where  [New MSP Loan # as of August 2014] = '8005730136'
--------------------------------------------------------------------------------------------
--select * from lids_auto_upload_activity_log order by BeginningTime desc 
--select distinct ReportMonth from ess_monthly_dataset
-- select * from ESS
--select * from lids_auto_upload_activity_log order by BeginningTime desc 
--select * from lids_auto_upload_activity_log with(noLock) where UserId = 'Python code' order by ReportDate desc

--sp_whoisactive
--kill 103

--SELECT     [Strip #], [File Source], [New MSP Loan # as of August 2014], [Secondary Portfolio Loan #], [Primary Portfolio XSIO Remittance], 
--                      [Secondary Portfolio XSIO Remittance], UPB [Investor Cut-off UPB - Primary Portfolio], [UPB Second] [Investor Cut-off UPB - Secondary  Portfolio]
--FROM         ESS
--where [New MSP Loan # as of August 2014] = 7002339034
-- or [Secondary Portfolio Loan #] = 7002339034


-- SELECT     ReportDate, LoanNumber, OldLoanNumber, CurrentCombinedUPB as UPB
--FROM         [FINSQLPROD1].dw_fin_datamart.dbo.ConsolidatedLoanFinanceActivity AS a
--WHERE      (ReportDate = '20181031' and LoanNumber = 7002339034 ) 

--SELECT * FROM [LoanInventory].[dbo].[PLS_TRSESSConsolidatedFile] where [New MSP Loan # as of August 2014] = '7002339034'   or [Secondary Portfolio Loan #] = '7002339034'

--SELECT * FROM [LoanInventory].[dbo].[PLS_TRSESSConsolidatedFile] where [New MSP Loan # as of August 2014] = '1004274011'   or [Secondary Portfolio Loan #] = '1004274011'


