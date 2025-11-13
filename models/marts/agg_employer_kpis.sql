{{ config(schema='marts', materialized='table') }}

select
  dm.employer_id,
  dm.employer_name,
  countif(ps.enrollment_status = 'enrolled') as enrolled_members,
  countif(f.recommended_flag) as members_recommended,
  countif(f.completed_flag) as members_completed,
  safe_divide(countif(f.completed_flag), nullif(countif(f.recommended_flag),0)) as screening_completion_rate,
  approx_quantiles(time_to_screening_days, 100)[safe_offset(50)] as median_time_to_screening_days,
  safe_divide(
    sum(case when f.positive_flag and f.follow_up_60d_flag then 1 else 0 end),
    nullif(sum(case when f.positive_flag then 1 else 0 end),0)
  ) as follow_up_completion_rate
from {{ ref('dim_member') }} dm
left join {{ ref('fct_screening_journey') }} f using(member_id)
left join {{ ref('int_member_program_status') }} ps using(member_id)
group by 1,2