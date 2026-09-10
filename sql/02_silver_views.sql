CREATE SCHEMA IF NOT EXISTS silver;


CREATE OR REPLACE VIEW silver.devices AS
SELECT
    device_id,
    TRIM(device_type) AS device_type,
    CASE
        WHEN has_prior_fraud_flag = 1 THEN 1
        ELSE 0
    END AS has_prior_fraud_flag
FROM bronze.devices
WHERE device_id IS NOT NULL;


CREATE OR REPLACE VIEW silver.customers AS
SELECT
    customer_id,
    TRIM(customer_type) AS customer_type,
    TRIM(gender) AS gender,
    age,
    TRIM(region) AS region,
    TRIM(job_type) AS job_type,
    annual_income,
    current_credit_score,
    CASE
        WHEN defaulted_flag = 1 THEN 1
        ELSE 0
    END AS defaulted_flag,
    created_date
FROM bronze.customers
WHERE
    customer_id IS NOT NULL
    AND age BETWEEN 18 AND 100
    AND current_credit_score BETWEEN 300 AND 850
    AND annual_income >= 0;


CREATE OR REPLACE VIEW silver.applications AS
SELECT
    application_id,
    customer_id,
    device_id,
    application_date,
    requested_loan_amount,
    offered_interest_rate,
    risk_probability,
    TRIM(loan_status) AS loan_status,
    TRIM(loan_purpose) AS loan_purpose,

    CASE
        WHEN suspected_fraud_flag = 1 THEN 1
        ELSE 0
    END AS suspected_fraud_flag,

    NULLIF(
        TRIM(fraud_reason),
        ''
    ) AS fraud_reason

FROM bronze.applications
WHERE
    application_id IS NOT NULL
    AND customer_id IS NOT NULL
    AND requested_loan_amount >= 0
    AND risk_probability BETWEEN 0 AND 1;


CREATE OR REPLACE VIEW silver.transactions AS
SELECT
    transaction_id,
    customer_id,
    device_id,
    transaction_date,

    TRIM(
        transaction_type
    ) AS transaction_type,

    TRIM(
        merchant_category
    ) AS merchant_category,

    amount,

    CASE
        WHEN fraudulent_flag = 1 THEN 1
        ELSE 0
    END AS fraudulent_flag,

    NULLIF(
        TRIM(fraud_reason),
        ''
    ) AS fraud_reason,

    CASE
        WHEN return_flag = 1 THEN 1
        ELSE 0
    END AS return_flag

FROM bronze.transactions
WHERE
    transaction_id IS NOT NULL
    AND customer_id IS NOT NULL
    AND amount >= 0;
