<!-- Testing CI/CD workflow -->
# Cancer Screening Analytics

A production-ready dbt project demonstrating end-to-end analytics engineering for cancer screening programs. Built to showcase analytics engineering skills for Color Health's Senior Analytics Engineer role.

## 🎯 Project Overview

This project models and analyzes cancer screening program data, transforming raw healthcare data into client-facing analytics that drive business decisions. The architecture follows dimensional modeling best practices (Kimball methodology) and demonstrates skills in:

- **Status:** Production-ready with multi-environment CI/CD pipeline
- **Data modeling:** Staging → Core (dimensions & facts) → Marts architecture
- **Healthcare analytics:** Cancer screening metrics, follow-up compliance, population health
- **Statistical analysis:** Logistic regression for predicting patient follow-up completion
- **Analytics engineering:** dbt best practices, incremental models, testing, documentation
- **Business intelligence:** Client-facing dashboards, KPI design, composite scoring

## 📊 Business Context

**Scenario:** Color Health operates a Virtual Cancer Clinic providing employer-sponsored cancer screening programs. This analytics infrastructure enables:

1. **Client dashboards** showing program performance to employer HR teams
2. **Population health insights** identifying underserved demographic segments
3. **Clinical outcomes tracking** demonstrating program ROI and impact
4. **Predictive analytics** for optimizing care coordination and reducing care gaps

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
│             │  
│  CLIENT     │  - mart_program_health (employer KPIs)
│  ANALYTICS  │  - mart_population_insights (demographics)
│             │  - mart_outcomes_summary (clinical outcomes)
│             │
│  INTERNAL   │  - prep_followup_analysis (feature engineering)
│  OPS        │  - mart_followup_risk_prediction (ML predictions)
│             │  - analysis_followup_descriptive (EDA)
│             │  - analysis_followup_risk_summary (model monitoring)
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
│   │   └── sources.yml
│   │
│   ├── core/                           # Dimensions & facts
│   │   ├── dim_employer.sql
│   │   ├── dim_member.sql
│   │   ├── dim_provider.sql
│   │   ├── fct_screenings.sql          # Transactional fact (560 screenings)
│   │   ├── agg_member_enrollment_summary.sql  # Aggregate fact
│   │   └── core.yml
│   │
│   └── marts/
│       ├── client_analytics/           # Client-facing dashboards
│       │   ├── mart_program_health.sql
│       │   ├── mart_population_insights.sql
│       │   ├── mart_outcomes_summary.sql
│       │   └── client_analytics.yml
│       │
│       └── internal_ops/               # Predictive analytics
│           ├── prep_followup_analysis.sql
│           ├── analysis_followup_descriptive.sql
│           ├── mart_followup_risk_prediction.sql
│           ├── analysis_followup_risk_summary.sql
│           └── internal_ops.yml
│
├── seeds/                              # Synthetic healthcare data
│   ├── raw_members.csv                 # 100 members
│   ├── raw_employers.csv               # 10 employers
│   ├── raw_enrollments.csv             # 95 enrollments
│   ├── raw_screenings.csv              # 560 screenings
│   ├── raw_providers.csv               # 10 providers
│   └── raw_followup_predictions.csv    # ML model predictions
│
├── analyses/
│   └── logistic_regression_analysis.py # Python statistical analysis
│
├── dbt_project.yml
├── packages.yml
└── README.md
```

## 📚 Data Dictionary

See model-level documentation in `.yml` files:
- `models/staging/sources.yml` - Source data definitions
- `models/core/core.yml` - Dimension & fact table definitions
- `models/marts/client_analytics/client_analytics.yml` - Client mart definitions
- `models/marts/client_analytics/internal_ops.yml` - Predictive analytics definitions

## 🧪 Testing

The project includes 30+ data quality tests:
- **Unique keys:** All surrogate and natural keys
- **Not null:** Critical foreign keys and dates
- **Referential integrity:** Relationships between facts and dimensions
- **Accepted values:** Gender, enrollment status, screening results

## 📊 Synthetic Data

This project uses synthetic healthcare data (100 members, 560 screenings, 10 employers) generated to demonstrate realistic patterns:
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

### Predictive Analytics (Follow-Up Risk)
- **Risk scores:** 0-100 non-completion risk score per member
- **Outreach prioritization:** Tier 1 (critical), Tier 2 (standard), Tier 3 (monitor)
- **Model accuracy:** 82.5% on test set
- **Feature importance:** Screening type, day of week, demographics

## 📊 Statistical Analysis: Follow-Up Completion Prediction

### Research Question
**"Will a member complete their required follow-up after an abnormal screening result?"**

### Methodology
- **Model:** Logistic regression (binary classification)
- **Sample:** 386 screenings requiring follow-up (75% train, 25% test)
- **Observation window:** 60 days from result date
- **Outcome variable:** follow_up_completed (1 = completed, 0 = not completed)

### Predictors (5 features)
1. **age_group** (categorical: Under 40, 40-49, 50-64, 65+)
2. **gender** (categorical: M, F, Other)
3. **screening_type** (categorical: Mammogram, Colonoscopy, Prostate, Cervical, Other)
4. **days_to_result** (continuous: turnaround time)
5. **day_of_week_result_delivered** (categorical: Monday-Sunday)

### Model Performance
- **Accuracy:** 82.5%
- **Precision:** 82.5%
- **Recall:** 100% (catches all actual completions)
- **F1-Score:** 0.904
- **ROC-AUC:** 0.586

### Key Findings

**Factors DECREASING follow-up completion:**
- Other screening types (OR: 0.37) - 63% less likely
- Cervical screenings (OR: 0.38) - 62% less likely
- Results on Friday (OR: 0.42) - 58% less likely
- Results on Saturday (OR: 0.57) - 43% less likely

**Factors INCREASING follow-up completion:**
- Colonoscopy screenings (OR: 1.99) - 99% more likely

### Business Application
**Risk-based outreach prioritization:**
- **Tier 1 (Critical):** <40% completion probability - immediate phone outreach
- **Tier 2 (Standard):** 40-70% completion probability - scheduled follow-up
- **Tier 3 (Monitor):** >70% completion probability - automated reminders only

**Operational impact:**
- Enables care coordinators to prioritize ~60 high-risk members per week
- Reduces care gaps by proactively reaching members before 60-day window closes
- Optimizes resource allocation by focusing on members most likely to need support

## 👤 Author
**Max Vargas**  
