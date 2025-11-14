{{
    config(
        materialized='incremental',
        unique_key='journey_key'
    )
}}

with enrollments as (
    select * from {{ ref('stg_enrollments') }}
    {% if is_incremental() %}
        where enrollment_date > (select max(enrollment_date) from {{ this }})
    {% endif %}
),

screenings as (
    select * from {{ ref('fct_screenings') }}
),

member_screening_summary as (
    select
        member_id,
        count(*) as total_screenings,
        count(case when cancer_detected_flag = 1 then 1 end) as cancer_detections,
        count(case when abnormal_flag = 1 then 1 end) as abnormal_results,
        count(case when normal_flag = 1 then 1 end) as normal_results,
        count(case when follow_up_needed then 1 end) as follow_ups_needed,
        count(case when follow_up_completed_flag = 1 then 1 end) as follow_ups_completed,
        min(screening_date) as first_screening_date,
        max(screening_date) as most_recent_screening_date,
        sum(cost) as total_screening_cost,
        avg(days_to_result) as avg_days_to_result
    from screenings
    group by member_id
),

final as (
    select
        -- Primary key
        {{ dbt_utils.generate_surrogate_key(['e.member_id']) }} as journey_key,
        
        -- Foreign keys (generated from natural keys)
        {{ dbt_utils.generate_surrogate_key(['e.member_id']) }} as member_key,
        {{ dbt_utils.generate_surrogate_key(['e.employer_id']) }} as employer_key,
        
        -- Natural keys
        e.member_id,
        e.employer_id,
        
        -- Enrollment info
        e.enrollment_id,
        e.enrollment_date,
        e.enrollment_channel,
        e.status as enrollment_status,
        
        -- Screening summary metrics
        coalesce(s.total_screenings, 0) as total_screenings,
        coalesce(s.cancer_detections, 0) as cancer_detections,
        coalesce(s.abnormal_results, 0) as abnormal_results,
        coalesce(s.normal_results, 0) as normal_results,
        coalesce(s.follow_ups_needed, 0) as follow_ups_needed,
        coalesce(s.follow_ups_completed, 0) as follow_ups_completed,
        s.first_screening_date,
        s.most_recent_screening_date,
        coalesce(s.total_screening_cost, 0) as total_screening_cost,
        s.avg_days_to_result,
        
        -- Calculated metrics
        case 
            when s.total_screenings > 0 then 1 
            else 0 
        end as has_completed_screening,
        
        case 
            when s.first_screening_date is not null 
            then DATE_DIFF(s.first_screening_date, e.enrollment_date, DAY)
        end as days_to_first_screening,
        
        case 
            when s.follow_ups_needed > 0 
            then round(safe_divide(s.follow_ups_completed, s.follow_ups_needed), 2)
        end as follow_up_completion_rate,
        
        -- Engagement flags
        case when s.total_screenings >= 2 then 1 else 0 end as multiple_screenings_flag,
        case when s.cancer_detections > 0 then 1 else 0 end as cancer_detected_flag,
        
        -- Metadata
        e.loaded_at
        
    from enrollments e
    left join member_screening_summary s on e.member_id = s.member_id
)

select * from final