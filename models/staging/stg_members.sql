{{ config(schema='staging', materialized='view') }}

select
  member_id,
  employer_id,
  first_name,
  last_name,
  date(dob) as dob,
  lower(sex_at_birth) as sex_at_birth,
  lower(email) as email,
  timestamp(created_at) as created_at,
  is_test_account
from {{ source('raw','raw_members') }}
where coalesce(is_test_account,false) = false