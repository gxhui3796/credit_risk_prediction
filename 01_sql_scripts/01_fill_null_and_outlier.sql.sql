-- 计算月收入中位数
SET @median_income = (SELECT AVG(MonthlyIncome)
FROM (SELECT 
	MonthlyIncome,
    ROW_NUMBER()OVER(ORDER BY MonthlyIncome) AS rn,
    count(*)over() AS total_rows
FROM row_data
WHERE MonthlyIncome IS NOT NULL) AS t
WHERE  rn IN ((total_rows+1)/2,(total_rows+2)/2));

-- 为了更新目的
SET SQL_SAFE_UPDATES = 0;

-- 填充空值
UPDATE row_data
SET MonthlyIncome = @median_income
WHERE MonthlyIncome IS NULL;

-- 检查是否更新
SELECT COUNT(*)
FROM row_data
WHERE MonthlyIncome IS NULL;

-- 看缺失值占比，判断用什么方法
SELECT COUNT(*)
FROM row_data
WHERE NumberOfDependents IS NULL;



-- 计算家人员众数,设置变量
SELECT NumberOfDependents
INTO @mode_dependents
FROM(SELECT NumberOfDependents,
	COUNT(*) AS cnt
FROM row_data
WHERE NumberOfDependents IS NOT NULL
GROUP BY NumberOfDependents
ORDER BY COUNT(*) DESC) AS a
LIMIT 1;

-- 填充空值
UPDATE row_data
SET NumberOfDependents = @mode_dependents
WHERE NumberOfDependents IS NULL;

-- 检查是否更新
SELECT COUNT(*)
FROM row_data
WHERE NumberOfDependents IS NULL;






