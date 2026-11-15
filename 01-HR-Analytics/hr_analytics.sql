/*
Project: HR Analytics
Database: SQL Server (T-SQL)

Purpose:
Analyze workforce composition, compensation patterns, and hiring trends
using employee and department data.

Run this script in SQL Server Management Studio (SSMS).
*/

-- 1. Database setup
IF DB_ID('HR_Analytics_Project') IS NULL
    CREATE DATABASE HR_Analytics_Project;
GO

USE HR_Analytics_Project;
GO

-- 2. Recreate tables (safe to rerun)
DROP TABLE IF EXISTS Employees;
DROP TABLE IF EXISTS Departments;
GO

CREATE TABLE Departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(50) NOT NULL,
    location VARCHAR(50)
);

CREATE TABLE Employees (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    department_id INT,
    salary DECIMAL(10,2),
    age INT,
    hire_date DATE,
    job_title VARCHAR(100),
    FOREIGN KEY (department_id)
        REFERENCES Departments(department_id)
);
GO

-- 3. Insert sample data
INSERT INTO Departments (department_id, department_name, location)
VALUES
(1, 'Engineering', 'Chennai'),
(2, 'Marketing', 'Bangalore'),
(3, 'Finance', 'Mumbai'),
(4, 'Human Resources', 'Chennai'),
(5, 'Sales', 'Hyderabad'),
(6, 'Operations', 'Pune');

INSERT INTO Employees
(id, name, department_id, salary, age, hire_date, job_title)
VALUES
(1, 'Arun', 1, 85000, 29, '2021-06-15', 'Software Engineer'),
(2, 'Priya', 1, 95000, 32, '2020-03-10', 'Senior Software Engineer'),
(3, 'Karthik', 1, 75000, 26, '2023-01-20', 'Software Engineer'),
(4, 'Divya', 1, 120000, 38, '2018-08-12', 'Engineering Manager'),
(5, 'Meena', 2, 65000, 28, '2022-04-18', 'Marketing Executive'),
(6, 'Rahul', 2, 80000, 34, '2019-11-05', 'Marketing Manager'),
(7, 'Sneha', 2, 70000, 30, '2021-09-22', 'Marketing Analyst'),
(8, 'Vikram', 3, 90000, 35, '2019-02-14', 'Financial Analyst'),
(9, 'Anitha', 3, 105000, 40, '2017-07-01', 'Finance Manager'),
(10, 'Suresh', 3, 72000, 27, '2023-06-10', 'Accountant'),
(11, 'Lakshmi', 4, 60000, 31, '2021-01-11', 'HR Executive'),
(12, 'Ravi', 4, 85000, 36, '2018-05-25', 'HR Manager'),
(13, 'Nisha', 4, 60000, 29, '2022-10-03', 'Recruiter'),
(14, 'Ganesh', 5, 55000, 25, '2024-01-15', 'Sales Executive'),
(15, 'Pooja', 5, 75000, 31, '2020-08-19', 'Sales Executive'),
(16, 'Manoj', 5, 95000, 37, '2018-12-01', 'Sales Manager'),
(17, 'Asha', 5, 75000, 29, '2022-02-28', 'Sales Executive'),
(18, 'Sanjay', 6, 70000, 33, '2020-06-20', 'Operations Analyst'),
(19, 'Deepa', 6, 82000, 35, '2019-04-16', 'Operations Manager'),
(20, 'Mohan', 6, 65000, 28, '2023-03-12', 'Operations Executive');
GO

-- 4. Initial data checks
SELECT * FROM Departments;
SELECT * FROM Employees;

-- 5. Overall workforce summary
SELECT
    COUNT(e.id) AS total_employees,
    COUNT(DISTINCT d.department_id) AS department_count,
    AVG(e.salary) AS overall_average_salary,
    MIN(e.age) AS youngest_employee_age,
    MAX(e.age) AS oldest_employee_age
FROM Employees AS e
INNER JOIN Departments AS d
    ON e.department_id = d.department_id;

-- 6. Workforce by department
SELECT
    d.department_name,
    COUNT(e.id) AS employee_count
FROM Employees AS e
INNER JOIN Departments AS d
    ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY employee_count DESC;

