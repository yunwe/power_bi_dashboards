/*
================================================================================
Project:        RavenStack: SaaS Subscription & Churn
Script:         01_create_tables.sql
Database:       PostgreSQL
Author:         Saw Yu Nwe
Date:           2026-01-29
Description:    Table in the DB do not work well for Power BI Query, and DAX functions.
				The data are transformed in DB side, so it is ready to use in Power BI
How to Use:		Copy the below SQL in Power BI Data Connection; 
				each section of SQL is for one PowerBI Query
================================================================================
*/

/*
================================================================================
Name:    		Billing
Description:	Actual Revenue Flow 
================================================================================
*/
WITH dates AS (
    SELECT generate_series(
        date_trunc('month', (SELECT MIN(start_date) FROM subscriptions)), 
        date_trunc('month', (SELECT MAX(end_date) FROM subscriptions)),
        '1 month'::interval
    )::date AS month_date
),
monthly_calendar AS (
	SELECT 
		month_date AS start_of_month,
		(date_trunc('MONTH', month_date) + INTERVAL '1 MONTH - 1 day')::date AS end_of_month
	FROM dates
),
annual_subscriptions AS (
	SELECT 
		subscription_id,
		account_id,
		start_date,
		end_date,
		(start_date + interval '1' year)::date AS next_cycle,
		arr_amount AS amount,
		billing_frequency,
		plan_tier
	FROM subscriptions 
	WHERE billing_frequency = 'annual'
		AND is_trial = false
),
annual_bills AS (
	SELECT 
		c.start_of_month, 
		s.subscription_id, 
		s.account_id,
		s.amount,
		s.billing_frequency,
		s.plan_tier
	FROM annual_subscriptions AS s
	CROSS JOIN monthly_calendar AS c
	WHERE date_trunc('month', s.start_date) = c.start_of_month
		OR (date_trunc('month', s.next_cycle) = c.start_of_month
			AND (end_date IS NULL OR end_date > next_cycle))
),
monthly_bills AS (
	SELECT 
		c.start_of_month, 
		s.subscription_id, 
		s.account_id,
		s.mrr_amount AS amount,
		s.billing_frequency,
		s.plan_tier
	FROM monthly_calendar AS c
	CROSS JOIN subscriptions AS s
	WHERE s.start_date < c.end_of_month 
		AND (s.end_date IS NULL OR s.end_date >= c.start_of_month)
		AND s.is_trial = false
		AND s.billing_frequency = 'monthly'
)

SELECT *
FROM monthly_bills
UNION 
SELECT *
FROM annual_bills
ORDER BY start_of_month, subscription_id



/*
================================================================================
Name:    		Subscriptions
Description:	Filter Columns for Better Performance
================================================================================
*/

SELECT 
	subscription_id,
	account_id,
	start_date,
	end_date,
	mrr_amount,
	is_trial,
	upgrade_flag
FROM subscriptions


/*
================================================================================
Name:    		MRR
Description:	Revenue in MRR for KPI Calcualations
================================================================================
*/

WITH dates AS (
    SELECT generate_series(
        date_trunc('month', (SELECT MIN(start_date) FROM subscriptions)), 
        date_trunc('month', (SELECT MAX(end_date) FROM subscriptions)),
        '1 month'::interval
    )::date AS month_date
),
monthly_calendar AS (
	SELECT 
		month_date AS start_of_month,
		(date_trunc('MONTH', month_date) + INTERVAL '1 MONTH - 1 day')::date AS end_of_month
	FROM dates
)

SELECT 
	c.start_of_month, 
	s.subscription_id, 
	s.account_id,
	s.mrr_amount AS amount
FROM monthly_calendar AS c
CROSS JOIN subscriptions AS s
WHERE s.start_date < c.end_of_month 
	AND (s.end_date IS NULL OR s.end_date >= c.start_of_month)
	AND s.is_trial = false

/*
================================================================================
Name:    		User Account Statistics
Description:	To Calculate User Running Total, Monthly Churned Rate  
================================================================================
*/


WITH account_churn_events AS (
	SELECT 
		a.account_id,
		date_trunc('month', a.signup_date)::date AS signup_date,
		date_trunc('month', e.churn_date)::date AS churn_date,
		ROW_NUMBER() OVER(PARTITION BY a.account_id ORDER BY e.churn_date DESC) as ind
	FROM accounts AS a
	LEFT JOIN churn_events AS e
		ON a.account_id = e.account_id
),
signed_up AS (
	SELECT 
		signup_date, 
		COUNT(*)
	FROM account_churn_events
	WHERE ind = 1
	GROUP BY signup_date
),
churned AS (
	SELECT 
		churn_date, 
		COUNT(*)
	FROM account_churn_events
	WHERE churn_date IS NOT NULL
		AND ind = 1
	GROUP BY churn_date
),
buffer AS (
	SELECT 
		signed_up.signup_date as start_of_month,
		COALESCE(signed_up.count, 0) AS new_users,
		COALESCE(churned.count, 0) AS churned_users,
		SUM(COALESCE(signed_up.count, 0)) OVER (ORDER BY signed_up.signup_date) AS total_users,
		SUM(COALESCE(churned.count, 0)) OVER (ORDER BY signed_up.signup_date) AS total_churned_users
	FROM signed_up
	LEFT JOIN churned
		ON signed_up.signup_date = churned.churn_date
	ORDER BY start_of_month
)

SELECT
    start_of_month,
	new_users,
	churned_users,
	(total_users - total_churned_users)  AS active_users,
	ROUND(
		COALESCE(churned_users / 
			NULLIF(
				LAG((total_users - total_churned_users), 1, 0) 
					OVER (ORDER BY start_of_month)
				, 0)
			, 0)
		,2) AS churned_rate
FROM buffer




