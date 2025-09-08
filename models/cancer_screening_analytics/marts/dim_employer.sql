{{ config(schema='marts', materialized='view') }}

select
  employer_id,
  employer_name,
  industry,
  plan_start_date
from {{ ref('stg_employers') }}