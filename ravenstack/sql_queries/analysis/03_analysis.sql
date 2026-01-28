/*
================================================================================
Project:        RavenStack: SaaS Subscription & Churn
Script:         03_analysis.sql
Database:       PostgreSQL
Author:         Saw Yu Nwe
Date:           2026-01-26
Description:    Collection of SQL queries for Key KPIs
================================================================================
*/


/*
================================================================================
Query No: 	1
Error:    	Total Number of Paying User differ
			from kpi.Query 2 & kpi.Query 3
Query:		Checking if subsciption is not churned yet, 
			account is already churned or not
================================================================================
*/


SELECT is_trial, churn_flag, COUNT(*)
FROM accounts
WHERE account_id IN (
	SELECT DISTINCT account_id
	FROM subscriptions
	WHERE churn_flag = false)
GROUP BY is_trial, churn_flag

/*
Result:		Even if there is an active subscription running, 
			account is already churned
================================================================================
is_trial 	| churn_flag 	| count
true	 	| true			|	25
false		| false			|	318
true		| false			| 	72
false		| true			|	85
================================================================================
*/