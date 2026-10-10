# Vietnam Garment Line Production

**Vietnam - Garment Production Lines (cutting, knit sewing, woven sewing, quality inspection, finishing and packing)**
Use case: Committed line-plan attainment and line stoppage risk

> Production planning for a synthetic network of 28 garment lines across 5 Vietnamese cities: dynamic tables, a holdout-evaluated stoppage-risk classifier, a plan-attainment forecast and grounded AI answers.

## Why Snowflake

- **Dynamic tables** reconcile plan attainment, queue hours per piece and line availability from RAW line data, with checks in `run_core.py`
- **Stoppage-risk classification** gives a holdout-evaluated next-7-day stoppage probability per line
- **Plan-attainment forecast** projects 14 days of network-wide attainment with prediction intervals
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live telemetry**: a native simulator (Snowflake only) or IoT Core, S3 and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.PRODUCTION_LINES` (28 rows) |
| Fact table | `RAW.LINE_DAILY` (2,520 line-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `CONSTRAINT_CAUSES`, `TREND_ANALYSIS` |
| ML | `ML.CONSTRAINT_RISK_SCORES`, `ML.CONSTRAINT_RISK_HOLDOUT_METRICS`, `ML.ATTAINMENT_FORECAST`, `ML.THROUGHPUT_GAP_ANOMALIES` |

Cities: Nam Dinh, Thu Dau Mot, Da Nang, Hung Yen, Tan An (Vietnamese cities used as regions; factories, lines, buyers and planners are fictional).
Line types: Cutting, Knit Sewing, Woven Sewing, Quality Inspection, Finishing and Packing.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| Plan Attainment | 97.7% |
| Line Stoppages | 235 |
| Queue Hours per Piece | 0.86 h |
| WIP Released (pieces) | 9,153,197 |
| Line Availability | 98.7% |
| Lines Monitored | 28 |
| Backup Machine Coverage | 59.3% |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily plan attainment, piece shortfall by root cause, garment line table
2. Predictive: holdout metrics, risk bands, 14-day plan-attainment forecast, throughput gap anomalies
3. Line Health: line availability, backup machine coverage, PM compliance against plan attainment, then generate the action memo
4. Live IoT: run `CALL APP.SIMULATE_TELEMETRY(20)` (Snowflake only) or `python aws/publish_telemetry.py --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_ALARM_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- The committed line plan tightens over the 90 days, so attainment drifts down late in the window. Per-line attainment ranges from 91.9% to 99.1%; Knit Sewing is the lowest line type and Thu Dau Mot the lowest city.
- Late fabric deliveries cost the most pieces of the 14 stoppage causes, ahead of marker plan rework and carton shortages; operator absenteeism occurs as often as late fabric but costs far fewer pieces.
- 20 of 28 lines have fewer backup machines with qualified operators than their critical style needs.
- The risk model is evaluated on a time-based holdout: precision 0.41 and recall 0.20 at 0.5, against a 0.40 base rate. The lift over the base rate is small; present it as triage for the daily production review, not a guarantee, since it misses most stoppages at this threshold.
- Site-wide grid power dips are excluded from stoppage labels, because the line does not cause them.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
