-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Production Optimization
-- ============================================================================
USE DATABASE TEXTILE_PRODUCTION;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.TEXTILE_PRODUCTION_SEARCH
  ON CONTENT
  ATTRIBUTES DOC_TYPE, CATEGORY
  WAREHOUSE = TEXTILE_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.DOCUMENTS
);