-- 7. Department salary compared with company average
SELECT DISTINCT
    d.department_name,
    AVG(e.salary) OVER (PARTITION BY e.department_id) AS department_avg_salary,
    AVG(e.salary) OVER () AS company_avg_salary,
    AVG(e.salary) OVER (PARTITION BY e.department_id)
        - AVG(e.salary) OVER () AS difference_from_company_avg
FROM Employees AS e
INNER JOIN Departments AS d
    ON e.department_id = d.department_id
ORDER BY d.department_name;

-- 8. Salary distribution by department
SELECT
    d.department_name,
    COUNT(e.id) AS employee_count,
    SUM(e.salary) AS total_salary,
    AVG(e.salary) AS average_salary,
    MAX(e.salary) AS highest_salary,
    MIN(e.salary) AS lowest_salary,
    MAX(e.salary) - MIN(e.salary) AS salary_gap
FROM Employees AS e
INNER JOIN Departments AS d
    ON e.department_id = d.department_id
GROUP BY d.department_id, d.department_name
ORDER BY average_salary DESC;

-- 9. Employee count by job title
SELECT
    job_title,
    COUNT(id) AS employee_count
FROM Employees
GROUP BY job_title
ORDER BY employee_count DESC, job_title ASC;

-- 10. Employees earning above their department average
WITH DepartmentSalary AS (
    SELECT
        e.name AS employee_name,
        d.department_name,
        e.salary,
        AVG(e.salary) OVER (PARTITION BY e.department_id) AS department_avg_salary
    FROM Employees AS e
    INNER JOIN Departments AS d
        ON e.department_id = d.department_id
)
SELECT *
FROM DepartmentSalary
WHERE salary > department_avg_salary
ORDER BY department_name, salary DESC;

-- 11. Top two salary ranks in each department (ties are included)
WITH SalaryRanking AS (
    SELECT
        e.name AS employee_name,
        d.department_name,
        e.salary,
        DENSE_RANK() OVER (
            PARTITION BY e.department_id
            ORDER BY e.salary DESC
        ) AS salary_rank
    FROM Employees AS e
    INNER JOIN Departments AS d
        ON e.department_id = d.department_id
)
SELECT *
FROM SalaryRanking
WHERE salary_rank <= 2
ORDER BY department_name, salary_rank, employee_name;

-- 12. Highest-paid employee(s) in each department (ties are included)
WITH HighestPaid AS (
    SELECT
        e.name AS employee_name,
        d.department_name,
        e.salary,
        DENSE_RANK() OVER (
            PARTITION BY e.department_id
            ORDER BY e.salary DESC
        ) AS salary_rank
    FROM Employees AS e
    INNER JOIN Departments AS d
        ON e.department_id = d.department_id
)
SELECT employee_name, department_name, salary
FROM HighestPaid
WHERE salary_rank = 1
ORDER BY department_name;

-- 13. Compare salary levels within each department
SELECT
    e.name AS employee_name,
    d.department_name,
    e.salary,
    LAG(e.salary) OVER (
        PARTITION BY e.department_id
        ORDER BY e.salary DESC
    ) AS previous_salary_level,
    e.salary - LAG(e.salary) OVER (
        PARTITION BY e.department_id
        ORDER BY e.salary DESC
    ) AS salary_difference
FROM Employees AS e
INNER JOIN Departments AS d
    ON e.department_id = d.department_id
ORDER BY d.department_name, e.salary DESC;

-- 14. Departments with a salary gap greater than 40,000
SELECT
    d.department_name,
    COUNT(e.id) AS employee_count,
    AVG(e.salary) AS average_salary,
    MAX(e.salary) AS highest_salary,
    MIN(e.salary) AS lowest_salary,
    MAX(e.salary) - MIN(e.salary) AS salary_gap
FROM Employees AS e
INNER JOIN Departments AS d
    ON e.department_id = d.department_id
GROUP BY d.department_id, d.department_name
HAVING MAX(e.salary) - MIN(e.salary) > 40000
ORDER BY salary_gap DESC;

-- 15. Well-staffed departments (at least 3 employees)
SELECT
    d.department_name,
    COUNT(e.id) AS employee_count,
    SUM(e.salary) AS total_salary,
    AVG(e.salary) AS average_salary
