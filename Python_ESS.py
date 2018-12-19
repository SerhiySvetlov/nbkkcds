#----------------------------collecting excel data  and creating one consolidated excel file--------------------
import numpy as np
import pandas as pd
ESSMonthlyPMSR = pd.read_excel('C:\Sergei\ESS_Tax_Automation_SergeiFile\ESS Monthly PMSR  Report.xlsx',sheet_name='ACH', usecols = "A,L,M")
FNMASecuritization = pd.read_excel('C:\Sergei\ESS_Tax_Automation_SergeiFile\FNMA Securitization.xlsx',sheet_name='Excel Calcs', skiprows=1, usecols = "A,N:Q")
ESSMonthlySecondaryReport = pd.read_excel('C:\Sergei\ESS_Tax_Automation_SergeiFile\ESS Monthly Secondary Report.xlsx',sheet_name='ACH', usecols = "A,B,L:M")
ExcessServiceFeeReportFHLMCConsolidated = pd.read_excel('C:\Sergei\ESS_Tax_Automation_SergeiFile\ExcessServiceFeeReport  FHLMC Consolidated.xlsx',sheet_name='Monthly Collections (P102)', usecols = "A,S,T:U")

writer = pd.ExcelWriter(r"M:\Finance\Loan Accounting\ESS_Tax_Automation_SergeiFile\ESS_Data_Source.xlsx", engine = 'xlsxwriter')
ESSMonthlyPMSR.to_excel(writer,sheet_name='ESSMonthlyPMSR')
FNMASecuritization.to_excel(writer,sheet_name='FNMASecuritization')
ESSMonthlySecondaryReport.to_excel(writer,sheet_name= 'ESSMonthlySecondaryReport')
ExcessServiceFeeReportFHLMCConsolidated.to_excel(writer,sheet_name= 'ESFeeReportFHLMCConsolidated')

writer.save()
writer.close()
#-----------------------------------Uploading to SQL---------------------------------------------------------------
import pyodbc
server = '10.3.17.74' 
database = 'LoanInventory' 
username = 'LAT_RDS' 
password = 'LAT_6k29nae_RDS_$1' 
cnxn = pyodbc.connect('DRIVER={ODBC Driver 13 for SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD='+ password)
cursor = cnxn.cursor()
book = xlrd.open_workbook("C:\Sergei\ESS_Tax_Automation_SergeiFile\ESS_Data_Source.xlsx")
sheet = book.sheet_by_name("ESSMonthlySecondaryReport")
cursor.execute("truncate table ESSMonthlySecondaryReport") 
query = """INSERT INTO ESSMonthlySecondaryReport([F1],[LoanNumber],[Channel],[PLS Retained Excess  S/F Amt],[PMH Excess S/F Amt])VALUES (?,?,?,?,?)"""

for r in range(1, sheet.nrows):
    F1 = sheet.cell(r,0).value    
    LoanNumber = sheet.cell(r,1).value
    Channel = sheet.cell(r,2).value
    PLSRetainedExcessAmt = sheet.cell(r,3).value
    PMHExcessAmt = sheet.cell(r,4).value
    values = (F1,LoanNumber,Channel,PLSRetainedExcessAmt ,PMHExcessAmt)
    cursor.execute(query, values)

cnxn.commit()
cursor.close()


import pyodbc
server = '10.3.17.74' 
database = 'LoanInventory' 
username = 'LAT_RDS' 
password = 'LAT_6k29nae_RDS_$1' 
cnxn = pyodbc.connect('DRIVER={ODBC Driver 13 for SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD='+ password)
cursor = cnxn.cursor()
book = xlrd.open_workbook("C:\Sergei\ESS_Tax_Automation_SergeiFile\ESS_Data_Source.xlsx")
sheet = book.sheet_by_name("ESFeeReportFHLMCConsolidated")
cursor.execute("truncate table ESFeeReportFHLMCConsolidated") 
query = """INSERT INTO ESFeeReportFHLMCConsolidated([LoanNumber],[ServiceFeesAmount],[BasePMCSFeeAmt],[PMHSFeeAmt])VALUES (?,?,?,?)"""

for r in range(1, sheet.nrows):
    LoanNumber = sheet.cell(r,1).value
    ServiceFeesAmount = sheet.cell(r,2).value
    BasePMCSFeeAmt = sheet.cell(r,3).value
    PMHSFeeAmt = sheet.cell(r,4).value
    values = (LoanNumber, ServiceFeesAmount,BasePMCSFeeAmt,PMHSFeeAmt)
    cursor.execute(query, values)

cnxn.commit()
cursor.close()

import pyodbc
server = '10.3.17.74' 
database = 'LoanInventory' 
username = 'LAT_RDS' 
password = 'LAT_6k29nae_RDS_$1' 
cnxn = pyodbc.connect('DRIVER={ODBC Driver 13 for SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD='+ password)
cursor = cnxn.cursor()
book = xlrd.open_workbook("C:\Sergei\ESS_Tax_Automation_SergeiFile\ESS_Data_Source.xlsx")
sheet = book.sheet_by_name("FNMASecuritization")
cursor.execute("truncate table FNMASecuritization") 
query = """INSERT INTO FNMASecuritization([F1],[Loanid],[Base Amt],[Callable Strip Amt],[Sold MSR Excess S/F Amt],[Retained MSR Excess S/F Amt])VALUES (?,?,?,?,?,?)"""

for r in range(1, sheet.nrows):
    F1 = sheet.cell(r,0).value    
    Loanid = sheet.cell(r,1).value
    BaseAmt = sheet.cell(r,2).value
    CallableStripAmt = sheet.cell(r,3).value
    SoldMSRExcessAmt = sheet.cell(r,4).value
    RetainedMSRExcessAmt = sheet.cell(r,5).value
    values = (F1,Loanid,BaseAmt,CallableStripAmt ,SoldMSRExcessAmt,RetainedMSRExcessAmt)
    cursor.execute(query, values)

cnxn.commit()
cursor.close()

import pyodbc
server = '10.3.17.74' 
database = 'LoanInventory' 
username = 'LAT_RDS' 
password = 'LAT_6k29nae_RDS_$1' 
cnxn = pyodbc.connect('DRIVER={ODBC Driver 13 for SQL Server};SERVER='+server+';DATABASE='+database+';UID='+username+';PWD='+ password)
cursor = cnxn.cursor()
book = xlrd.open_workbook("C:\Sergei\ESS_Tax_Automation_SergeiFile\ESS_Data_Source.xlsx")
sheet = book.sheet_by_name("ESSMonthlyPMSR")
cursor.execute("truncate table ESSMonthlyPMSR") 
query = """INSERT INTO ESSMonthlyPMSR([F1],[LoanNumber],[PLS Retained Excess  S/F Am],[PMH Excess S/F Amt])VALUES (?,?,?,?)"""

for r in range(1, sheet.nrows):
    F1 = sheet.cell(r,0).value    
    LoanNumber = sheet.cell(r,1).value
    PLSRetainedExcessAmt = sheet.cell(r,2).value
    PMHExcessAmt = sheet.cell(r,3).value
    values = (F1,LoanNumber,PLSRetainedExcessAmt,PMHExcessAmt)
    cursor.execute(query, values)

cnxn.commit()
cursor.close()