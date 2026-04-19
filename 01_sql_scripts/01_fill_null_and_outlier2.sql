-- 脚本名称：01_fill_null_and_outlier.sql
-- 版本v1.0
-- 日期： 2026-04-19
-- 用途：处理row_data表的缺失值（月收入，家庭赡养人员）和异常值，生成v1_initial_clean数据
-- 输入表：cs_tranning
-- 输出表；row_data_v1


-- 计算月收入中位数
SET @median_income = (SELECT AVG(MonthlyIncome)
FROM (SELECT 
	MonthlyIncome,
    ROW_NUMBER()OVER(ORDER BY MonthlyIncome) AS rn,
    count(*)over() AS total_rows
FROM row_data3
WHERE MonthlyIncome IS NOT NULL) AS t
WHERE  rn IN ((total_rows+1)/2,(total_rows+2)/2));

-- 为了更新目的
SET SQL_SAFE_UPDATES = 0;

-- 填充空值
UPDATE row_data3
SET MonthlyIncome = @median_income
WHERE MonthlyIncome IS NULL;

-- 检查是否更新
SELECT COUNT(*)
FROM row_data3
WHERE MonthlyIncome IS NULL;

-- 看缺失值占比，判断用什么方法
SELECT COUNT(*)
FROM row_data3
WHERE NumberOfDependents IS NULL;



-- 计算家人员众数,设置变量
SELECT NumberOfDependents
INTO @mode_dependents
FROM(SELECT NumberOfDependents,
	COUNT(*) AS cnt
FROM row_data3
WHERE NumberOfDependents IS NOT NULL
GROUP BY NumberOfDependents
ORDER BY COUNT(*) DESC) AS a
LIMIT 1;

-- 填充空值
UPDATE row_data3
SET NumberOfDependents = @mode_dependents
WHERE NumberOfDependents IS NULL;

-- 检查是否更新
SELECT COUNT(*)
FROM row_data3
WHERE NumberOfDependents IS NULL;




-- 检查逾期次数相关变量
-- 查看核心业务变量，逾期次数分布，找是否存在异常值(96=账户信息缺失,98=报告无逾期记录,99=数据未采集) 
SELECT NumberOfTime30_59DaysPastDueNotWorse,COUNT(*) AS cnt
FROM row_data3
GROUP BY NumberOfTime30_59DaysPastDueNotWorse
ORDER BY NumberOfTime30_59DaysPastDueNotWorse;
SELECT NumberOfTimes90DaysLate,COUNT(*) AS cnt
FROM row_data3
GROUP BY NumberOfTimes90DaysLate
ORDER BY NumberOfTimes90DaysLate;
SELECT NumberOfTime60_89DaysPastDueNotWorse,COUNT(*) AS cnt
FROM row_data3
GROUP BY NumberOfTime60_89DaysPastDueNotWorse
ORDER BY NumberOfTime60_89DaysPastDueNotWorse;

-- 把异常值转为null
UPDATE row_data3
SET NumberOfTime30_59DaysPastDueNotWorse = null
WHERE NumberOfTime30_59DaysPastDueNotWorse IN (96,98,99);
UPDATE row_data3
SET NumberOfTimes90DaysLate = null
WHERE NumberOfTimes90DaysLate IN (96,98,99);
UPDATE row_data3
SET NumberOfTime60_89DaysPastDueNotWorse = null
WHERE NumberOfTime60_89DaysPastDueNotWorse IN (96,98,99);
-- 用众数填充null
SELECT NumberOfTime30_59DaysPastDueNotWorse
INTO @mode_30_59
FROM(SELECT NumberOfTime30_59DaysPastDueNotWorse,
	COUNT(*) AS cnt
FROM row_data3
WHERE NumberOfTime30_59DaysPastDueNotWorse IS NOT NULL
GROUP BY NumberOfTime30_59DaysPastDueNotWorse
ORDER BY COUNT(*) DESC) AS a
LIMIT 1;
UPDATE row_data3
SET NumberOfTime30_59DaysPastDueNotWorse = @mode_30_59
WHERE NumberOfTime30_59DaysPastDueNotWorse IS NULL;

SELECT NumberOfTimes90DaysLate
INTO @mode_90
FROM(SELECT NumberOfTimes90DaysLate,
	COUNT(*) AS cnt
FROM row_data3
WHERE NumberOfTimes90DaysLate IS NOT NULL
GROUP BY NumberOfTimes90DaysLate
ORDER BY COUNT(*) DESC) AS a
LIMIT 1;
UPDATE row_data3
SET NumberOfTimes90DaysLate = @mode_90
WHERE NumberOfTimes90DaysLate IS NULL;

