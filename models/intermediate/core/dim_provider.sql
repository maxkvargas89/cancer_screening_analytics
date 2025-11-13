{{ config(schema='marts', materialized='view') }}

select
  provider_id,
  npi,
  provider_name,
  specialty
from {{ ref('stg_providers') }}