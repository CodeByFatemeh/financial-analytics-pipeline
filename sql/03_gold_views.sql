CREATE SCHEMA IF NOT EXISTS gold;


-- =========================================================
-- CUSTOMER DIMENSION
-- Grain: one row per customer
-- =========================================================

CREATE OR REPLACE VIEW gold.dim_customer AS
SELECT
    c.customer_id,
    c.customer_type,
    c.gender,
    c.age,

    CASE
        WHEN c.age BETWEEN 18 AND 24 THEN '18-24'
        WHEN c.age BETWEEN 25 AND 34 THEN '25-34'
        WHEN c.age BETWEEN 35 AND 44 THEN '35-44'
        WHEN c.age BETWEEN 45 AND 54 THEN '45-54'
        WHEN c.age BETWEEN 55 AND 64 THEN '55-64'
        ELSE '65+'
    END AS age_band,

    c.region,
    c.job_type,
    c.annual_income,

    CASE
        WHEN c.annual_income < 100000
            THEN '$50K-$99K'
        WHEN c.annual_income < 150000
            THEN '$100K-$149K'
        WHEN c.annual_income < 200000
            THEN '$150K-$199K'
        ELSE '$200K+'
    END AS income_band,

    c.current_credit_score,

    CASE
        WHEN c.current_credit_score < 580
            THEN '<580'
        WHEN c.current_credit_score < 670
            THEN '580-669'
        WHEN c.current_credit_score < 740
            THEN '670-739'
        WHEN c.current_credit_score < 800
            THEN '740-799'
        ELSE '800+'
    END AS credit_score_band,

    CASE
        WHEN c.current_credit_score < 580
            THEN 'Subprime'
        WHEN c.current_credit_score < 670
            THEN 'Near-Prime'
        ELSE 'Prime'
    END AS credit_tier,

    c.defaulted_flag,
    c.created_date

FROM silver.customers c;


-- =========================================================
-- APPLICATION FACT
-- Grain: one row per loan application
-- =========================================================

CREATE OR REPLACE VIEW gold.fact_application AS
SELECT
    a.application_id,
    a.customer_id,
    a.device_id,
    a.application_date,

    a.requested_loan_amount,
    a.offered_interest_rate,
    a.risk_probability,

    CASE
        WHEN a.risk_probability >= 0.12
            THEN 'High Risk'
        WHEN a.risk_probability >= 0.07
            THEN 'Moderate Risk'
        ELSE 'Low Risk'
    END AS risk_band,

    a.loan_status,
    a.loan_purpose,

    CASE
        WHEN a.loan_status <> 'Not Approved'
            THEN 1
        ELSE 0
    END AS approved_flag,

    a.suspected_fraud_flag,
    a.fraud_reason,

    COALESCE(
        d.has_prior_fraud_flag,
        0
    ) AS device_has_prior_fraud_flag

FROM silver.applications a

LEFT JOIN silver.devices d
    ON a.device_id = d.device_id;


-- =========================================================
-- TRANSACTION FACT
-- Grain: one row per transaction
-- =========================================================

CREATE OR REPLACE VIEW gold.fact_transaction AS
SELECT
    t.transaction_id,
    t.customer_id,
    t.device_id,
    t.transaction_date,
    t.transaction_type,
    t.merchant_category,
    t.amount,
    t.fraudulent_flag,
    t.fraud_reason,
    t.return_flag,

    COALESCE(
        d.has_prior_fraud_flag,
        0
    ) AS device_has_prior_fraud_flag

FROM silver.transactions t

LEFT JOIN silver.devices d
    ON t.device_id = d.device_id;


-- =========================================================
-- APPLICATION FRAUD FEATURE VIEW
-- Grain: one row per application
-- =========================================================

CREATE OR REPLACE VIEW gold.feat_application_fraud AS
SELECT
    application_id,
    customer_id,
    suspected_fraud_flag,
    fraud_reason,
    device_has_prior_fraud_flag,

    CASE
        WHEN
            suspected_fraud_flag = 1
            AND device_has_prior_fraud_flag = 1
        THEN 1
        ELSE 0
    END AS fraud_with_prior_device_flag

FROM gold.fact_application;


-- =========================================================
-- TRANSACTION FRAUD FEATURE VIEW
-- Grain: one row per transaction
-- =========================================================

CREATE OR REPLACE VIEW gold.feat_transaction_fraud AS
SELECT
    transaction_id,
    customer_id,
    merchant_category,
    amount,
    fraudulent_flag,
    fraud_reason,
    device_has_prior_fraud_flag,

    CASE
        WHEN amount >= 5000
            THEN 1
        ELSE 0
    END AS high_amount_flag

FROM gold.fact_transaction;


-- =========================================================
-- EXECUTIVE SUMMARY
-- Grain: one-row portfolio summary
-- =========================================================

CREATE OR REPLACE VIEW gold.vw_executive_summary AS
SELECT

    (
        SELECT COUNT(*)
        FROM gold.dim_customer
    ) AS total_customers,

    (
        SELECT COUNT(*)
        FROM gold.fact_application
    ) AS total_applications,

    (
        SELECT COUNT(*)
        FROM gold.fact_application
        WHERE approved_flag = 1
    ) AS approved_applications,

    (
        SELECT
            ROUND(
                AVG(
                    approved_flag
                ) * 100,
                2
            )
        FROM gold.fact_application
    ) AS approval_rate_pct,

    (
        SELECT COUNT(*)
        FROM gold.fact_transaction
    ) AS total_transactions,

    (
        SELECT COUNT(*)
        FROM gold.fact_transaction
        WHERE fraudulent_flag = 1
    ) AS fraudulent_transactions,

    (
        SELECT
            ROUND(
                AVG(
                    fraudulent_flag
                ) * 100,
                2
            )
        FROM gold.fact_transaction
    ) AS fraud_transaction_rate_pct,

    (
        SELECT COUNT(*)
        FROM gold.fact_application
        WHERE suspected_fraud_flag = 1
    ) AS suspected_fraud_applications;
