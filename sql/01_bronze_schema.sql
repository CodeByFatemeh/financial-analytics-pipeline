CREATE SCHEMA IF NOT EXISTS bronze;


DROP TABLE IF EXISTS bronze.transactions;
DROP TABLE IF EXISTS bronze.applications;
DROP TABLE IF EXISTS bronze.customers;
DROP TABLE IF EXISTS bronze.devices;


CREATE TABLE bronze.devices (
    device_id BIGINT,
    device_type TEXT,
    has_prior_fraud_flag INTEGER
);


CREATE TABLE bronze.customers (
    customer_id BIGINT,
    customer_type TEXT,
    gender TEXT,
    age INTEGER,
    region TEXT,
    job_type TEXT,
    annual_income NUMERIC(14, 2),
    current_credit_score INTEGER,
    defaulted_flag INTEGER,
    created_date DATE
);


CREATE TABLE bronze.applications (
    application_id BIGINT,
    customer_id BIGINT,
    device_id BIGINT,
    application_date DATE,
    requested_loan_amount NUMERIC(14, 2),
    offered_interest_rate NUMERIC(8, 2),
    risk_probability NUMERIC(8, 4),
    loan_status TEXT,
    loan_purpose TEXT,
    suspected_fraud_flag INTEGER,
    fraud_reason TEXT
);


CREATE TABLE bronze.transactions (
    transaction_id BIGINT,
    customer_id BIGINT,
    device_id BIGINT,
    transaction_date DATE,
    transaction_type TEXT,
    merchant_category TEXT,
    amount NUMERIC(14, 2),
    fraudulent_flag INTEGER,
    fraud_reason TEXT,
    return_flag INTEGER
);
