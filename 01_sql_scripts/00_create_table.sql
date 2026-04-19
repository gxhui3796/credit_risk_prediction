CREATE TABLE row_data(
Id INT,
SeriousDlqin2yrs INT,
RevolvingUtilizationOfUnsecuredLines DOUBLE,
age	INT,
NumberOfTime30_59DaysPastDueNotWorse INT,
DebtRatio DOUBLE,
MonthlyIncome VARCHAR(20),
NumberOfOpenCreditLinesAndLoans INT,	
NumberOfTimes90DaysLate	INT,
NumberRealEstateLoansOrLines INT,	
NumberOfTime60_89DaysPastDueNotWorse INT,	
NumberOfDependents VARCHAR(20) );



load data infile "D:/MySQL/MySQL Server 8.0/Uploads/cs-training.csv"
INTO TABLE risk_credit.row_data
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(
  Id,
  SeriousDlqin2yrs,
  RevolvingUtilizationOfUnsecuredLines,
  age,
  NumberOfTime30_59DaysPastDueNotWorse,
  DebtRatio,
  @MonthlyIncome,
  NumberOfOpenCreditLinesAndLoans,
  NumberOfTimes90DaysLate,
  NumberRealEstateLoansOrLines,
  NumberOfTime60_89DaysPastDueNotWorse,
  @NumberOfDependents
)
SET
  MonthlyIncome = IF(@MonthlyIncome = 'NA' OR @MonthlyIncome = '', NULL, @MonthlyIncome),
  NumberOfDependents = IF(@NumberOfDependents = 'NA' OR @NumberOfDependents = '', NULL, @NumberOfDependents);

select
count(*)
from row_data;

CREATE TABLE row_data_2
LIKE row_data;

INSERT row_data_2
SELECT *
FROM row_data;
