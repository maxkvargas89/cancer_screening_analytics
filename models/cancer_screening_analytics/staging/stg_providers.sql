{{ config(schema='staging', materialized='view') }}

select
  provider_id,
  npi,
  provider_name,
  specialty
from {{ source('raw','raw_providers') }}