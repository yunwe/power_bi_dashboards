/*
================================================================================
Project:        RavenStack: SaaS Subscription & Churn
Script:         01_create_tables.sql
Database:       PostgreSQL
Author:         Saw Yu Nwe
Date:           2026-01-26
Description:    Initializes the database schema and defines table constraints 
                (Primary Keys, Foreign Keys) for the raw dataset.
================================================================================
Change Log:
2026-01-29: Update subscriptions table's end_date, where auto_renew = false
================================================================================
*/



UPDATE subscriptions
SET end_date = ((start_date + interval '1' month) - interval '1' day)::date 
WHERE auto_renew_flag = false
	AND end_date IS NULL
	AND billing_frequency = 'monthly';


UPDATE subscriptions
SET end_date = ((start_date + interval '1' year) - interval '1' day)::date 
WHERE auto_renew_flag = false
	AND end_date IS NULL
	AND billing_frequency = 'annual';