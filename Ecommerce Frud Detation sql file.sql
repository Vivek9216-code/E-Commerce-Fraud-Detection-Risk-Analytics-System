create database Ecommerce_frud_detation;
use Ecommerce_frud_detation;

-- Q1. Overall Fraud Summary KPIs
-- ─────────────────────────────────────────────────────────────
SELECT
    COUNT(*)                                    AS total_transactions,
    SUM(is_fraud)                               AS total_fraud_txns,
    ROUND(AVG(is_fraud) * 100, 2)               AS fraud_rate_pct,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END), 2)  AS total_fraud_amount,
    ROUND(AVG(CASE WHEN is_fraud = 1 THEN amount END), 2)         AS avg_fraud_amount,
    ROUND(AVG(CASE WHEN is_fraud = 0 THEN amount END), 2)         AS avg_legit_amount
FROM transactions;

-- ─────────────────────────────────────────────────────────────
-- Q2. Fraud Rate by Product Category (Ranked)
-- ─────────────────────────────────────────────────────────────
SELECT
    product_category,
    COUNT(*)                              AS total_txns,
    SUM(is_fraud)                         AS fraud_txns,
    ROUND(AVG(is_fraud) * 100, 2)         AS fraud_rate_pct,
    ROUND(SUM(CASE WHEN is_fraud=1 THEN amount ELSE 0 END), 2) AS fraud_amount_lost,
    RANK() OVER (ORDER BY AVG(is_fraud) DESC) AS fraud_rank
FROM transactions
GROUP BY product_category
ORDER BY fraud_rate_pct DESC;

-- ─────────────────────────────────────────────────────────────
-- Q3. Top 10 Riskiest Merchants
-- ─────────────────────────────────────────────────────────────
SELECT
    merchant_id,
    COUNT(*)                                    AS total_txns,
    SUM(is_fraud)                               AS fraud_txns,
    ROUND(AVG(is_fraud) * 100, 2)               AS fraud_rate_pct,
    ROUND(SUM(CASE WHEN is_fraud=1 THEN amount ELSE 0 END), 2) AS revenue_at_risk,
    CASE
        WHEN AVG(is_fraud) > 0.15 THEN 'HIGH RISK'
        WHEN AVG(is_fraud) > 0.08 THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END AS merchant_risk_tier
FROM transactions
GROUP BY merchant_id
HAVING COUNT(*) >= 50
ORDER BY fraud_rate_pct DESC
LIMIT 10;

-- ─────────────────────────────────────────────────────────────
-- Q4. Velocity Rule — Users with 3+ orders in same hour
-- ─────────────────────────────────────────────────────────────
SELECT
    user_id,
    DATE_TRUNC('hour', timestamp)           AS order_hour,
    COUNT(*)                                AS orders_in_hour,
    SUM(amount)                             AS total_amount,
    SUM(is_fraud)                           AS fraud_count,
    STRING_AGG(transaction_id, ', ')        AS transaction_ids
FROM transactions
GROUP BY user_id, DATE_TRUNC('hour', timestamp)
HAVING COUNT(*) >= 3
ORDER BY orders_in_hour DESC, total_amount DESC
LIMIT 20;

-- ─────────────────────────────────────────────────────────────
-- Q5. Time-Based Fraud Pattern (Hour of Day)
-- ─────────────────────────────────────────────────────────────
SELECT
    EXTRACT(HOUR FROM timestamp)            AS hour_of_day,
    COUNT(*)                                AS total_txns,
    SUM(is_fraud)                           AS fraud_txns,
    ROUND(AVG(is_fraud) * 100, 2)           AS fraud_rate_pct,
    CASE
        WHEN EXTRACT(HOUR FROM timestamp) BETWEEN 0 AND 5 THEN 'Late Night (High Risk)'
        WHEN EXTRACT(HOUR FROM timestamp) BETWEEN 6 AND 11 THEN 'Morning'
        WHEN EXTRACT(HOUR FROM timestamp) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS time_slot
FROM transactions
GROUP BY hour_of_day
ORDER BY hour_of_day;

-- ─────────────────────────────────────────────────────────────
-- Q6. Repeat Offenders — Users with Multiple Fraud Transactions
-- ─────────────────────────────────────────────────────────────
SELECT
    user_id,
    COUNT(*)                                AS total_txns,
    SUM(is_fraud)                           AS fraud_count,
    ROUND(AVG(is_fraud) * 100, 2)           AS fraud_rate_pct,
    ROUND(SUM(CASE WHEN is_fraud=1 THEN amount ELSE 0 END), 2) AS total_fraud_value,
    MAX(prev_chargebacks)                   AS max_chargebacks,
    MAX(failed_attempts)                    AS max_failed_attempts
