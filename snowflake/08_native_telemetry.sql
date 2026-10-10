-- ============================================================================
-- 08_native_telemetry.sql - Snowflake-only build: live telemetry without AWS.
-- Creates RAW.LIVE_TELEMETRY (same columns as the Snowpipe target created by
-- aws/setup_aws.py) and APP.SIMULATE_TELEMETRY(N), which inserts synthetic
-- sewing-line controller readings with the same value ranges and ~10% ALARM rate as
-- aws/publish_telemetry.py. Rows are inserted directly; this simulates a
-- sewing-line controller feed and is not Snowpipe Streaming.
-- Run before 06_intelligence.sql (the alert reads RAW.LIVE_TELEMETRY).
-- Idempotent: safe to run in the AWS build too.
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS APP;

CREATE TABLE IF NOT EXISTS RAW.LIVE_TELEMETRY (
  LINE_ID VARCHAR, EVENT_TS TIMESTAMP_NTZ, THROUGHPUT_GAP_PCT FLOAT, QUEUE_UNITS FLOAT,
  STATUS VARCHAR, IOT_RECEIVED_TS TIMESTAMP_NTZ, SOURCE_FILE VARCHAR,
  LOADED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP());

CREATE OR REPLACE PROCEDURE APP.SIMULATE_TELEMETRY(N NUMBER)
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  IF (N < 1 OR N > 1000) THEN
    RETURN 0;
  END IF;
  INSERT INTO RAW.LIVE_TELEMETRY (LINE_ID, EVENT_TS, THROUGHPUT_GAP_PCT, QUEUE_UNITS, STATUS, IOT_RECEIVED_TS, SOURCE_FILE)
    WITH g AS (
      SELECT 'SL-' || LPAD(UNIFORM(0, 27, RANDOM())::VARCHAR, 4, '0') AS LINE_ID,
             UNIFORM(0::FLOAT, 1::FLOAT, RANDOM()) < 0.1 AS IS_ALARM,
             SYSDATE() AS TS, SEQ4() AS I
      FROM TABLE(GENERATOR(ROWCOUNT => 1000))
    )
    -- NORMAL() needs a constant mean, so the alarm offset is added outside it.
    SELECT LINE_ID, TS,
           ROUND(IFF(IS_ALARM, 8.4, 2.3) + NORMAL(0, 0.7, RANDOM()), 2),
           ROUND(IFF(IS_ALARM, 455, 350) + NORMAL(0, 20, RANDOM()), 1),
           IFF(IS_ALARM, 'ALARM', 'RUNNING'), TS, 'APP.SIMULATE_TELEMETRY'
    FROM g
    WHERE I < :N;
  RETURN SQLROWCOUNT;
END;
$$;

-- Optional continuous feed for longer demos (suspended; RESUME to start, SUSPEND after).
CREATE OR REPLACE TASK APP.TASK_SIMULATE_TELEMETRY
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '1 MINUTE'
AS
  CALL APP.SIMULATE_TELEMETRY(5);
