-- 05  Large losses
-- A handful of very large claims can swamp a segment's experience. Claims are capped at the 99.5th percentile; the excess above the cap is charged back to everyone as a flat large-loss load.
-- Claim size distribution
CREATE OR REPLACE TABLE result_05_severity_distribution AS
WITH banded AS (
    SELECT
        claim_amount,
        CASE
            WHEN claim_amount <   500 THEN '1: under 500'
            WHEN claim_amount <  1000 THEN '2: 500 - 1k'
            WHEN claim_amount <  2000 THEN '3: 1k - 2k'
            WHEN claim_amount <  5000 THEN '4: 2k - 5k'
            WHEN claim_amount < 20000 THEN '5: 5k - 20k'
            WHEN claim_amount < 100000 THEN '6: 20k - 100k'
            ELSE '7: 100k+'
        END AS size_band
    FROM claim
)
SELECT
    size_band,
    COUNT(*)                                                    AS claims,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)          AS pct_of_claims,
    ROUND(SUM(claim_amount), 0)                                 AS amount,
    ROUND(100 * SUM(claim_amount) / SUM(SUM(claim_amount)) OVER (), 2) AS pct_of_amount
FROM banded
GROUP BY size_band
ORDER BY size_band;

-- Cap, excess and large-loss load
CREATE OR REPLACE TABLE result_05_large_loss_load AS
SELECT
    t.cap                                                         AS cap_99_5_pct,
    COUNT(*) FILTER (WHERE c.claim_amount > t.cap)                AS claims_above_cap,
    ROUND(SUM(c.claim_amount), 0)                                 AS total_incurred,
    ROUND(SUM(GREATEST(c.claim_amount - t.cap, 0)), 0)            AS excess_above_cap,
    ROUND(100 * SUM(GREATEST(c.claim_amount - t.cap, 0)) / SUM(c.claim_amount), 1)
                                                                  AS pct_of_incurred_above_cap,
    -- multiply capped pure premiums by this factor to get back to total cost
    ROUND(SUM(c.claim_amount) / SUM(LEAST(c.claim_amount, t.cap)), 4) AS large_loss_load
FROM claim c
CROSS JOIN large_loss_threshold t
GROUP BY t.cap;

-- The ten largest claims and the policies behind them
CREATE OR REPLACE TABLE result_05_top_claims AS
SELECT
    RANK() OVER (ORDER BY c.claim_amount DESC) AS rank,
    c.claim_id,
    c.policy_id,
    ROUND(c.claim_amount, 0)                   AS claim_amount,
    p.driver_age, p.bonus_malus, p.vehicle_age, p.area, p.region
FROM claim c
JOIN policy p USING (policy_id)
QUALIFY rank <= 10
ORDER BY rank;
