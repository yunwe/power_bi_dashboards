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
KPI:    Total Revenue
================================================================================
*/
SELECT SUM(mrr_amount) as revenue
FROM subscriptions
WHERE 
	end_date IS NOT NULL
	AND billing_frequency = 'monthly'
	OR (billing_frequency = 'annual' AND start_date > date_trunc('month', current_date));


/*
================================================================================
KPI:    Average Revenue Per User (ARPU)
================================================================================
*/
SELECT 
	(SUM(mrr_amount)/ 
		(SELECT count(*) 
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
KPI:    Total Number of Paying Users
================================================================================
*/
SELECT COUNT(DISTINCT account_id)
FROM subscriptions
WHERE end_date IS NOT NULL

SELECT
	churn_flag,
	is_trial,
	COUNT(account_id)
FROM accounts
GROUP BY churn_flag, is_trial;
/*
================================================================================
KPI:    Average Revenue Per Paying User (ARPPU)
================================================================================
*/

