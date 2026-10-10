-- Synthetic line-day observations for garment production lines (cutting,
-- knit sewing, woven sewing, quality inspection, finishing and packing).
-- Nothing is seeded as a prediction. Randomness is HASH-seeded, so every
-- rebuild is reproducible: per-line machine age and stoppage propensity, wear
-- between PM windows, missed PM, a committed cut plan that tightens over the
-- window, category-weighted stoppage causes, and two site-wide grid power dips.
-- Factories, lines and buyers are fictional; the cities are real Vietnamese cities.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.PRODUCTION_LINES AS
WITH line_seq AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS LINE_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 28))
), draws AS (
  SELECT LINE_INDEX,
         MOD(ABS(HASH(LINE_INDEX, 'vntxp-sew-age')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(LINE_INDEX, 'vntxp-sew-rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(LINE_INDEX, 'vntxp-sew-pm')), 1000000) / 1e6 AS U_PM,
         MOD(ABS(HASH(LINE_INDEX, 'vntxp-sew-discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(LINE_INDEX, 'vntxp-sew-throughput')), 1000000) / 1e6 AS U_THROUGHPUT
  FROM line_seq
)
SELECT 'SL-' || LPAD(LINE_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic garment line ' || LPAD(LINE_INDEX::VARCHAR, 4, '0') AS NAME,
       -- Deterministic spread (7 and 5 are coprime): every city and line type is present.
       CASE MOD(LINE_INDEX, 7) WHEN 0 THEN 'Nam Dinh' WHEN 1 THEN 'Thu Dau Mot'
            WHEN 2 THEN 'Nam Dinh' WHEN 3 THEN 'Thu Dau Mot' WHEN 4 THEN 'Da Nang'
            WHEN 5 THEN 'Hung Yen' ELSE 'Tan An' END AS REGION,
       CASE MOD(LINE_INDEX, 5) WHEN 0 THEN 'Cutting' WHEN 1 THEN 'Knit Sewing'
            WHEN 2 THEN 'Woven Sewing' WHEN 3 THEN 'Quality Inspection'
            ELSE 'Finishing and Packing' END AS CATEGORY,
       LINE_INDEX,
       ROUND(1 + U_AGE * 12, 1) AS AGE_YEARS,
       -- Base daily stoppage probability 1.0%-4.6%; ~14% of lines are chronic (x3.5).
       (0.010 + U_RATE * 0.036) * IFF(U_RATE > 0.86, 3.5, 1) AS BASE_CONSTRAINT_RATE,
       7 * (1 + FLOOR(U_PM * 3)) AS PM_INTERVAL_DAYS,
       0.58 + U_DISCIPLINE * 0.40 AS PM_COMPLETION_PROB,
       -- Qualified pieces per hour for the whole line.
       ROUND(CASE MOD(LINE_INDEX, 5) WHEN 0 THEN 260 + U_THROUGHPUT * 90
                  WHEN 1 THEN 110 + U_THROUGHPUT * 50 WHEN 2 THEN 75 + U_THROUGHPUT * 35
                  WHEN 3 THEN 180 + U_THROUGHPUT * 60 ELSE 220 + U_THROUGHPUT * 80 END, 1)
         AS QUALIFIED_UNITS_PER_HOUR,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.LINE_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), power_dips AS (
  -- Two site-wide grid power dips in the window.
  SELECT * FROM VALUES (31, 'Nam Dinh', 2.0), (58, 'Thu Dau Mot', 3.5) AS o(DAY_INDEX, REGION, HOURS)
), base AS (
  SELECT l.ID AS ENTITY_ID, l.LINE_INDEX, l.CATEGORY, l.REGION, l.AGE_YEARS,
         l.BASE_CONSTRAINT_RATE, l.PM_INTERVAL_DAYS, l.PM_COMPLETION_PROB, l.QUALIFIED_UNITS_PER_HOUR,
         d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         20.0 AS PLANNED_HOURS,
         MOD(d.DAY_INDEX + l.LINE_INDEX * 3, l.PM_INTERVAL_DAYS) AS DAYS_SINCE_PM,
         MOD(ABS(HASH(l.ID, d.DAY_INDEX, 'vntxp-sew-event')), 1000000) / 1e6 AS U_CONSTRAINT,
         MOD(ABS(HASH(l.ID, d.DAY_INDEX, 'vntxp-sew-down')), 1000000) / 1e6 + 1e-6 AS U_DOWN,
         MOD(ABS(HASH(l.ID, d.DAY_INDEX, 'vntxp-sew-cause')), 1000000) / 1e6 AS U_CAUSE,
         MOD(ABS(HASH(l.ID, d.DAY_INDEX, 'vntxp-sew-pmdone')), 1000000) / 1e6 AS U_PMDONE,
         MOD(ABS(HASH(l.ID, d.DAY_INDEX, 'vntxp-sew-load')), 1000000) / 1e6 AS U_LOAD,
         MOD(ABS(HASH(l.ID, d.DAY_INDEX, 'vntxp-sew-noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(l.ID, d.DAY_INDEX, 'vntxp-sew-hit')), 1000000) / 1e6 AS U_HIT,
         p.HOURS AS DIP_HOURS
  FROM RAW.PRODUCTION_LINES l CROSS JOIN days d
  LEFT JOIN power_dips p ON p.DAY_INDEX = d.DAY_INDEX AND p.REGION = l.REGION
), pm AS (
  SELECT *,
         IFF(DAYS_SINCE_PM = 0, 1, 0) AS PM_DUE,
         IFF(DAYS_SINCE_PM = 0 AND U_PMDONE < PM_COMPLETION_PROB, 1, 0) AS PM_COMPLETED,
         -- Wear (needles, feed dogs, cutter blades) rises between PM windows; weak discipline carries it over.
         DAYS_SINCE_PM / PM_INTERVAL_DAYS + (1 - PM_COMPLETION_PROB) AS WEAR,
         -- Committed loading tightens from about 81% to 100% of qualified capacity over the window.
         0.81 + 0.14 * DAY_INDEX / 89 + 0.05 * U_LOAD AS LOADING
  FROM base
), events AS (
  SELECT *,
         CASE WHEN DIP_HOURS IS NOT NULL THEN 1
              WHEN U_CONSTRAINT < LEAST(0.5, BASE_CONSTRAINT_RATE * (0.25 + 2.0 * WEAR) * (1 + AGE_YEARS / 25)) / 4 THEN 2
              WHEN U_CONSTRAINT < LEAST(0.5, BASE_CONSTRAINT_RATE * (0.25 + 2.0 * WEAR) * (1 + AGE_YEARS / 25)) THEN 1
              ELSE 0 END AS CONSTRAINT_COUNT
  FROM pm
), timed AS (
  SELECT *,
         -- Lost line hours: exponential, mean depends on the line type.
         CASE WHEN CONSTRAINT_COUNT = 0 THEN 0.0
              WHEN DIP_HOURS IS NOT NULL THEN DIP_HOURS
              ELSE LEAST(14.0, ROUND(CONSTRAINT_COUNT * (0.4 - LN(U_DOWN) *
                   CASE CATEGORY WHEN 'Cutting' THEN 2.6 WHEN 'Knit Sewing' THEN 3.2
                                 WHEN 'Woven Sewing' THEN 3.4 WHEN 'Quality Inspection' THEN 2.0 ELSE 1.6 END), 1))
         END AS DOWNTIME_HOURS
  FROM events
), output AS (
  SELECT *,
         PLANNED_HOURS - DOWNTIME_HOURS AS OPERATING_HOURS,
         ROUND(PLANNED_HOURS * QUALIFIED_UNITS_PER_HOUR * LOADING) AS COMMITTED,
         -- Running efficiency versus the qualified rate: minus wear, machine age and the stoppage hit.
         LEAST(0.995, GREATEST(0.52, 0.975 - 0.036 * WEAR - 0.007 * AGE_YEARS / 12 - 0.010 * U_NOISE
           - CONSTRAINT_COUNT * (0.06 + 0.07 * U_HIT))) AS EFFICIENCY,
         -- WIP queue hours per piece by line type; wear and stoppages add waiting.
         CASE CATEGORY WHEN 'Cutting' THEN 0.5 WHEN 'Knit Sewing' THEN 1.1
                       WHEN 'Woven Sewing' THEN 1.2 WHEN 'Quality Inspection' THEN 0.8 ELSE 0.4 END
           * (1 + 0.22 * WEAR + 0.45 * CONSTRAINT_COUNT + 0.12 * U_NOISE) AS QH_PER_UNIT
  FROM timed
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE, PLANNED_HOURS, DOWNTIME_HOURS, OPERATING_HOURS,
       CONSTRAINT_COUNT,
       CASE WHEN CONSTRAINT_COUNT = 0 THEN 'None'
            WHEN DIP_HOURS IS NOT NULL THEN 'Grid power dip'
            WHEN CATEGORY = 'Cutting' THEN IFF(U_CAUSE < 0.45, 'Fabric delivery late', IFF(U_CAUSE < 0.8, 'Marker plan rework', 'Cutting table down'))
            WHEN CATEGORY = 'Knit Sewing' THEN IFF(U_CAUSE < 0.5, 'Operator absenteeism', IFF(U_CAUSE < 0.8, 'Sewing machine breakdown', 'Style changeover overrun'))
            WHEN CATEGORY = 'Woven Sewing' THEN IFF(U_CAUSE < 0.55, 'Trims shortage', 'Line balancing loss')
            WHEN CATEGORY = 'Quality Inspection' THEN IFF(U_CAUSE < 0.5, 'Rework backlog', IFF(U_CAUSE < 0.8, 'Needle detector down', 'Shade variation hold'))
            ELSE IFF(U_CAUSE < 0.6, 'Carton shortage', 'Pressing station down') END AS ROOT_CAUSE,
       PM_DUE, PM_COMPLETED,
       -- Pieces released into the line queue, close to the committed plan.
       ROUND(COMMITTED * (0.96 + 0.07 * U_NOISE)) AS WIP_ARRIVALS,
       COMMITTED AS COMMITTED_UNITS,
       LEAST(COMMITTED, ROUND(OPERATING_HOURS * QUALIFIED_UNITS_PER_HOUR * EFFICIENCY)) AS UNITS_COMPLETED,
       ROUND(COMMITTED * QH_PER_UNIT + DOWNTIME_HOURS * QUALIFIED_UNITS_PER_HOUR * 0.6, 1) AS QUEUE_HOURS,
       ROUND(1.1 + 2.2 * WEAR + 3.8 * CONSTRAINT_COUNT + U_NOISE * 0.9, 2) AS THROUGHPUT_GAP_PCT,
       ROUND(320 + 60 * WEAR + 48 * CONSTRAINT_COUNT + U_NOISE * 18, 1) AS QUEUE_UNITS,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM output;

-- Backup machine qualification per line (snapshot): machines needed to run
-- the line critical style with one machine down, versus machines with
-- qualified operators today and machines in operator qualification.
CREATE TABLE RAW.LINE_QUALIFICATION AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Cutting' THEN 'Knit T-shirt' WHEN 'Knit Sewing' THEN 'Polo shirt'
                     WHEN 'Woven Sewing' THEN 'Denim jeans' WHEN 'Quality Inspection' THEN 'Outdoor jacket'
                     ELSE 'Sportswear set' END AS PRODUCT_FAMILY,
       3 + MOD(ABS(HASH(ID, 'vntxp-sew-req')), 3) AS REQUIRED_STATIONS,
       MOD(ABS(HASH(ID, 'vntxp-sew-qual')), 6) AS QUALIFIED_STATIONS,
       IFF(MOD(ABS(HASH(ID, 'vntxp-sew-qual')), 6) < 3 + MOD(ABS(HASH(ID, 'vntxp-sew-req')), 3),
           MOD(ABS(HASH(ID, 'vntxp-sew-inqual')), 3), 0) AS IN_QUALIFICATION,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.PRODUCTION_LINES;
