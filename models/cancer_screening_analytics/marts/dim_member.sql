{{ config(schema='marts', materialized='view') }}

select
  m.member_id,
  m.employer_id,
  e.employer_name,
  e.industry,
  m.first_name,
  m.last_name,
  m.dob,
  m.sex_at_birth,
  m.email,
  m.created_at,
  case
    when m.dob is not null then extract(year from current_date()) - extract(year from m.dob)
  end as age_approx
from {{ ref('stg_members') }} m
left join {{ ref('stg_employers') }} e using (employer_id)