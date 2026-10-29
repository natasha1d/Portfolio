-- =====================================================================
-- 02  Data quality and reconciliation checks
-- Every check returns one row: what was tested, the count found and a
-- PASS / REVIEW status, so problems are visible before any analysis.
-- =====================================================================

CREATE OR REPLACE TABLE result_02_data_quality AS
WITH claims_per_policy AS (
    SELECT policy_id, COUNT(*) AS n_records, SUM(claim_amount) AS amount
    FROM claim
    GROUP BY policy_id
),
checks AS (
    SELECT 'Duplicate policy IDs' AS check_name,
           (SELECT COUNT(*) - COUNT(DISTINCT policy_id) FROM policy) AS n_found
    UNION ALL
    SELECT 'Claims with no matching policy',
           (SELECT COUNT(*) FROM raw_claim r
             WHERE NOT EXISTS (SELECT 1 FROM raw_policy p WHERE p.IDpol = r.IDpol))
    UNION ALL
    SELECT 'Policies whose claim count differs from claim records',
           (SELECT COUNT(*) FROM policy p
              LEFT JOIN claims_per_policy c USING (policy_id)
             WHERE p.claim_count_raw <> COALESCE(c.n_records, 0))
    UNION ALL
    SELECT 'Policies with claims but no claim amount',
           (SELECT COUNT(*) FROM policy p
             WHERE p.claim_count_raw > 0
               AND NOT EXISTS (SELECT 1 FROM claim c WHERE c.policy_id = p.policy_id))
    UNION ALL
    SELECT 'Exposure above 1 year (capped to 1)',
           (SELECT COUNT(*) FROM policy WHERE exposure_raw > 1)
    UNION ALL
    SELECT 'Zero or negative exposure',
           (SELECT COUNT(*) FROM policy WHERE exposure_raw <= 0)
    UNION ALL
    SELECT 'More than 4 claims in a year (flagged, excluded)',
           (SELECT COUNT(*) FROM policy WHERE NOT is_valid)
    UNION ALL
    SELECT 'Zero or negative claim amounts',
           (SELECT COUNT(*) FROM claim WHERE claim_amount <= 0)
    UNION ALL
    SELECT 'Driver age outside 18-100',
           (SELECT COUNT(*) FROM policy WHERE driver_age NOT BETWEEN 18 AND 100)
    UNION ALL
    SELECT 'Missing rating factors',
           (SELECT COUNT(*) FROM policy
             WHERE driver_age IS NULL OR bonus_malus IS NULL OR vehicle_age IS NULL
                OR area IS NULL OR region IS NULL OR vehicle_brand IS NULL)
)
SELECT
    check_name,
    n_found,
    CASE WHEN n_found = 0 THEN 'PASS' ELSE 'REVIEW' END AS status
FROM checks;

-- Control totals: the clean tables must add back to the raw files
CREATE OR REPLACE TABLE result_02_control_totals AS
SELECT 'Raw files'    AS source,
       (SELECT COUNT(*) FROM raw_policy)            AS policies,
       (SELECT SUM(ClaimNb) FROM raw_policy)        AS claims_on_policies,
       (SELECT COUNT(*) FROM raw_claim)             AS claim_records,
       (SELECT ROUND(SUM(ClaimAmount), 2) FROM raw_claim) AS claim_amount
UNION ALL
SELECT 'Clean tables',
       (SELECT COUNT(*) FROM policy),
       (SELECT SUM(claim_count_raw) FROM policy),
       (SELECT COUNT(*) FROM claim),
       (SELECT ROUND(SUM(claim_amount), 2) FROM claim);
