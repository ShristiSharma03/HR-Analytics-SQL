--Understanding the Workforce 

-- 1.What is the total headcount by department and job level?

select e.DEPT_ID,d.DEPT_NAME,count(e.EMP_ID) as Total_Employee,e.JOB_LEVEL
from employee e join departments d on e.DEPT_ID=d.DEPT_ID
group by e.DEPT_ID,e.JOB_LEVEL,d.DEPT_NAME
order by DEPT_ID;


-- 2.What is the gender distribution across each department?

select d.DEPT_ID,d.DEPT_NAME,e.GENDER,count(e.GENDER) as Gender_Distribution
from employee e 
join departments d 
on e.DEPT_ID=d.DEPT_ID
group by e.GENDER,d.DEPT_NAME,d.DEPT_ID
order by d.DEPT_ID;


-- 3.What is the average age of employees per department?

select d.DEPT_ID,d.DEPT_NAME,ROUND(avg(e.AGE),1) AS Average_age
from employee e 
join departments d on
e.DEPT_ID=d.DEPT_ID
group by d.DEPT_ID,d.DEPT_NAME
order by d.DEPT_ID;


-- 4.Which departments have the highest average salary — and is it fair across genders?

select e.DEPT_ID,d.DEPT_NAME,
ROUND(MAX(e.SALARY),2) as Maximum_salary,
ROUND(MIN(e.SALARY),2) as Minimum_salary,
ROUND(AVG(e.SALARY),2) as Average_salary,
e.GENDER
from employee e 
join departments d
on e.DEPT_ID=d.DEPT_ID
group by e.DEPT_ID,d.DEPT_NAME,e.GENDER
order by d.DEPT_ID;


-- 5.How has the company grown year over year — how many people were hired each year?

SELECT date_format(HIRED_DATE,'%Y') as Year,
count(EMP_ID) as No_of_Employees
from recruitements
group by Year
order by Year;


-- Attrition Deep Dive

-- 6.What is the overall attrition rate of the company?

SELECT 
    d.DEPT_ID,
    d.DEPT_NAME,
    COUNT(DISTINCT a.EMP_ID) AS Employees_Left,
    COUNT(DISTINCT e.EMP_ID) AS Total_Employees,
    ROUND((COUNT(DISTINCT a.EMP_ID) / COUNT(DISTINCT e.EMP_ID)) * 100, 2) AS Attrition_Rate
FROM employee e
LEFT JOIN attrition a ON e.EMP_ID = a.EMP_ID
join departments d on e.DEPT_ID=d.DEPT_ID 
group by d.DEPT_ID,d.DEPT_NAME
order by Attrition_Rate DESC;


-- 7.What are the top 3 reasons employees are leaving?

SELECT
REASON,COUNT(REASON) AS MAX_REASON
from attrition
group by REASON
ORDER BY MAX_REASON DESC
LIMIT 3;


-- 8.Which job level (Junior/Mid/Senior) has the most attrition?

select
e.JOB_LEVEL,count(a.EMP_ID) AS no_of_Attrition
from attrition a
left join employee e
on a.EMP_ID=e.EMP_ID
group by e.JOB_LEVEL
order by no_of_Attrition DESC;

-- 9.Which manager has lost the most team members in the last 1 year

SELECT 
    d.MANAGER_ID,
    d.DEPT_ID,
    d.DEPT_NAME,
    COUNT(a.ATT_ID) AS Employee_Left
FROM employee e
JOIN departments d ON e.DEPT_ID = d.DEPT_ID
JOIN attrition a ON e.EMP_ID = a.EMP_ID
WHERE YEAR(a.LEAVE_DATE) = 2025
GROUP BY d.MANAGER_ID, d.DEPT_ID, d.DEPT_NAME
ORDER BY Employee_Left DESC
LIMIT 1;


-- 10.Is attrition higher among employees who were never promoted in 3 years?
SELECT 
    e.PROMOTION_LAST_3YRS,
    COUNT(a.ATT_ID) AS Employee_Left,
    ROUND(COUNT(a.ATT_ID) * 100.0 / 
        (SELECT COUNT(*) FROM attrition), 2) AS Attrition_Percentage
