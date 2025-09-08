-- Simple demo mapping: colonoscopy = follow-up for colorectal, mammogram for breast, etc.
{{ config(schema='intermediate', materialized='view') }}

with mapped as (
  select
    c.member_id,
    c.claim_date,
    c.cpt_code,
    case
      when c.cpt_code in (45378,45380) then 'colorectal_followup'
      when c.cpt_code in (77066,77067) then 'breast_followup'
      else null
    end as followup_type
  from {{ ref('stg_claims') }} c
)
select * from mapped where followup_type is not null