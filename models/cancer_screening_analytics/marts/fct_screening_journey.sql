{{ config(
  schema='marts',
  materialized='table',
  partition_by={'field':'recommendation_date','data_type':'date'},
  cluster_by=['member_id','screening_type']
) }}

with s as (
  select * from {{ ref('int_screening_events') }}
),
fup as (
  select * from {{ ref('int_claims_procedures') }}
)

select
  s.member_id,
  s.screening_type,
  s.recommendation_date,
  s.completion_date,
  s.result,
  s.time_to_screening_days,
  (s.recommendation_date is not null) as recommended_flag,
  (s.completion_date is not null) as completed_flag,
  (s.result = 'positive') as positive_flag,
  case
    when s.result = 'positive'
     and exists (
       select 1 from fup
       where fup.member_id = s.member_id
         and fup.claim_date between s.completion_date and date_add(s.completion_date, interval 60 day)
     )
    then true else false
  end as follow_up_60d_flag
from s