FROM attrition a
LEFT JOIN employee e ON a.EMP_ID = e.EMP_ID
GROUP BY e.PROMOTION_LAST_3YRS
ORDER BY Employee_Left DESC;


-- Salary & Performance Analysis

-- 11.Find employees who earn below the average salary of their department — potential flight risk

SELECT 
    e.EMP_ID,
    e.NAME,
    e.DEPT_ID,
    d.DEPT_NAME,
    e.SALARY,
    e.JOB_LEVEL,
    ROUND(avg_sal.Avg_Salary, 2) AS Dept_Avg_Salary
FROM employee e
JOIN departments d ON e.DEPT_ID = d.DEPT_ID
JOIN (
    SELECT DEPT_ID, AVG(SALARY) AS Avg_Salary
    FROM employee
    GROUP BY DEPT_ID
) AS avg_sal ON e.DEPT_ID = avg_sal.DEPT_ID
WHERE e.SALARY < avg_sal.Avg_Salary
ORDER BY e.DEPT_ID, e.SALARY ASC;


-- 12.Is there a salary gap between male and female employees in the same job level?

select 
d.DEPT_NAME,
e.GENDER,
e.DEPT_ID,
e.JOB_LEVEL,
min(e.SALARY) as minimum_Salary,
max(e.SALARY)as maximum_Salary,
Round(AVG(e.SALARY),2) as Average_Salary
from employee e 
join departments d on e.DEPT_ID=d.DEPT_ID
group by e.GENDER,e.JOB_LEVEL,e.DEPT_ID,d.DEPT_NAME
order by e.DEPT_ID,d.DEPT_NAME, e.GENDER;


-- 13.Which department has the lowest average performance rating?

SELECT 
    d.DEPT_ID,
    d.DEPT_NAME,
    ROUND(AVG(p.RATING), 2) AS Avg_Rating,
    COUNT(p.REVIEW_ID) AS Total_Reviews,
    CASE 
        WHEN AVG(p.RATING) >= 4 THEN 'High'
        WHEN AVG(p.RATING) >= 3 THEN 'Medium'
        ELSE 'Low'
    END AS Performance_Status
FROM performance p
JOIN employee e ON p.EMP_ID = e.EMP_ID
JOIN departments d ON e.DEPT_ID = d.DEPT_ID
GROUP BY d.DEPT_ID, d.DEPT_NAME
ORDER BY Avg_Rating ASC;


-- 14.Find employees with high performance (rating 4–5) but low salary — retention risk!

select
e.EMP_ID,
e.NAME,
e.GENDER,
e.DEPT_ID,
d.DEPT_NAME,
e.SALARY,
ROUND(AVG(p.RATING), 1) AS Avg_Rating
FROM employee e
join departments d on e.DEPT_ID=d.DEPT_ID
join performance p on e.EMP_ID=p.EMP_ID
where e.SALARY < (
    SELECT AVG(SALARY) 
    FROM employee 
    WHERE DEPT_ID = e.DEPT_ID
)
GROUP BY e.EMP_ID, e.NAME, e.GENDER, d.DEPT_NAME, e.SALARY,e.DEPT_ID
having AVG(p.RATING) >= 4
order by e.DEPT_ID,e.SALARY;


-- 15.Which hiring source produces the best performing employees?

select e.HIRING_SOURCE,
count(distinct e.EMP_ID) as Total_Employee,
Round(avg(p.RATING),2) as Average_rating
from performance p
join employee e on p.EMP_ID=e.EMP_ID
group by e.HIRING_SOURCE
order by Average_rating desc;


-- 16.Compare average salary of employees who left vs those who stayed — is salary the real reason?

SELECT 
    CASE 
        WHEN e.EMP_ID IN (SELECT EMP_ID FROM attrition) 
        THEN 'Left'
        ELSE 'Stayed'
    END AS Employment_Status,
    COUNT(e.EMP_ID) AS Total_Employees,
    ROUND(AVG(e.SALARY), 2) AS Avg_Salary,
    ROUND(MIN(e.SALARY), 2) AS Min_Salary,
    ROUND(MAX(e.SALARY), 2) AS Max_Salary
