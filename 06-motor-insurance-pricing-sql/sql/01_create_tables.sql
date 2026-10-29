-- =====================================================================
-- 01  Load raw data and build clean analysis tables
-- Data: freMTPL2 (French motor third-party liability), CASdatasets
--   freMTPL2freq : one row per policy  (677,991 policies, exposure in years)
--   freMTPL2sev  : one row per claim   (claim amounts in EUR)
-- =====================================================================

CREATE OR REPLACE TABLE raw_policy AS
SELECT * FROM read_csv_auto('data/freMTPL2freq.csv');

CREATE OR REPLACE TABLE raw_claim AS
SELECT * FROM read_csv_auto('data/freMTPL2sev.csv');

-- ---------------------------------------------------------------------
-- Clean policy table
--  * exposure capped at 1 year (a policy-year cannot exceed 1)
--  * policies with more than 4 claims flagged as suspected data errors
--    and excluded from the modelling flag (standard treatment in the
--    literature on this dataset)
--  * rating factors banded with CASE so each band has enough data
--  * deterministic 80/20 train/test split on a hash of the policy ID,
--    so the relativities in 06 are tested on policies they never saw
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE policy AS
SELECT
    IDpol                                   AS policy_id,
    CAST(ClaimNb AS INTEGER)                AS claim_count_raw,
    LEAST(CAST(ClaimNb AS INTEGER), 4)      AS claim_count,
    Exposure                                AS exposure_raw,
    LEAST(Exposure, 1.0)                    AS exposure,
    DrivAge                                 AS driver_age,
    CASE
        WHEN DrivAge < 21 THEN '18-20'
        WHEN DrivAge < 26 THEN '21-25'
        WHEN DrivAge < 31 THEN '26-30'
        WHEN DrivAge < 41 THEN '31-40'
        WHEN DrivAge < 51 THEN '41-50'
        WHEN DrivAge < 61 THEN '51-60'
        WHEN DrivAge < 71 THEN '61-70'
        ELSE '71+'
    END                                     AS driver_age_band,
    BonusMalus                              AS bonus_malus,
    CASE
        WHEN BonusMalus = 50  THEN '050 (best)'
        WHEN BonusMalus < 60  THEN '051-059'
        WHEN BonusMalus < 80  THEN '060-079'
        WHEN BonusMalus < 100 THEN '080-099'
        ELSE '100+ (malus)'
    END                                     AS bonus_malus_band,
    VehAge                                  AS vehicle_age,
    CASE
        WHEN VehAge = 0  THEN '0 (new)'
        WHEN VehAge < 4  THEN '01-03'
        WHEN VehAge < 8  THEN '04-07'
        WHEN VehAge < 13 THEN '08-12'
        ELSE '13+'
    END                                     AS vehicle_age_band,
    CASE
        WHEN VehPower <= 5 THEN '04-05'
        WHEN VehPower <= 7 THEN '06-07'
        WHEN VehPower <= 9 THEN '08-09'
        ELSE '10+'
    END                                     AS vehicle_power_band,
    VehBrand                                AS vehicle_brand,
    VehGas                                  AS fuel_type,
    Area                                    AS area,
    Density                                 AS density,
    Region                                  AS region,
    (ClaimNb <= 4)                          AS is_valid,
    CASE WHEN hash(IDpol) % 5 = 0 THEN 'test' ELSE 'train' END AS sample
FROM raw_policy;

-- ---------------------------------------------------------------------
-- Clean claim table: add a claim ID and keep only claims that belong
-- to a known policy
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE claim AS
SELECT
    ROW_NUMBER() OVER (ORDER BY c.IDpol, c.ClaimAmount) AS claim_id,
    c.IDpol        AS policy_id,
    c.ClaimAmount  AS claim_amount
FROM raw_claim c
WHERE EXISTS (SELECT 1 FROM raw_policy p WHERE p.IDpol = c.IDpol);

-- ---------------------------------------------------------------------
-- Large-loss threshold: 99.5th percentile of individual claim amounts.
-- Claims are capped here; the part above the cap is spread back across
-- the whole portfolio as a large-loss load (see 05).
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE large_loss_threshold AS
SELECT ROUND(QUANTILE_CONT(claim_amount, 0.995), 0) AS cap
FROM claim;

-- One row per policy with its claims summed (raw and capped)
CREATE OR REPLACE TABLE policy_claims AS
SELECT
    p.*,
    COALESCE(SUM(c.claim_amount), 0)                       AS incurred,
    -- note: LEAST() ignores NULLs, so policies with no claim must be
    -- handled explicitly or they would pick up the cap as a 'claim'
    COALESCE(SUM(CASE WHEN c.claim_amount IS NOT NULL
                      THEN LEAST(c.claim_amount, t.cap) END), 0) AS incurred_capped,
    COUNT(c.claim_id)                                      AS n_claim_records
FROM policy p
CROSS JOIN large_loss_threshold t
LEFT JOIN claim c USING (policy_id)
GROUP BY ALL;
