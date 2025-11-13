{{ config(schema='staging', materialized='view') }}

with base as (
  select
    screening_id,
    member_id,
    lower(screening_type) as screening_type,
    date(recommendation_date) as recommendation_date,
    date(completion_date) as completion_date,
    lower(result) as result,
    lower(source) as source
  from {{ source('raw','raw_screenings') }}
)
select
  *,
  case when completion_date is not null and completion_date >= recommendation_date
    then date_diff(completion_date, recommendation_date, day)
  end as time_to_screening_days
from base