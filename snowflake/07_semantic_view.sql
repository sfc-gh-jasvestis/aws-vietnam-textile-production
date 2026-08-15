-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Production Optimization
-- ============================================================================
USE DATABASE TEXTILE_PRODUCTION;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.TEXTILE_PRODUCTION_ANALYTICS
  COMMENT = 'Textile & Garment production optimization analytics'
AS
  TABLES (
    CURATED.PERFORMANCE_DASHBOARD AS performance_dashboard,CURATED.TREND_ANALYTICS AS trend_analytics,CURATED.FORECAST_INPUT AS forecast_input,CURATED.OPERATIONAL_RISK AS operational_risk
  );