FROM Employees AS e
INNER JOIN Departments AS d
    ON e.department_id = d.department_id
GROUP BY d.department_id, d.department_name
HAVING COUNT(e.id) >= 3
ORDER BY average_salary DESC;

-- 16. Departments with at least one employee earning over 100,000.
-- Counts include every employee in each qualifying department.
SELECT
    d.department_name,
    MAX(e.salary) AS highest_salary,
    COUNT(e.id) AS employee_count
FROM Employees AS e
INNER JOIN Departments AS d
    ON e.department_id = d.department_id
GROUP BY d.department_id, d.department_name
HAVING MAX(e.salary) > 100000
ORDER BY highest_salary DESC;

-- 17. Hiring range by department
SELECT
    d.department_name,
    MIN(e.hire_date) AS earliest_hire_date,
    MAX(e.hire_date) AS latest_hire_date,
    COUNT(e.id) AS employee_count
FROM Employees AS e
INNER JOIN Departments AS d
    ON e.department_id = d.department_id
GROUP BY d.department_id, d.department_name
ORDER BY earliest_hire_date;

-- 18. Employees hired in each calendar year
SELECT
    YEAR(hire_date) AS hire_year,
    COUNT(id) AS employee_count
FROM Employees
GROUP BY YEAR(hire_date)
ORDER BY hire_year DESC;

-- 19. Department hiring summary: hires from 2022 onward
SELECT
    d.department_name,
    COUNT(e.id) AS total_employees,
    SUM(CASE WHEN e.hire_date >= '2022-01-01' THEN 1 ELSE 0 END)
        AS employees_hired_from_2022,
    SUM(CASE WHEN e.hire_date >= '2022-01-01' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(e.id) AS percentage_hired_from_2022
FROM Employees AS e
INNER JOIN Departments AS d
    ON e.department_id = d.department_id
GROUP BY d.department_id, d.department_name
ORDER BY percentage_hired_from_2022 DESC;

-- 20. Recent hires earning at least 20,000 above their department average
WITH EmployeeSalary AS (
    SELECT
        e.name AS employee_name,
        d.department_name,
        e.hire_date,
        e.salary,
        AVG(e.salary) OVER (PARTITION BY e.department_id) AS department_avg_salary
    FROM Employees AS e
    INNER JOIN Departments AS d
        ON e.department_id = d.department_id
)
SELECT
    employee_name,
    department_name,
    hire_date,
    salary,
    department_avg_salary,
    salary - department_avg_salary AS salary_difference
FROM EmployeeSalary
WHERE hire_date >= '2022-01-01'
  AND salary >= department_avg_salary + 20000
ORDER BY hire_date DESC, salary DESC;

-- 21. Department summary with salary rank.
-- Rank is calculated across all departments before filtering.
WITH DepartmentSummary AS (
    SELECT
        d.department_id,
        d.department_name,
        COUNT(e.id) AS employee_count,
        AVG(e.salary) AS average_salary,
        MAX(e.salary) AS highest_salary,
        AVG(CAST(e.age AS DECIMAL(10,2))) AS average_age
    FROM Employees AS e
    INNER JOIN Departments AS d
        ON e.department_id = d.department_id
    GROUP BY d.department_id, d.department_name
),
RankedDepartments AS (
    SELECT
        *,
        RANK() OVER (ORDER BY average_salary DESC) AS salary_rank
    FROM DepartmentSummary
)
SELECT
    department_name,
    employee_count,
    average_salary,
    highest_salary,
    average_age,
    salary_rank
FROM RankedDepartments
WHERE employee_count >= 3
  AND average_salary > (SELECT AVG(salary) FROM Employees)
ORDER BY salary_rank;

-- 22. Stored procedure: return the top N highest-paid employees
CREATE OR ALTER PROCEDURE GetTopEmployees
    @N INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @N < 1
    BEGIN
        THROW 50001, 'N must be greater than zero.', 1;
    END;

    SELECT TOP (@N)
        id,
        name,
        salary
    FROM Employees
    ORDER BY salary DESC, id ASC;
END;
GO

-- Example execution
EXEC GetTopEmployees @N = 5;
GO
