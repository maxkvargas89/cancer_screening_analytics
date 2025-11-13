{{ config(schema='staging', materialized='view') }}

select
  employer_id,
  employer_name,
  industry,
  date(plan_start_date) as plan_start_date
from {{ source('raw','raw_employers') }}