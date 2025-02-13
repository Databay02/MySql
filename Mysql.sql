select * from transactions_info;
WITH transactions_filtered AS (
    SELECT 
        ID_client, 
        DATE_FORMAT(date_new, '%Y-%m') AS month_year, 
        COUNT(*) AS transactions_count,
        SUM(Sum_payment) AS total_sum
    FROM transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY ID_client, month_year
), 

continuous_clients AS (
    SELECT ID_client
    FROM transactions_filtered
    GROUP BY ID_client
    HAVING COUNT(DISTINCT month_year) = 12
)

SELECT 
    t.ID_client,
    COUNT(t.Id_check) AS total_operations,
    SUM(t.Sum_payment) / COUNT(DISTINCT DATE_FORMAT(t.date_new, '%Y-%m')) AS avg_monthly_spending,
    SUM(t.Sum_payment) / COUNT(t.Id_check) AS avg_ticket_size
FROM transactions_info t
JOIN continuous_clients c ON t.ID_client = c.ID_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY t.ID_client;

WITH monthly_stats AS (
    SELECT 
        DATE_FORMAT(t.date_new, '%Y-%m') AS month_year,
        COUNT(t.Id_check) AS total_operations,
        SUM(t.Sum_payment) AS total_sum,
        COUNT(DISTINCT t.ID_client) AS unique_clients,
        SUM(t.Sum_payment) / COUNT(t.Id_check) AS avg_ticket_size,
        COUNT(t.Id_check) / COUNT(DISTINCT t.ID_client) AS avg_operations_per_client
    FROM transactions_info t
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY month_year
), 
gender_spending AS (
    SELECT 
        DATE_FORMAT(t.date_new, '%Y-%m') AS month_year,
        c.Gender,
        COUNT(DISTINCT t.ID_client) AS unique_gender_clients,
        SUM(t.Sum_payment) AS gender_spending
    FROM transactions_info t
    JOIN customer_info c ON t.ID_client = c.Id_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY month_year, c.Gender
), 
total_yearly AS (
    SELECT 
        COUNT(Id_check) AS yearly_operations,
        SUM(Sum_payment) AS yearly_sum
    FROM transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
)

WITH monthly_data AS (
    SELECT 
        DATE_FORMAT(t.date_new, '%Y-%m') AS month,
        COUNT(t.Id_check) AS total_transactions,
        SUM(t.Sum_payment) AS total_revenue,
        COUNT(DISTINCT t.ID_client) AS unique_clients,
        SUM(t.Sum_payment) / COUNT(t.Id_check) AS avg_check
    FROM transactions_info t
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY month
),
yearly_data AS (
    SELECT 
        COUNT(Id_check) AS yearly_transactions,
        SUM(Sum_payment) AS yearly_revenue
    FROM transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
),
gender_data AS (
    SELECT 
        DATE_FORMAT(t.date_new, '%Y-%m') AS month,
        c.Gender,
        SUM(t.Sum_payment) AS total_spent,
        COUNT(*) AS transaction_count
    FROM transactions_info t
    JOIN customer_info c ON t.ID_client = c.Id_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY month, c.Gender
)
SELECT 
    m.month,
    m.avg_check AS avg_check_per_month,
    m.total_transactions / 12 AS avg_transactions_per_month,
    m.unique_clients / 12 AS avg_clients_per_month,
    (m.total_transactions / y.yearly_transactions) * 100 AS transaction_share_percentage,
    (m.total_revenue / y.yearly_revenue) * 100 AS revenue_share_percentage,
    g_male.total_spent / m.total_revenue * 100 AS male_share,
    g_female.total_spent / m.total_revenue * 100 AS female_share,
    g_na.total_spent / m.total_revenue * 100 AS na_share
FROM monthly_data m
JOIN yearly_data y ON 1=1
LEFT JOIN (SELECT month, total_spent FROM gender_data WHERE Gender = 'M') g_male ON m.month = g_male.month
LEFT JOIN (SELECT month, total_spent FROM gender_data WHERE Gender = 'F') g_female ON m.month = g_female.month
LEFT JOIN (SELECT month, total_spent FROM gender_data WHERE Gender IS NULL) g_na ON m.month = g_na.month
ORDER BY m.month;


WITH age_groups AS (
    SELECT 
        CASE 
            WHEN Age IS NULL THEN 'Unknown'
            WHEN Age BETWEEN 10 AND 19 THEN '10-19'
            WHEN Age BETWEEN 20 AND 29 THEN '20-29'
            WHEN Age BETWEEN 30 AND 39 THEN '30-39'
            WHEN Age BETWEEN 40 AND 49 THEN '40-49'
            WHEN Age BETWEEN 50 AND 59 THEN '50-59'
            WHEN Age BETWEEN 60 AND 69 THEN '60-69'
            WHEN Age BETWEEN 70 AND 79 THEN '70-79'
            ELSE '80+'
        END AS age_category,
        t.ID_client,
        t.Sum_payment,
        t.Id_check,
        DATE_FORMAT(t.date_new, '%Y-Q%q') AS quarter
    FROM transactions_info t
    JOIN customer_info c ON t.ID_client = c.Id_client
)
SELECT 
    age_category,
    COUNT(DISTINCT ID_client) AS unique_clients,
    COUNT(Id_check) AS total_transactions,
    SUM(Sum_payment) AS total_revenue,
    quarter,
    COUNT(Id_check) / COUNT(DISTINCT ID_client) AS avg_transactions_per_client,
    SUM(Sum_payment) / COUNT(DISTINCT ID_client) AS avg_revenue_per_client,
    (SUM(Sum_payment) / (SELECT SUM(Sum_payment) FROM age_groups)) * 100 AS revenue_percentage
FROM age_groups
GROUP BY age_category, quarter
ORDER BY age_category, quarter;

