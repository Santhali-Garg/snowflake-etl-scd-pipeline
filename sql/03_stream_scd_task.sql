-- ============================================================
-- SNOWFLAKE ETL + SCD TYPE 2 PIPELINE
-- 03 - STREAM, CDC AND SCD TYPE 2 TASK
-- ============================================================

-- ------------------------------------------------------------
-- 1. Create Stream on CUSTOMER_STG
-- ------------------------------------------------------------

CREATE OR REPLACE STREAM CUSTOMER_STG_STREAM
ON TABLE CUSTOMER_STG;


-- ------------------------------------------------------------
-- 2. Check Stream
-- ------------------------------------------------------------

SHOW STREAMS;

SELECT *
FROM CUSTOMER_STG_STREAM;


-- ------------------------------------------------------------
-- 3. Sample CDC change
--    This demonstrates a customer change arriving in STAGING
-- ------------------------------------------------------------

INSERT INTO CUSTOMER_STG
(
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CITY,
    LOAD_DATE,
    SOURCE_FILE
)
VALUES
(
    103,
    'Amit',
    'Bangalore',
    CURRENT_TIMESTAMP(),
    'customer_new.csv'
);


-- ------------------------------------------------------------
-- 4. Verify customer record
-- ------------------------------------------------------------

SELECT *
FROM CUSTOMER_STG
WHERE CUSTOMER_ID = 103;


-- ------------------------------------------------------------
-- 5. SCD Type 2 TASK
-- ------------------------------------------------------------

CREATE OR REPLACE TASK CUSTOMER_SCD_TASK
WAREHOUSE = ETL_DW
WHEN SYSTEM$STREAM_HAS_DATA('CUSTOMER_STG_STREAM')
AS

BEGIN

    -- Close the existing current record
    UPDATE CUSTOMER_DIM D
    SET
        END_DATE = CURRENT_DATE() - 1,
        IS_CURRENT = FALSE
    WHERE D.CUSTOMER_ID IN
    (
        SELECT CUSTOMER_ID
        FROM CUSTOMER_STG_STREAM
        WHERE METADATA$ACTION = 'INSERT'
    )
    AND D.IS_CURRENT = TRUE;


    -- Insert the new current version
    INSERT INTO CUSTOMER_DIM
    (
        CUSTOMER_ID,
        CUSTOMER_NAME,
        CITY,
        STATE,
        LOAD_DATE,
        SOURCE_FILE,
        EFFECTIVE_DATE,
        END_DATE,
        IS_CURRENT
    )
    SELECT
        S.CUSTOMER_ID,
        S.CUSTOMER_NAME,
        S.CITY,
        C.STATE,
        S.LOAD_DATE,
        S.SOURCE_FILE,
        CURRENT_DATE(),
        '9999-12-31',
        TRUE
    FROM CUSTOMER_STG_STREAM S
    LEFT JOIN CITY_STATE C
        ON UPPER(TRIM(S.CITY)) = UPPER(TRIM(C.CITY))
    WHERE METADATA$ACTION = 'INSERT';

END;


-- ------------------------------------------------------------
-- 6. Execute task manually for testing
-- ------------------------------------------------------------

EXECUTE TASK CUSTOMER_SCD_TASK;


-- ------------------------------------------------------------
-- 7. Verify SCD Type 2 history
-- ------------------------------------------------------------

SELECT
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CITY,
    STATE,
    EFFECTIVE_DATE,
    END_DATE,
    IS_CURRENT
FROM CUSTOMER_DIM
ORDER BY CUSTOMER_ID, EFFECTIVE_DATE;
