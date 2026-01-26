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
2026-01-26: Initial setup of tables.
================================================================================
*/

/*
================================================================================
Table:        accounts
Description:  customer metadata
Rows:         500
Error:        -
================================================================================
*/
CREATE TABLE accounts (
  account_id CHAR(8),
  account_name VARCHAR(50),
  industry VARCHAR(50),
  country CHAR(2),
  signup_date DATE,
  referral_source VARCHAR(50),
  plan_tier VARCHAR(50),
  seats INT4,
  is_trial BOOL,
  churn_flag BOOL,
  PRIMARY KEY (account_id)
);


COPY accounts 
FROM 'absolute_path_to_ravenstack_accounts.csv'
DELIMITER ','
CSV HEADER;


			
/*
================================================================================
Table:        subscriptions
Description:  subscription lifecycles and revenue
ROWS:         5,000
Error:        -
================================================================================
*/
CREATE TABLE subscriptions (
  subscription_id CHAR(8),
  account_id CHAR(8),
  start_date DATE,
  end_date DATE,
  plan_tier VARCHAR(50),
  seats INT4,
  mrr_amount FLOAT4,
  arr_amount FLOAT4,
  is_trial BOOL,
  upgrade_flag BOOL,
  downgrade_flag BOOL,
  churn_flag BOOL,
  billing_frequency VARCHAR(10),
  auto_renew_flag BOOL,
  PRIMARY KEY (subscription_id)
);

COPY subscriptions 
FROM 'absolute_path_to_ravenstack_subscriptions.csv'
DELIMITER ','
CSV HEADER;


/*
================================================================================
Table:        feature_usage
Description:  daily product interaction logs
ROWS:         25,000
Error:        uplicate usage_id in raw data
================================================================================
*/
CREATE TABLE feature_usage (
  usage_id CHAR(8),
  subscription_id CHAR(8),
  usage_date DATE,
  feature_name VARCHAR(50),
  usage_count INT4,
  usage_duration_sec INT,
  error_count INT4,
  is_beta_feature BOOL
);


COPY feature_usage --- 25,000 rows
FROM 'absolute_path_to_ravenstack_feature_usage.csv'
DELIMITER ','
CSV HEADER;

/*
================================================================================
Table:        support_tickets
Description:  support activity and satisfaction scores
ROWS:         2,000
Error:        datatype error in `staisfaction_score`
================================================================================
*/
CREATE TABLE support_tickets (
  ticket_id CHAR(8),
  account_id CHAR(8),
  submitted_at TIMESTAMP,
  closed_at TIMESTAMP,
  resolution_time_hours FLOAT,
  priority VARCHAR(50),
  first_response_time_minutes INT,
  staisfaction_score FLOAT, -- CAST to SMALLINT
  escalation_flag BOOL,
  PRIMARY KEY (ticket_id)
);

COPY support_tickets
FROM 'absolute_path_to_ravenstack_support_tickets.csv'
DELIMITER ','
CSV HEADER;


/*
================================================================================
Table:        churn_events
Description:  churn dates, reasons, and refund behaviors
ROWS:         600
Error:        -
================================================================================
*/
CREATE TABLE churn_events (
  churn_event_id CHAR(8),
  account_id CHAR(8),
  churn_date DATE,
  reason_code VARCHAR(50),
  refund_amount_usd FLOAT,
  preceding_upgrade_flag BOOL,
  preceding_downgrade_flag BOOL,
  is_reactivation BOOL,
  feedback_text VARCHAR(50),
  PRIMARY KEY (churn_event_id)
);

COPY churn_events 
FROM 'absolute_path_to_ravenstack_churn_events.csv'
DELIMITER ','
CSV HEADER;