-- =====================================================================
-- 04  One-way analysis of every rating factor in a single query
-- UNPIVOT turns the rating-factor columns into (factor, level) rows, so
-- one GROUP BY gives frequency, severity and pure premium for every
-- level of every factor, instead of writing one query per factor.
-- =====================================================================

CREATE OR REPLACE VIEW policy_long AS
UNPIVOT (
    SELECT policy_id, exposure, claim_count, incurred, incurred_capped,
           driver_age_band, bonus_malus_band, vehicle_age_band,
           vehicle_power_band, fuel_type, area, sample
    FROM policy_claims
    WHERE is_valid
)
ON driver_age_band, bonus_malus_band, vehicle_age_band,
   vehicle_power_band, fuel_type, area
INTO NAME factor VALUE level;

CREATE OR REPLACE TABLE result_04_one_way AS
WITH lvl AS (
    SELECT
        factor,
        level,
        SUM(exposure)        AS exposure_years,
        SUM(claim_count)     AS claims,
        SUM(incurred_capped) AS incurred_capped
    FROM policy_long
    GROUP BY factor, level
),
portfolio AS (
    SELECT SUM(claim_count) / SUM(exposure) AS freq_all
    FROM policy_claims WHERE is_valid
)
SELECT
    factor,
    level,
    ROUND(exposure_years, 0)                              AS exposure_years,
    claims,
    ROUND(claims / exposure_years, 4)                     AS frequency,
    ROUND(incurred_capped / NULLIF(claims, 0), 0)         AS severity_capped,
    ROUND(incurred_capped / exposure_years, 1)            AS pure_premium_capped,
    -- frequency relative to the whole portfolio (1.00 = average)
    ROUND((claims / exposure_years) / p.freq_all, 2)      AS frequency_index,
    -- approximate 95% interval for frequency (Poisson)
    ROUND((claims - 1.96 * SQRT(claims)) / exposure_years, 4) AS freq_lower_95,
    ROUND((claims + 1.96 * SQRT(claims)) / exposure_years, 4) AS freq_upper_95
FROM lvl
CROSS JOIN portfolio p
ORDER BY factor, level;
