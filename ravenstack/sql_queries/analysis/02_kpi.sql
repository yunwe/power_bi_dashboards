/*
================================================================================
Project:        RavenStack: SaaS Subscription & Churn
Script:         02_kpi.sql
Database:       PostgreSQL
Author:         Saw Yu Nwe
Date:           2026-01-26
Description:    Collection of SQL queries for Key KPIs
================================================================================
*/

/*
================================================================================
Query No: 	1
KPI:    	Total Revenue (Currnet Month)
================================================================================
*/
WITH active_subscriptions AS (
	SELECT mrr_amount, arr_amount, billing_frequency
	FROM subscriptions
	WHERE 
		end_date IS NOT NULL
		AND (billing_frequency = 'monthly'
		OR (billing_frequency = 'annual' AND start_date >= TO_DATE('2024-12-01', 'YYYY-MM-DD')))
)


SELECT SUM(mrr_amount) + (
	SELECT SUM(arr_amount)
	FROM active_subscriptions
	WHERE billing_frequency = 'annual') AS total_revenue
FROM active_subscriptions
WHERE billing_frequency = 'monthly';



/*
================================================================================
Query No: 	2
KPI:    	Total Number of Paying Users
================================================================================
*/
SELECT COUNT(DISTINCT account_id)
FROM subscriptions
WHERE end_date IS NOT NULL

/*
================================================================================
Query No: 	3
KPI:    	Total Number of Users; Churned, On Trial, Active
================================================================================
*/
WITH category AS (
	SELECT
		CASE WHEN churn_flag = true THEN 'Churned'
		WHEN churn_flag = false AND is_trial = true THEN 'Trial'
		ELSE 'Active' END AS category,
		COUNT(account_id)
	FROM accounts
	GROUP BY churn_flag, is_trial
)

SELECT category, SUM(count) AS total_users
FROM category
GROUP BY category

/*
================================================================================
Query No: 	4
KPI:    	Average Revenue Per User (ARPU) 
Formula:	ARPU = Total Revenue ÷ Total Active Users (including users on trial)
================================================================================
*/
SELECT (
		SUM(mrr_amount)/ (
		SELECT count(*) 
		FROM accounts 
		WHERE churn_flag = false)
	) as arpu
FROM subscriptions
WHERE 
	end_date IS NOT NULL
	AND billing_frequency = 'monthly'
	OR (billing_frequency = 'annual' 
		AND start_date > date_trunc('month', current_date));



/*
================================================================================
Query No: 	5
KPI:   	 	Average Revenue Per Paying User (ARPPU)
Formula:	ARPPU = Total Revenue ÷ Total Paying Users
================================================================================
*/
WITH paying_users AS (
	SELECT COUNT(DISTINCT account_id) AS c
	FROM subscriptions 
	WHERE 
		is_trial = false 
		AND (end_date is NULL 
			OR end_date < (DATE_TRUNC('month', current_date) + INTERVAL '1 month - 1 day'))
		AND churn_flag = false
)

SELECT (
	SUM(mrr_amount)/ 
	(SELECT c FROM paying_users)) AS arppu 
FROM subscriptions
WHERE 
	end_date IS NOT NULL
	AND billing_frequency = 'monthly'
	OR (billing_frequency = 'annual' 
		AND start_date > date_trunc('month', current_date));


/*
================================================================================
Query No: 	6
KPI:    	Customer Lifetime Value (CLV)
Formula:	LTV = Average Revenue per Customer × Gross Margin ÷ Churn Rate.
================================================================================
*/

-- NO DATA on Spending >> NO Gross margin

/*
================================================================================
Query No: 	7
KPI:    	Churn Rate (Logo), Logo Churn: How many customers left?
================================================================================
*/
SELECT (COUNT(account_id)::float / (
	SELECT COUNT(account_id)
	FROM accounts) * 100) AS trial_to_paid_conversion
FROM accounts
WHERE churn_flag = true


/*
================================================================================
Query No: 	8
KPI:    	Churn Rate (Revenue), Revenue Churn: How much money left?
================================================================================
*/
WITH lost_dec AS(
	SELECT SUM(mrr_amount) AS total_lost
	FROM subscriptions
	WHERE 
		downgrade_flag = true
		OR end_date > TO_DATE('2024-12-31', 'YYYY-MM-DD')
),
nov_subscriptions AS (
	SELECT mrr_amount, arr_amount, billing_frequency
	FROM subscriptions
	WHERE 
		(end_date IS NOT NULL 
			OR end_date >= TO_DATE('2024-11-30', 'YYYY-MM-DD'))
		AND (billing_frequency = 'monthly'
			OR (billing_frequency = 'annual' 
				AND start_date >= TO_DATE('2024-11-01', 'YYYY-MM-DD')))
),
nov_revenue AS (
	SELECT SUM(mrr_amount) + (
		SELECT SUM(arr_amount)
		FROM nov_subscriptions
		WHERE billing_frequency = 'annual') AS revenue
	FROM nov_subscriptions
	WHERE billing_frequency = 'monthly'
)

SELECT (total_lost / (SELECT revenue FROM nov_revenue) * 100) AS revenue_churn
FROM lost_dec

/*
================================================================================
Query No: 	9
KPI:    	trial-to-paid conversion
Formula:	Converted User ÷ Total Trial Users
================================================================================
*/

SELECT (COUNT(DISTINCT account_id)::float / (
	SELECT COUNT(DISTINCT account_id)
	FROM subscriptions
	WHERE is_trial = true ) * 100) AS trial_to_paid_conversion
FROM subscriptions
WHERE is_trial = true 
	AND upgrade_flag = true