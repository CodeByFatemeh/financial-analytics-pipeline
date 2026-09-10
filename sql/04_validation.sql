-- =========================================================
-- 1. SOURCE / GOLD ROW COUNT RECONCILIATION
-- =========================================================

SELECT
    'customers' AS dataset,
    (SELECT COUNT(*) FROM bronze.customers) AS bronze_rows,
    (SELECT COUNT(*) FROM gold.dim_customer) AS gold_rows

UNION ALL

SELECT
    'applications',
    (SELECT COUNT(*) FROM bronze.applications),
    (SELECT COUNT(*) FROM gold.fact_application)

UNION ALL

SELECT
    'transactions',
    (SELECT COUNT(*) FROM bronze.transactions),
    (SELECT COUNT(*) FROM gold.fact_transaction);


-- =========================================================
-- 2. CUSTOMER GRAIN
-- Expected: zero duplicate customer IDs
-- =========================================================

SELECT
    customer_id,
    COUNT(*) AS row_count

FROM gold.dim_customer

GROUP BY customer_id

HAVING COUNT(*) > 1;


-- =========================================================
-- 3. APPLICATION GRAIN
-- Expected: zero duplicates
-- =========================================================

SELECT
    application_id,
    COUNT(*) AS row_count

FROM gold.fact_application

GROUP BY application_id

HAVING COUNT(*) > 1;


-- =========================================================
-- 4. TRANSACTION GRAIN
-- Expected: zero duplicates
-- =========================================================

SELECT
    transaction_id,
    COUNT(*) AS row_count

FROM gold.fact_transaction

GROUP BY transaction_id

HAVING COUNT(*) > 1;


-- =========================================================
-- 5. ORPHAN CUSTOMER CHECK - APPLICATION
-- Expected: zero rows
-- =========================================================

SELECT
    a.application_id,
    a.customer_id

FROM gold.fact_application a

LEFT JOIN gold.dim_customer c
    ON a.customer_id = c.customer_id

WHERE c.customer_id IS NULL;


-- =========================================================
-- 6. ORPHAN CUSTOMER CHECK - TRANSACTION
-- Expected: zero rows
-- =========================================================

SELECT
    t.transaction_id,
    t.customer_id

FROM gold.fact_transaction t

LEFT JOIN gold.dim_customer c
    ON t.customer_id = c.customer_id

WHERE c.customer_id IS NULL;


-- =========================================================
-- 7. FRAUD RATE SANITY CHECK
-- =========================================================

SELECT
    COUNT(*) AS total_transactions,

    SUM(
        fraudulent_flag
    ) AS fraudulent_transactions,

    ROUND(
        AVG(
            fraudulent_flag
        ) * 100,
        4
    ) AS fraud_rate_pct

FROM gold.fact_transaction;


-- =========================================================
-- 8. APPLICATION APPROVAL RATE
-- =========================================================

SELECT
    COUNT(*) AS total_applications,

    SUM(
        approved_flag
    ) AS approved_applications,

    ROUND(
        AVG(
            approved_flag
        ) * 100,
        2
    ) AS approval_rate_pct

FROM gold.fact_application;


-- =========================================================
-- 9. PRIOR DEVICE FRAUD CHECK
-- =========================================================

SELECT
    device_has_prior_fraud_flag,

    COUNT(*) AS transactions,

    SUM(
        fraudulent_flag
    ) AS fraudulent_transactions,

    ROUND(
        AVG(
            fraudulent_flag
        ) * 100,
        4
    ) AS fraud_rate_pct

FROM gold.fact_transaction

GROUP BY device_has_prior_fraud_flag

ORDER BY device_has_prior_fraud_flag;
