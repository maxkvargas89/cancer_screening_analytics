{{ config(schema='intermediate', materialized='view') }}

with base as (
  select
    member_id,
    screening_type,
    min(recommendation_date) as recommendation_date,
    max(completion_date) as completion_date,
    any_value(result) as result,
    min(time_to_screening_days) as time_to_screening_days
  from {{ ref('stg_screenings') }}
  group by 1,2
)
select * from base