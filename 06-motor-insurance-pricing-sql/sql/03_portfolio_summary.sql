-- =====================================================================
-- 03  Portfolio summary
--   frequency    = claims / exposure-years
--   severity     = incurred / claims
--   pure premium = incurred / exposure-years  (= frequency x severity)
-- =====================================================================

CREATE OR REPLACE TABLE result_03_portfolio AS
SELECT
    COUNT(*)                                      AS policies,
    ROUND(SUM(exposure), 0)                       AS exposure_years,
    SUM(claim_count)                              AS claims,
    ROUND(SUM(claim_count) / SUM(exposure), 4)    AS frequency,
    ROUND(SUM(incurred) / SUM(claim_count), 0)    AS severity,
    ROUND(SUM(incurred) / SUM(exposure), 1)       AS pure_premium,
    ROUND(SUM(incurred_capped) / SUM(exposure), 1) AS pure_premium_capped
FROM policy_claims
WHERE is_valid;

-- By region, ranked by pure premium, with each region's share of
-- exposure and of incurred claims (window functions over the totals)
CREATE OR REPLACE TABLE result_03_by_region AS
WITH r AS (
    SELECT
        region,
        SUM(exposure)        AS exposure_years,
        SUM(claim_count)     AS claims,
        SUM(incurred)        AS incurred,
        SUM(incurred_capped) AS incurred_capped
    FROM policy_claims
    WHERE is_valid
    GROUP BY region
)
SELECT
    region,
    ROUND(exposure_years, 0)                                      AS exposure_years,
    claims,
    ROUND(claims / exposure_years, 4)                             AS frequency,
    ROUND(incurred_capped / NULLIF(claims, 0), 0)                 AS severity_capped,
    ROUND(incurred_capped / exposure_years, 1)                    AS pure_premium_capped,
    ROUND(100 * exposure_years / SUM(exposure_years) OVER (), 1)  AS pct_exposure,
    ROUND(100 * incurred / SUM(incurred) OVER (), 1)              AS pct_incurred,
    RANK() OVER (ORDER BY incurred_capped / exposure_years DESC)  AS risk_rank
FROM r
ORDER BY risk_rank;
