# Production Optimization

**Vietnam - Textile & Garment**
Use case: Production Optimization

> Production Optimization for Vietnam - ML.FORECAST and Dynamic Tables power real-time production optimization intelligence for textile & garment in Dong Nai & Long An.

## Why Snowflake

Snowflake delivers production optimization intelligence for Vietnamese textile & garment - Dynamic Tables maintain real-time dashboards, ML.FORECAST projects key metrics, and Cortex AI generates recommendations

- **ML.FORECAST for production optimization** - Only demo for Vietnamese textile & garment
- **ML.ANOMALY_DETECTION early warning** - Detects deviations before impact
- **AI recommendations** - Cortex AI actionable guidance
- **Vietnamese context** - Local names, VND economics

## What is deployed

| | |
|---|---|
| Database | `VIETNAM_TEXTILE_PRODUCTION` |
| Service | `VIETNAM_TEXTILE_PRODUCTION_APP` |
| Compute pool | `SEA_DEMOS_VIETNAM_POOL` |
| Dimension table | `RAW.DOCUMENTS` (20 rows) |
| Fact table | `RAW.METRICS` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | VND (₫) |

Regions in play: Ho Chi Minh City, Hanoi, Binh Duong, Dong Nai, Can Tho
Segments: Cutting, Sewing, Finishing, Packing

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh VIETNAM_TEXTILE_PRODUCTION
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| Production Output | `12.4M pcs` | total across Documents |
| Line Efficiency | `84%` | average per event |
| Quality Pass Rate | `97.2%` | average per event |
| Workers Active | `8,400` | total across Documents |
| SAM Achievement | `92%` | average per event |
| Changeover Time | `2.4 hrs` | average per event |
| Absenteeism | `4.8%` | average per event |


## Demo flow

1. Overview
2. Analytics
3. AI Intelligence
4. Ask AI
5. Architecture

## Talking points

- **100K operations** - tracked in Dong Nai & Long An
- **500K metrics** - time-series data points
- **5K assets** - monitored
- **100 docs** - searchable

## Business impact

- Vietnam textile & garment sector growing rapidly (GSO Vietnam)
- AI improves outcomes 15-30% (McKinsey)
- Vietnam FDI strong in this sector (MPI)
- Real-time analytics reduces response 60-80% (Gartner)

---
Generated from `generator/demo_specs/aws-vietnam-textile-production.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-vietnam-textile-production` instead.
