with scr as (
  select
    screening_id,
    member_id,
    lower(screening_type)              as screening_type,
    cast(recommendation_date as date)  as recommendation_date,
    cast(completion_date as date)      as completion_date,
    lower(nullif(result, ''))          as result,
    lower(nullif(source, ''))          as source
  from {{ ref('stg_screenings') }}
),
m as (
  select
    member_id,
    employer_id,
    initcap(first_name) as first_name,
    initcap(last_name)  as last_name,
    cast(dob as date)   as dob,
    lower(sex_at_birth) as sex_at_birth,
    lower(email)        as email,
    cast(created_at as timestamp) as created_at,
    cast(is_test_account as bool) as is_test_account
  from {{ ref('stg_members') }}
)
select
  -- Fact grain will be one row per screening event
  {{ dbt_utils.generate_surrogate_key(['scr.screening_id']) }} as fact_id,

  scr.screening_id,
  scr.member_id,
  scr.screening_type,
  scr.recommendation_date,
  scr.completion_date,
  scr.result,
  scr.source,

  m.employer_id,
  m.dob,
  m.sex_at_birth,
  m.is_test_account
from scr
left join m
  on scr.member_id = m.member_id
where coalesce(m.is_test_account, false) = false