SELECT NumberOfTime60_89DaysPastDueNotWorse
INTO @mode_60_89
FROM(SELECT NumberOfTime60_89DaysPastDueNotWorse,
	COUNT(*) AS cnt
FROM row_data3
WHERE NumberOfTime60_89DaysPastDueNotWorse IS NOT NULL
GROUP BY NumberOfTime60_89DaysPastDueNotWorse
ORDER BY COUNT(*) DESC) AS a
LIMIT 1;
UPDATE row_data3
SET NumberOfTime60_89DaysPastDueNotWorse = @mode_60_89
WHERE NumberOfTime60_89DaysPastDueNotWorse IS NULL;


-- 快速排查连续型变量
SELECT 
	'age' AS var_name,
    MIN(age),
    MAX(age),
    AVG(age)
FROM row_data3
UNION ALL
SELECT 
	'RevolvingUtilizationOfUnsecuredLines' AS var_name,
    MIN(RevolvingUtilizationOfUnsecuredLines),
    MAX(RevolvingUtilizationOfUnsecuredLines),
    AVG(RevolvingUtilizationOfUnsecuredLines)
FROM row_data3
UNION ALL
SELECT 
	'MonthlyIncome' AS var_name,
    MIN(MonthlyIncome),
    MAX(MonthlyIncome),
    AVG(MonthlyIncome)
FROM row_data3
UNION ALL
SELECT 
	'DebtRatio' AS var_name,
    MIN(DebtRatio),
    MAX(DebtRatio),
    AVG(DebtRatio)
FROM row_data3;

-- 处理循环信用利用率REVOLVINGUTILIZATIONOFUNSERCUREDLINES,只能位于0-1，把大于1截断为1，小于0截断为0
UPDATE row_data3
SET RevolvingUtilizationOfUnsecuredLines = 1
WHERE RevolvingUtilizationOfUnsecuredLines > 1;
UPDATE row_data3
SET RevolvingUtilizationOfUnsecuredLines = 0
WHERE RevolvingUtilizationOfUnsecuredLines < 0;

-- 处理年龄 age，删除小于18，大于100的记录
DELETE FROM row_data3
WHERE age<18 or age>100;

-- 处理债务收入比,债务支出占总收入比例，一般不超过10 DebtRatio
-- 计算 DebtRatio 的 99% 分位数（假设表名为 credit_data）
-- 1. 查看不同分位数下的 DebtRatio，确定截断点
SELECT 
    MIN(DebtRatio) AS min_val,
    AVG(DebtRatio) AS avg_val,
    MAX(DebtRatio) AS max_val,
    -- 模拟 99% 分位数 (取排序后第 148500 行左右的值)
    (SELECT DebtRatio FROM row_data3 ORDER BY DebtRatio ASC LIMIT 148500, 1) AS p99
FROM row_data3;

-- 把 $P_{99}$ 以上的数值全部抹平。5000 之后增加的数值不再提供额外的“信用风险信息”,反而全是系统记录错误带来的“噪声”。
UPDATE row_data3 
SET DebtRatio = 5000 
WHERE DebtRatio > 5000;

-- 增加一个特征：是否属于超高负债组.
-- 在风控中，DebtRatio > 1（资不抵债）就已经是个强信号了
ALTER TABLE row_data3 ADD COLUMN dr_level TINYINT;
UPDATE row_data3 SET dr_level = 0 WHERE DebtRatio <= 1;    -- 财务健康
UPDATE row_data3 SET dr_level = 1 WHERE DebtRatio > 1 AND DebtRatio <= 10; -- 潜在风险
UPDATE row_data3 SET dr_level = 2 WHERE DebtRatio > 10;   -- 极高风险/数据异常


-- 排查计数/分类变量
SELECT NumberOfOpenCreditLinesAndLoans,COUNT(*) AS cnt
FROM row_data3
GROUP BY NumberOfOpenCreditLinesAndLoans
ORDER BY NumberOfOpenCreditLinesAndLoans
LIMIT 10;
SELECT NumberRealEstateLoansOrLines,COUNT(*) AS cnt
FROM row_data3
GROUP BY NumberRealEstateLoansOrLines
ORDER BY NumberRealEstateLoansOrLines
LIMIT 10;
SELECT NumberOfDependents,COUNT(*) AS cnt
FROM row_data3
GROUP BY NumberOfDependents
ORDER BY NumberOfDependents
LIMIT 10;	

-- 盖帽处理赡养人数
UPDATE row_data3 
SET NumberOfDependents = 5 
WHERE NumberOfDependents > 5;