FROM employee e
GROUP BY Employment_Status
ORDER BY Avg_Salary DESC;



-- Advanced Insights 

-- 17.Rank employees within each department by performance rating

SELECT 
    e.EMP_ID,
    e.NAME,
    d.DEPT_NAME,
    ROUND(AVG(p.RATING), 2) AS Avg_Rating,
    RANK() OVER (
        PARTITION BY e.DEPT_ID 
        ORDER BY AVG(p.RATING) DESC
    ) AS Performance_Rank
FROM employee e
JOIN departments d ON e.DEPT_ID = d.DEPT_ID
JOIN performance p ON e.EMP_ID = p.EMP_ID
GROUP BY e.EMP_ID, e.NAME, e.DEPT_ID, d.DEPT_NAME
ORDER BY e.DEPT_ID, Performance_Rank;


-- 18.create an attrition risk score for every current employee based on salary, promotion history and performance rating.

SELECT 
    e.EMP_ID,
    e.NAME,
    d.DEPT_NAME,
    e.SALARY,
    e.PROMOTION_LAST_3YRS,
    ROUND(AVG(p.RATING), 2) AS Avg_Rating,
    CASE
        WHEN e.SALARY < 30000 AND e.PROMOTION_LAST_3YRS = 0 
             AND AVG(p.RATING) < 3 THEN 'High Risk'
        WHEN e.SALARY < 50000 AND e.PROMOTION_LAST_3YRS = 0 
             AND AVG(p.RATING) < 4 THEN 'Medium Risk'
        WHEN e.SALARY >= 50000 AND e.PROMOTION_LAST_3YRS = 1 
             AND AVG(p.RATING) >= 4 THEN 'Low Risk'
        ELSE 'Monitor'
    END AS Risk_Score
FROM employee e
JOIN departments d ON e.DEPT_ID = d.DEPT_ID
JOIN performance p ON e.EMP_ID = p.EMP_ID
GROUP BY e.EMP_ID, e.NAME, d.DEPT_NAME, e.SALARY, e.PROMOTION_LAST_3YRS
ORDER BY Risk_Score;


-- 19. Calculate month-over-month attrition trend — which months see the most resignations?

SELECT 
    YEAR(a.LEAVE_DATE) AS Year,
    MONTH(a.LEAVE_DATE) AS Month_Number,
    DATE_FORMAT(a.LEAVE_DATE, '%M') AS Month_Name,
    COUNT(a.ATT_ID) AS Employees_Left
FROM attrition a
GROUP BY YEAR(a.LEAVE_DATE), MONTH(a.LEAVE_DATE), DATE_FORMAT(a.LEAVE_DATE, '%M')
ORDER BY Year, Month_Number;


-- 20.Do a cohort analysis — of employees hired in 2023, 2024, 2025 — what % are still with the company?

SELECT 
    YEAR(e.HIRE_DATE) AS Cohort_Year,
    COUNT(DISTINCT e.EMP_ID) AS Total_Hired,
    COUNT(DISTINCT e.EMP_ID) - COUNT(DISTINCT a.EMP_ID) AS Still_Active,
    COUNT(DISTINCT a.EMP_ID) AS Left_Company,
    ROUND(
        (COUNT(DISTINCT e.EMP_ID) - COUNT(DISTINCT a.EMP_ID)) * 100.0 
        / COUNT(DISTINCT e.EMP_ID), 2
    ) AS Retention_Percentage
FROM employee e
LEFT JOIN attrition a ON e.EMP_ID = a.EMP_ID
WHERE YEAR(e.HIRE_DATE) IN (2023, 2024, 2025)
GROUP BY YEAR(e.HIRE_DATE)
ORDER BY Cohort_Year;


-- 21.Find the salary difference between each employee and the top earner in their department.

SELECT 
    e.EMP_ID,
    e.NAME,
    d.DEPT_NAME,
    e.SALARY,
    MAX(e.SALARY) OVER (PARTITION BY e.DEPT_ID) AS Top_Salary_In_Dept,
    MAX(e.SALARY) OVER (PARTITION BY e.DEPT_ID) - e.SALARY AS Salary_Gap
FROM employee e
JOIN departments d ON e.DEPT_ID = d.DEPT_ID
ORDER BY e.DEPT_ID, Salary_Gap;



