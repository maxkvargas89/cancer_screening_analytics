{{
    config(
        materialized='table'
    )
}}

with members as (
    select * from {{ ref('dim_member') }}
),

member_summary as (
    select * from {{ ref('agg_member_enrollment_summary') }}
),

demographics_summary as (
    select
        ms.employer_id,
        m.age_group,
        m.gender,
        m.state,
        m.high_risk_flag,
        
        -- Population counts
        count(distinct ms.member_id) as total_members,
        count(distinct case when ms.has_completed_screening = 1 then ms.member_id end) as members_screened,
        count(distinct case when ms.has_completed_screening = 0 then ms.member_id end) as members_not_screened,
        
        -- Screening metrics
        sum(ms.total_screenings) as total_screenings,
        avg(ms.total_screenings) as avg_screenings_per_member,
        
        -- Engagement metrics
        avg(ms.days_to_first_screening) as avg_days_to_first_screening,
        count(distinct case when ms.multiple_screenings_flag = 1 then ms.member_id end) as members_with_multiple_screenings,
        
        -- Follow-up metrics
        sum(ms.follow_ups_needed) as follow_ups_needed,
        sum(ms.follow_ups_completed) as follow_ups_completed,
        
        -- Outcomes
        sum(ms.cancer_detections) as cancer_detections,
        sum(ms.abnormal_results) as abnormal_results
        
    from member_summary ms
    inner join members m on ms.member_key = m.member_key
    group by 
        ms.employer_id,
        m.age_group,
        m.gender,
        m.state,
        m.high_risk_flag
),

final as (
    select
        -- Segment identifiers
        employer_id,
        age_group,
        gender,
        state,
        high_risk_flag,
        
        -- Population size
        total_members,
        members_screened,
        members_not_screened,
        
        -- Screening rates
        round(safe_divide(members_screened, total_members) * 100, 2) as screening_rate_pct,
        total_screenings,
        round(avg_screenings_per_member, 2) as avg_screenings_per_member,
        
        -- Engagement metrics
        round(avg_days_to_first_screening, 1) as avg_days_to_first_screening,
        members_with_multiple_screenings,
        round(safe_divide(members_with_multiple_screenings, members_screened) * 100, 2) as repeat_screening_rate_pct,
        
        -- Follow-up metrics
        follow_ups_needed,
        follow_ups_completed,
        round(safe_divide(follow_ups_completed, follow_ups_needed) * 100, 2) as follow_up_compliance_rate_pct,
        
        -- Outcomes
        cancer_detections,
        abnormal_results,
        round(safe_divide(cancer_detections, total_screenings) * 1000, 2) as cancer_detection_rate_per_1000,
        
        -- Risk segmentation
        case
            when safe_divide(members_screened, total_members) * 100 < 50 then 'High Risk - Low Engagement'
            when safe_divide(members_screened, total_members) * 100 between 50 and 75 then 'Medium Risk - Moderate Engagement'
            when safe_divide(members_screened, total_members) * 100 > 75 then 'Low Risk - High Engagement'
            else 'Unknown'
        end as engagement_risk_segment,
        
        -- Care gap flag
        case 
            when members_not_screened > 0 then 1 
            else 0 
        end as has_care_gap,
        
        -- Metadata
        current_timestamp() as calculated_at
        
    from demographics_summary
)

select * from final