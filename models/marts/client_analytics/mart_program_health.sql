{{
    config(
        materialized='table'
    )
}}

with employers as (
    select * from {{ ref('dim_employer') }}
),

members as (
    select * from {{ ref('dim_member') }}
),

member_summary as (
    select * from {{ ref('agg_member_enrollment_summary') }}
),

employer_metrics as (
    select
        m.employer_id,
        
        -- Enrollment metrics
        count(distinct m.member_id) as total_enrolled_members,
        count(distinct case when m.enrollment_status = 'Active' then m.member_id end) as active_members,
        count(distinct case when m.enrollment_status = 'Completed' then m.member_id end) as completed_members,
        count(distinct case when m.enrollment_status = 'Inactive' then m.member_id end) as inactive_members,
        
        -- Participation metrics
        count(distinct case when m.has_completed_screening = 1 then m.member_id end) as members_completed_screening,
        sum(m.total_screenings) as total_screenings,
        
        -- Time-to-screening metrics
        avg(m.days_to_first_screening) as avg_days_to_first_screening,
        approx_quantiles(m.days_to_first_screening, 100)[offset(50)] as median_days_to_first_screening,
        approx_quantiles(m.days_to_first_screening, 100)[offset(90)] as p90_days_to_first_screening,
        
        -- Follow-up metrics
        sum(m.follow_ups_needed) as total_follow_ups_needed,
        sum(m.follow_ups_completed) as total_follow_ups_completed,
        
        -- Cost metrics
        sum(m.total_screening_cost) as total_program_cost,
        avg(m.total_screening_cost) as avg_cost_per_member,
        
        -- Engagement metrics
        count(distinct case when m.multiple_screenings_flag = 1 then m.member_id end) as members_with_multiple_screenings,
        
        -- Cancer detection
        sum(m.cancer_detections) as total_cancer_detections
        
    from member_summary m
    group by m.employer_id
),

final as (
    select
        -- Employer info
        e.employer_id,
        e.employer_name,
        e.industry,
        e.employee_count,
        e.state,
        e.contract_start_date,
        
        -- Enrollment metrics
        coalesce(em.total_enrolled_members, 0) as total_enrolled_members,
        coalesce(em.active_members, 0) as active_members,
        coalesce(em.completed_members, 0) as completed_members,
        coalesce(em.inactive_members, 0) as inactive_members,
        
        -- Enrollment rate (assuming employee_count = eligible population)
        round(safe_divide(em.total_enrolled_members, e.employee_count) * 100, 2) as enrollment_rate_pct,
        
        -- Participation metrics
        coalesce(em.members_completed_screening, 0) as members_completed_screening,
        coalesce(em.total_screenings, 0) as total_screenings,
        round(safe_divide(em.members_completed_screening, em.total_enrolled_members) * 100, 2) as participation_rate_pct,
        round(safe_divide(em.total_screenings, em.members_completed_screening), 2) as avg_screenings_per_participating_member,
        
        -- Time-to-screening metrics
        round(em.avg_days_to_first_screening, 1) as avg_days_to_first_screening,
        round(em.median_days_to_first_screening, 1) as median_days_to_first_screening,
        round(em.p90_days_to_first_screening, 1) as p90_days_to_first_screening,
        
        -- Follow-up metrics
        coalesce(em.total_follow_ups_needed, 0) as total_follow_ups_needed,
        coalesce(em.total_follow_ups_completed, 0) as total_follow_ups_completed,
        round(safe_divide(em.total_follow_ups_completed, em.total_follow_ups_needed) * 100, 2) as follow_up_compliance_rate_pct,
        
        -- Cost metrics
        coalesce(em.total_program_cost, 0) as total_program_cost,
        round(em.avg_cost_per_member, 2) as avg_cost_per_member,
        round(safe_divide(em.total_program_cost, em.members_completed_screening), 2) as cost_per_completed_screening,
        
        -- Engagement metrics
        coalesce(em.members_with_multiple_screenings, 0) as members_with_multiple_screenings,
        round(safe_divide(em.members_with_multiple_screenings, em.members_completed_screening) * 100, 2) as repeat_screening_rate_pct,
        
        -- Outcomes
        coalesce(em.total_cancer_detections, 0) as total_cancer_detections,
        round(safe_divide(em.total_cancer_detections, em.total_screenings) * 1000, 2) as cancers_detected_per_1000_screenings,
        
        -- Program health score (simple composite 0-100)
        round(
            (coalesce(safe_divide(em.active_members, em.total_enrolled_members), 0) * 20) +               -- 20% weight on activation
            (coalesce(safe_divide(em.members_completed_screening, em.total_enrolled_members), 0) * 35) +  -- 35% weight on participation
            (coalesce(safe_divide(em.total_follow_ups_completed, em.total_follow_ups_needed), 0) * 35) +  -- 35% weight on follow-up
            (case when em.avg_days_to_first_screening <= 10 then 10                                       -- 10% weight on screening time
                    when em.avg_days_to_first_screening between 11 and 20 then 5
                    else 0 end)                            
        , 0) as program_health_score,
        
        -- Metadata
        current_timestamp() as calculated_at
        
    from employers e
    left join employer_metrics em on e.employer_id = em.employer_id
)

select * from final