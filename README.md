# Cancer Screening Analytics

A production-ready dbt project demonstrating end-to-end analytics engineering for cancer screening programs. Built to showcase analytics engineering skills for Color Health's Senior Analytics Engineer role.

## 🎯 Project Overview

This project models and analyzes cancer screening program data, transforming raw healthcare data into client-facing analytics that drive business decisions. The architecture follows dimensional modeling best practices (Kimball methodology) and demonstrates skills in:

- **Data modeling:** Staging → Core (dimensions & facts) → Marts architecture
- **Healthcare analytics:** Cancer screening metrics, follow-up compliance, population health
- **Analytics engineering:** dbt best practices, incremental models, testing, documentation
- **Business intelligence:** Client-facing dashboards, KPI design, composite scoring

## 📊 Business Context

**Scenario:** Color Health operates a Virtual Cancer Clinic providing employer-sponsored cancer screening programs. This analytics infrastructure enables:

1. **Client dashboards** showing program performance to employer HR teams
2. **Population health insights** identifying underserved demographic segments
3. **Clinical outcomes tracking** demonstrating program ROI and impact

## 🏗️ Architecture
```
┌─────────────┐
│   STAGING   │  Raw data cleaning & standardization
│             │  - stg_members, stg_screenings, etc.
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    CORE     │  Reusable dimensions & facts
│             │  - dim_member, dim_employer, dim_provider
│             │  - fct_screenings (transactional)
│             │  - agg_member_enrollment_summary (aggregated)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    MARTS    │  Business-specific analytics
│             │  - mart_program_health (employer KPIs)
│             │  - mart_population_insights (demographics)
│             │  - mart_outcomes_summary (clinical outcomes)
└─────────────┘
```

## 📁 Project Structure
```
cancer_screening_analytics/
├── models/
│   ├── staging/                        # Raw data cleaning
│   │   ├── stg_members.sql
│   │   ├── stg_employers.sql
│   │   ├── stg_enrollments.sql
│   │   ├── stg_screenings.sql
│   │   ├── stg_providers.sql
│   │   ├── stg_claims.sql
│   │   ├── stg_app_events.sql
│   │   └── sources.yml
│   │
│   ├── core/                           # Dimensions & facts
│   │   ├── dim_employer.sql
│   │   ├── dim_member.sql
│   │   ├── dim_provider.sql
│   │   ├── fct_screenings.sql          # Transactional fact
│   │   ├── agg_member_enrollment_summary.sql  # Aggregate fact
│   │   └── core.yml
│   │
│   └── marts/
│       ├── client_analytics/           # Client-facing dashboards
│       │   ├── mart_program_health.sql
│       │   ├── mart_population_insights.sql
│       │   ├── mart_outcomes_summary.sql
│       │   └── client_analytics.yml
│       └── internal_ops/               # (Future: operational dashboards)
│
├── seeds/                              # Synthetic healthcare data
│   ├── raw_members.csv
│   ├── raw_employers.csv
│   ├── raw_enrollments.csv
│   ├── raw_screenings.csv
│   ├── raw_providers.csv
│   ├── raw_claims.csv
│   └── raw_app_events.csv
│
├── dbt_project.yml
├── packages.yml
└── README.md
```

## 📚 Data Dictionary

See model-level documentation in `.yml` files:
- `models/staging/sources.yml` - Source data definitions
- `models/core/core.yml` - Dimension & fact table definitions
- `models/marts/client_analytics/client_analytics.yml` - Mart definitions

## 🧪 Testing

The project includes 30+ data quality tests:
- **Unique keys:** All surrogate and natural keys
- **Not null:** Critical foreign keys and dates
- **Referential integrity:** Relationships between facts and dimensions
- **Accepted values:** Gender, enrollment status, screening results

## 📊 Synthetic Data

This project uses synthetic healthcare data (100 members, 60 screenings, 10 employers) generated to demonstrate realistic patterns:
- Age-appropriate screening types (mammograms for women 40+, colonoscopy 50+)
- 90% normal results, 8% abnormal, 2% cancer detected
- 75% follow-up compliance on abnormal results
- Engagement patterns (high/medium/low)
- Geographic and demographic variation

## 📈 Key Metrics & KPIs

### Program Health (Employer-Level)
- **Enrollment rate:** % of eligible employees enrolled
- **Participation rate:** % of enrolled members who completed screening
- **Time-to-screening:** Days from enrollment to first screening (avg, median, p90)
- **Follow-up compliance:** % of needed follow-ups completed
- **Program health score:** Composite 0-100 score

### Population Insights (Demographic Segments)
- **Screening rate by segment:** Age group, gender, state, risk profile
- **Engagement risk segmentation:** High/medium/low engagement categories
- **Care gap identification:** Segments with low screening rates

### Clinical Outcomes (Program Impact)
- **Cancer detection rate:** Per 1,000 screenings (benchmark: 4-8)
- **Result distribution:** Normal, abnormal, cancer detected
- **Care gaps:** Abnormal results needing follow-up
- **Cost per cancer detected:** ROI metric
- **Outcomes quality score:** Composite 0-100 score

## 👤 Author
**Max Vargas**  