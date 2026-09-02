-- Generated from generator/demo_specs/aws-vietnam-textile-production.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-vietnam-textile-production
-- This is the schema that is actually deployed for VIETNAM_TEXTILE_PRODUCTION.

-- VIETNAM_TEXTILE_PRODUCTION  (Production Optimization)
-- generated from generator/demo_specs/aws-vietnam-textile-production.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS VIETNAM_TEXTILE_PRODUCTION;
CREATE SCHEMA IF NOT EXISTS VIETNAM_TEXTILE_PRODUCTION.RAW;
CREATE SCHEMA IF NOT EXISTS VIETNAM_TEXTILE_PRODUCTION.CURATED;
CREATE SCHEMA IF NOT EXISTS VIETNAM_TEXTILE_PRODUCTION.APP;
USE DATABASE VIETNAM_TEXTILE_PRODUCTION;

-- 5 real regions; entity names carry their region so the two always agree
