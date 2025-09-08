{{ config(schema='staging', materialized='view') }}

select
  claim_id,
  member_id,
  provider_id,
  date(claim_date) as claim_date,
  cpt_code,
  diagnosis_code,
  cast(paid_amount as numeric) as paid_amount,
  place_of_service
from {{ source('raw','raw_claims') }}