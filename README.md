# cancer_screening_analytics
A dbt project that models and analyzes cancer screening program data. The project is designed to demonstrate end-to-end analytics engineering best practices: staging raw data, building intermediate transformations, and publishing clean marts and KPIs.

## Project Structure
```
cancer_screening_analytics/
├── models/
│   ├── staging/         # Raw → clean staging models
│   ├── intermediate/    # Business logic + joins across sources
│   ├── marts/           # Final fact/dim tables and KPIs
│   └── schema.yml       # Tests + documentation
├── seeds/               # Seed CSVs for raw source data
├── analyses/            # One-off exploratory SQL
├── tests/               # Custom schema + data tests
├── macros/              # Reusable SQL macros
└── dbt_project.yml      # Project configuration
```

## Data Flow
	1.	Seeds (/seeds): Provide sample raw datasets (e.g. members, enrollments, claims, app events).
	2.	Staging models (/models/staging): Standardize column names, formats, and apply light transformations.
	3.	Intermediate models (/models/intermediate): Join across domains, apply business rules, and prepare for marts.
	4.	Marts (/models/marts): Fact and dimension tables for analysis, including program KPIs.

## Testing & Quality
	•	Built-in dbt tests: unique, not_null, relationships, accepted_values
	•	Custom tests: Defined in schema files for business rules (e.g., unique member+screening_type).
	•	Run tests with: dbt test

## How to Run
  1.	Install dependencies: dbt deps
  2. Seed the project (load CSVs to warehouse): dbt seed
  3. Run models: dbt run
  4. Test everything: dbt build

## Environments
This project uses a multi-layer schema pattern in BigQuery:
	•	dbt_mvargas_staging
	•	dbt_mvargas_intermediate
	•	dbt_mvargas_marts

## Goals
  •	Demonstrate analytics engineering workflow in dbt Cloud.
	•	Show how to define KPIs, build data pipelines, and enable self-service analytics.
	•	Provide a foundation for expansion into production-grade cancer screening analytics.

### Author
Max Vargas
