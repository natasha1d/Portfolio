-- =====================================================================
-- 06  Credibility-weighted rating relativities (training data only)
--
-- relativity     = level pure premium / portfolio pure premium
-- credibility Z  = min(1, sqrt(claims / 1082))
--                  limited-fluctuation standard: 1,082 claims gives a
--                  90% chance that observed frequency is within 5% of
--                  the true frequency
-- credible rel.  = Z x observed relativity + (1 - Z) x 1.00
--
-- Small segments are pulled towards the average, so a few unlucky
-- claims in a thin cell do not create an extreme rate.
-- =====================================================================

CREATE OR REPLACE TABLE result_06_relativities AS
WITH lvl AS (
    SELECT
        factor,
        level,
        SUM(exposure)        AS exposure_years,
        SUM(claim_count)     AS claims,
        SUM(incurred_capped) AS incurred_capped
    FROM policy_long
    WHERE sample = 'train'
    GROUP BY factor, level
),
portfolio AS (
    SELECT SUM(incurred_capped) / SUM(exposure) AS pp_all
    FROM policy_claims
    WHERE is_valid AND sample = 'train'
),
rel AS (
    SELECT
        l.*,
        (l.incurred_capped / l.exposure_years) / p.pp_all AS observed_relativity,
        LEAST(1.0, SQRT(l.claims / 1082.0))               AS credibility
    FROM lvl l CROSS JOIN portfolio p
)
SELECT
    factor,
    level,
    ROUND(exposure_years, 0)                                              AS exposure_years,
    claims,
    ROUND(observed_relativity, 3)                                         AS observed_relativity,
    ROUND(credibility, 3)                                                 AS credibility,
    ROUND(credibility * observed_relativity + (1 - credibility) * 1.0, 3) AS credible_relativity
FROM rel
ORDER BY factor, level;

-- ---------------------------------------------------------------------
-- Simple multiplicative risk score for every policy:
-- product of its credible relativities for the main factors.
-- (A one-way product ignores correlation between factors; a GLM would
--  fix that. The point here is to test, out of sample, whether the
--  relativities rank risk correctly.)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE policy_score AS
WITH r AS (
    SELECT factor, level, credible_relativity AS rel FROM result_06_relativities
)
SELECT
    pc.policy_id,
    pc.sample,
    pc.exposure,
    pc.claim_count,
    pc.incurred_capped,
    r_age.rel * r_bm.rel * r_veh.rel * r_area.rel * r_pow.rel * r_fuel.rel AS risk_score
FROM policy_claims pc
JOIN r r_age  ON r_age.factor  = 'driver_age_band'    AND r_age.level  = pc.driver_age_band
JOIN r r_bm   ON r_bm.factor   = 'bonus_malus_band'   AND r_bm.level   = pc.bonus_malus_band
JOIN r r_veh  ON r_veh.factor  = 'vehicle_age_band'   AND r_veh.level  = pc.vehicle_age_band
JOIN r r_area ON r_area.factor = 'area'               AND r_area.level = pc.area
JOIN r r_pow  ON r_pow.factor  = 'vehicle_power_band' AND r_pow.level  = pc.vehicle_power_band
JOIN r r_fuel ON r_fuel.factor = 'fuel_type'          AND r_fuel.level = pc.fuel_type
WHERE pc.is_valid;
