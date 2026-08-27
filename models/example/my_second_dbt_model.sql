
-- Use the `ref` function to select from other models

    SELECT
        p.RECORD_ID,
        p.LEAD_ID,
        TRIM(INITCAP(REGEXP_REPLACE(LEAD_PATTERNS, r'[^A-Za-z0-9,]+', ' '))) AS LEAD_PATTERNS,
        CURRENT_TIMESTAMP() AS SOURCE_LOADED_AT
    FROM `BRONZE_LAYER.TBLLEADS_PATTERN` p;