-- Views & Stored Procedures 

-- 22.Create a VIEW called attrition_rate showing all current employees with high risk score, their department, salary and manager.

create view attrition_rate AS
select
 e.EMP_ID,
    e.NAME,
    d.DEPT_NAME,
    d.MANAGER_ID,
    e.SALARY,
    e.PROMOTION_LAST_3YRS,
    ROUND(AVG(p.RATING), 2) AS Avg_Rating,
    CASE
        WHEN e.SALARY < 30000 AND e.PROMOTION_LAST_3YRS = 0 
             AND AVG(p.RATING) < 3 THEN 'High Risk'
        WHEN e.SALARY < 50000 AND e.PROMOTION_LAST_3YRS = 0 
             AND AVG(p.RATING) < 4 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS Risk_Category
FROM employee e
JOIN departments d ON e.DEPT_ID = d.DEPT_ID
JOIN performance p ON e.EMP_ID = p.EMP_ID
GROUP BY e.EMP_ID, e.NAME, d.DEPT_NAME, d.MANAGER_ID, 
         e.SALARY, e.PROMOTION_LAST_3YRS
HAVING Risk_Category IN ('High Risk', 'Medium Risk');

SELECT * FROM attrition_rate
ORDER BY Risk_Category, SALARY;

--23.Create a stored procedure GetDepartmentHealthReport — input: department name → output: headcount, avg salary, attrition rate, avg performance rating.

DELIMITER $$

CREATE PROCEDURE GetDepartmentHealthReport(IN dept_name VARCHAR(50))
BEGIN
    SELECT 
        d.DEPT_NAME,
        COUNT(DISTINCT e.EMP_ID) AS Total_Employees,
        ROUND(AVG(e.SALARY), 2) AS Avg_Salary,
        ROUND(
            COUNT(DISTINCT a.EMP_ID) * 100.0 / 
            COUNT(DISTINCT e.EMP_ID), 2
        ) AS Attrition_Rate,
        ROUND(AVG(p.RATING), 2) AS Avg_Performance_Rating
    FROM employee e
    JOIN departments d ON e.DEPT_ID = d.DEPT_ID
    LEFT JOIN attrition a ON e.EMP_ID = a.EMP_ID
    LEFT JOIN performance p ON e.EMP_ID = p.EMP_ID
    WHERE d.DEPT_NAME = dept_name
    GROUP BY d.DEPT_NAME;
END $$

DELIMITER ;

call GetDepartmentHealthReport('Engineering');


-- 24.Create a stored procedure FlagAtRiskEmployees that automatically updates a risk flag on the employees table based on salary, promotion and rating thresholds.

-- First add risk column to employee table
ALTER TABLE employee ADD COLUMN Risk_Flag VARCHAR(20) DEFAULT 'Low Risk';

DELIMITER $$

CREATE PROCEDURE FlagAtRiskEmployees()
BEGIN
    UPDATE employee e
    JOIN (
        SELECT 
            e2.EMP_ID,
            CASE
                WHEN e2.SALARY < 30000 
                     AND e2.PROMOTION_LAST_3YRS = 0 
                     AND AVG(p.RATING) < 3 THEN 'High Risk'
                WHEN e2.SALARY < 50000 
                     AND e2.PROMOTION_LAST_3YRS = 0 
                     AND AVG(p.RATING) < 4 THEN 'Medium Risk'
                ELSE 'Low Risk'
            END AS new_flag
        FROM employee e2
        JOIN performance p ON e2.EMP_ID = p.EMP_ID
        GROUP BY e2.EMP_ID, e2.SALARY, e2.PROMOTION_LAST_3YRS
    ) AS flags ON e.EMP_ID = flags.EMP_ID
    SET e.Risk_Flag = flags.new_flag;
END $$

DELIMITER ;

SET SQL_SAFE_UPDATES = 0;
CALL FlagAtRiskEmployees();
SET SQL_SAFE_UPDATES = 1;

SELECT EMP_ID, NAME, SALARY, PROMOTION_LAST_3YRS, Risk_Flag 
FROM employee
ORDER BY Risk_Flag;