FROM transactions
GROUP BY user_id
HAVING SUM(is_fraud) >= 2
ORDER BY fraud_count DESC, total_fraud_value DESC
LIMIT 15;

-- ─────────────────────────────────────────────────────────────
-- Q7. False Positive Cost Analysis
-- (Legit transactions flagged by risk — business revenue impact)
-- ─────────────────────────────────────────────────────────────
WITH risk_scored AS (
    SELECT *,
        CASE
            WHEN (CASE WHEN ip_country_match = 'False' THEN 2 ELSE 0 END +
                  CASE WHEN device_mismatch = 'True' THEN 2 ELSE 0 END +
                  CASE WHEN velocity_1h >= 4 THEN 3 ELSE 0 END +
                  CASE WHEN prev_chargebacks >= 1 THEN 4 ELSE 0 END +
                  CASE WHEN failed_attempts >= 2 THEN 2 ELSE 0 END) >= 5
            THEN 1 ELSE 0
        END AS flagged_as_fraud
    FROM transactions
)
SELECT
    is_fraud,
    flagged_as_fraud,
    COUNT(*)                                AS count,
    ROUND(SUM(amount), 2)                   AS total_amount,
    CASE
        WHEN is_fraud = 0 AND flagged_as_fraud = 1 THEN 'FALSE POSITIVE (Revenue Lost)'
        WHEN is_fraud = 1 AND flagged_as_fraud = 1 THEN 'TRUE POSITIVE (Fraud Caught)'
        WHEN is_fraud = 1 AND flagged_as_fraud = 0 THEN 'FALSE NEGATIVE (Fraud Missed)'
        ELSE 'TRUE NEGATIVE (Legit, Correctly Passed)'
    END AS classification
FROM risk_scored
GROUP BY is_fraud, flagged_as_fraud
ORDER BY is_fraud, flagged_as_fraud;

-- ─────────────────────────────────────────────────────────────
-- Q8. Country-Level Risk Scorecard
-- ─────────────────────────────────────────────────────────────
SELECT
    country,
    COUNT(*)                                AS total_txns,
    SUM(is_fraud)                           AS fraud_txns,
    ROUND(AVG(is_fraud) * 100, 2)           AS fraud_rate_pct,
    ROUND(AVG(amount), 2)                   AS avg_txn_amount,
    ROUND(SUM(CASE WHEN is_fraud=1 THEN amount ELSE 0 END), 2) AS total_fraud_value,
    ROUND(AVG(CASE WHEN is_fraud=1 THEN amount END), 2)        AS avg_fraud_amount,
    SUM(CASE WHEN ip_country_match = 'False' THEN 1 ELSE 0 END) AS ip_mismatches
FROM transactions
GROUP BY country
ORDER BY fraud_rate_pct DESC;

-- ─────────────────────────────────────────────────────────────
-- Q9. Payment Method Risk Analysis
-- ─────────────────────────────────────────────────────────────
SELECT
    payment_method,
    COUNT(*)                                AS total_txns,
    SUM(is_fraud)                           AS fraud_txns,
    ROUND(AVG(is_fraud) * 100, 2)           AS fraud_rate_pct,
    ROUND(AVG(amount), 2)                   AS avg_txn_amount,
    ROUND(SUM(CASE WHEN is_fraud=1 THEN amount ELSE 0 END), 2) AS fraud_amount
FROM transactions
GROUP BY payment_method
ORDER BY fraud_rate_pct DESC;

-- ─────────────────────────────────────────────────────────────
-- Q10. Monthly Fraud Trend (MoM Change)
-- ─────────────────────────────────────────────────────────────
WITH monthly AS (
    SELECT
        EXTRACT(MONTH FROM timestamp)       AS month_num,
        TO_CHAR(timestamp, 'Mon YYYY')      AS month_label,
        COUNT(*)                            AS total_txns,
        SUM(is_fraud)                       AS fraud_txns,
        ROUND(AVG(is_fraud) * 100, 2)       AS fraud_rate_pct,
        ROUND(SUM(CASE WHEN is_fraud=1 THEN amount ELSE 0 END), 2) AS fraud_amount
    FROM transactions
    GROUP BY month_num, month_label
)
SELECT *,
    fraud_txns - LAG(fraud_txns) OVER (ORDER BY month_num) AS mom_fraud_change,
    ROUND(
        (fraud_txns - LAG(fraud_txns) OVER (ORDER BY month_num))
        * 100.0 / NULLIF(LAG(fraud_txns) OVER (ORDER BY month_num), 0), 2
    ) AS mom_pct_change
FROM monthly
ORDER BY month_num;