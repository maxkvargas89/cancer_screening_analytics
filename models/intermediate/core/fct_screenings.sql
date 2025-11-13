{{ config(
  materialized='incremental',
  unique_key='fact_id',
  on_schema_change='append_new_columns',
  partition_by={'field': 'recommendation_date', 'data_type': 'date'},
  cluster_by=['member_id','screening_type']
) }}

with src as (
  select * from {{ ref('int_member_screening_keys') }}
  {% if is_incremental() %}
    where recommendation_date >
      (select coalesce(max(recommendation_date), date('2000-01-01')) from {{ this }})
  {% endif %}
)

select
  fact_id,
  screening_id,
  member_id,
  employer_id,
  screening_type,
  recommendation_date,
  completion_date,
  result,
  source,
  dob,
  sex_at_birth,
  _is_completed,
  current_timestamp() as _loaded_at
from (
  select
    src.*,
    -- convenience flag: completed vs. recommended-only
    case when completion_date is not null then true else false end as _is_completed
  from src
)