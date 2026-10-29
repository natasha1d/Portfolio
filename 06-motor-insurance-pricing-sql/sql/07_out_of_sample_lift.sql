-- =====================================================================
-- 07  Does the score separate good and bad risks on unseen policies?
-- Test sample only (20% of policies held out in 01).
--
-- Exposure-weighted deciles: policies are sorted by risk score and cut
-- into ten groups of equal exposure using a running SUM() window.
-- Lift  = pure premium of the worst decile / pure premium of the best
-- Gini  = from the Lorenz curve of cumulative exposure vs cumulative
--         incurred, ordered from lowest to highest predicted risk
-- =====================================================================

CREATE OR REPLACE TABLE result_07_deciles AS
WITH ordered AS (
    SELECT
        *,
        SUM(exposure) OVER (ORDER BY risk_score, policy_id
                            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
            / SUM(exposure) OVER () AS cum_exposure_share
    FROM policy_score
    WHERE sample = 'test'
),
deciled AS (
    SELECT *, LEAST(CAST(CEIL(cum_exposure_share * 10) AS INTEGER), 10) AS decile
    FROM ordered
),
portfolio AS (
    SELECT SUM(incurred_capped) / SUM(exposure) AS pp_all FROM policy_score WHERE sample = 'test'
)
SELECT
    decile,
    COUNT(*)                                                      AS policies,
    ROUND(SUM(exposure), 0)                                       AS exposure_years,
    SUM(claim_count)                                              AS claims,
    ROUND(AVG(risk_score), 3)                                     AS avg_predicted_relativity,
    ROUND(SUM(claim_count) / SUM(exposure), 4)                    AS actual_frequency,
    ROUND(SUM(incurred_capped) / SUM(exposure) / MAX(p.pp_all), 3) AS actual_relativity
FROM deciled
CROSS JOIN portfolio p
GROUP BY decile
ORDER BY decile;

CREATE OR REPLACE TABLE result_07_model_metrics AS
WITH lorenz AS (
    SELECT
        SUM(exposure) OVER w / SUM(exposure) OVER ()              AS x,
        SUM(incurred_capped) OVER w / SUM(incurred_capped) OVER () AS y
    FROM policy_score
    WHERE sample = 'test'
    WINDOW w AS (ORDER BY risk_score, policy_id
                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
),
area_under AS (
    -- trapezium rule under the Lorenz curve
    SELECT SUM((x - lag_x) * (y + lag_y) / 2) AS auc
    FROM (
        SELECT x, y,
               COALESCE(LAG(x) OVER (ORDER BY x, y), 0) AS lag_x,
               COALESCE(LAG(y) OVER (ORDER BY x, y), 0) AS lag_y
        FROM lorenz
    )
),
d AS (SELECT * FROM result_07_deciles)
SELECT
    ROUND(1 - 2 * auc, 3)                                                        AS gini_test,
    ROUND((SELECT actual_relativity FROM d WHERE decile = 10)
        / (SELECT actual_relativity FROM d WHERE decile = 1), 2)                 AS lift_top_vs_bottom,
    ROUND((SELECT CORR(avg_predicted_relativity, actual_relativity) FROM d), 3)  AS decile_correlation
FROM area_under;
