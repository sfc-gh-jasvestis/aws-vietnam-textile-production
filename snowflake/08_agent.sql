-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Production Optimization
-- ============================================================================
USE DATABASE TEXTILE_PRODUCTION;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.TEXTILE_PRODUCTION_AGENT
  COMMENT = 'Production Optimization AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'TEXTILE_PRODUCTION.APP.TEXTILE_PRODUCTION_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'TEXTILE_PRODUCTION.SEARCH.TEXTILE_PRODUCTION_SEARCH', TOOL_DESCRIPTION => 'Search documents for Textile & Garment information')
  )
  SYSTEM_PROMPT = 'You are the Production Optimization Agent for Vietnamese textile & garment operations in Dong Nai & Long An.';
