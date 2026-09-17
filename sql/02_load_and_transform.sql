-- ============================================================
-- SNOWFLAKE ETL + SCD TYPE 2 PIPELINE
-- 02 - LOAD, VALIDATE AND TRANSFORM
-- ============================================================

-- ------------------------------------------------------------
-- 1. Load data from Snowflake Stage into RAW
-- ------------------------------------------------------------

COPY INTO CUSTOMER_RAW
FROM @CUSTOMER_STAGE
FILE_FORMAT = (
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
);

-- Check loaded raw data
SELECT *
FROM CUSTOMER_RAW;


-- ------------------------------------------------------------
-- 2. Validate NULL values
-- ------------------------------------------------------------

SELECT *
FROM CUSTOMER_RAW
WHERE CUSTOMER_ID IS NULL
   OR CUSTOMER_NAME IS NULL
   OR CITY IS NULL;


-- ------------------------------------------------------------
-- 3. Check duplicate customer records
-- ------------------------------------------------------------

SELECT
    CUSTOMER_ID,
    COUNT(*) AS RECORD_COUNT
FROM CUSTOMER_RAW
GROUP BY CUSTOMER_ID
HAVING COUNT(*) > 1;


-- ------------------------------------------------------------
-- 4. Capture invalid records in ERROR table
-- ------------------------------------------------------------

INSERT INTO CUSTOMER_ERROR
(
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CITY,
    ERROR_REASON,
    LOAD_DATE,
    SOURCE_FILE
)
SELECT
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CITY,
    CASE
        WHEN CUSTOMER_ID IS NULL THEN 'CUSTOMER_ID IS NULL'
        WHEN CUSTOMER_NAME IS NULL THEN 'CUSTOMER_NAME IS NULL'
        WHEN CITY IS NULL THEN 'CITY IS NULL'
    END AS ERROR_REASON,
    LOAD_DATE,
    SOURCE_FILE
FROM CUSTOMER_RAW
WHERE CUSTOMER_ID IS NULL
   OR CUSTOMER_NAME IS NULL
   OR CITY IS NULL;


-- ------------------------------------------------------------
-- 5. Transform and load valid records into STAGING
-- ------------------------------------------------------------

INSERT INTO CUSTOMER_STG
(
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CITY,
    LOAD_DATE,
    SOURCE_FILE
)
SELECT
    CUSTOMER_ID,
    TRIM(CUSTOMER_NAME) AS CUSTOMER_NAME,
    UPPER(TRIM(CITY)) AS CITY,
    LOAD_DATE,
    SOURCE_FILE
FROM CUSTOMER_RAW
WHERE CUSTOMER_ID IS NOT NULL
  AND CUSTOMER_NAME IS NOT NULL
  AND CITY IS NOT NULL;


-- ------------------------------------------------------------
-- 6. Verify staging data
-- ------------------------------------------------------------

SELECT *
FROM CUSTOMER_STG
ORDER BY CUSTOMER_ID;
