{{
    config(
        materialized='table'
    )
}}

with employers as (
    select * from {{ ref('dim_employer') }}
),

screenings as (
    select * from {{ ref('fct_screenings') }}
),

screening_outcomes as (
    select
        s.employer_id,
        s.screening_type,
        s.result,
        
        -- Screening counts
        count(*) as total_screenings,
        count(distinct s.member_id) as unique_members_screened,
        
        -- Result metrics
        count(case when s.normal_flag = 1 then 1 end) as normal_results,
        count(case when s.abnormal_flag = 1 then 1 end) as abnormal_results,
        count(case when s.cancer_detected_flag = 1 then 1 end) as cancer_detections,
        
        -- Follow-up metrics
        count(case when s.follow_up_needed then 1 end) as follow_ups_needed,
        count(case when s.follow_up_completed_flag = 1 then 1 end) as follow_ups_completed,
        count(case when s.follow_up_missing_flag = 1 then 1 end) as follow_ups_missing,
        
        -- Time metrics
        avg(s.days_to_result) as avg_days_to_result,
        
        -- Cost metrics
        sum(s.cost) as total_cost,
        avg(s.cost) as avg_cost_per_screening
        
    from screenings s
    group by 
        s.employer_id,
        s.screening_type,
        s.result
),

employer_summary as (
    select
        employer_id,
        
        -- Overall metrics
        sum(total_screenings) as total_screenings,
        count(distinct unique_members_screened) as unique_members_screened,
        sum(normal_results) as normal_results,
        sum(abnormal_results) as abnormal_results,
        sum(cancer_detections) as cancer_detections,
        
        -- Follow-up summary
        sum(follow_ups_needed) as follow_ups_needed,
        sum(follow_ups_completed) as follow_ups_completed,
        sum(follow_ups_missing) as follow_ups_missing,
        
        -- Time and cost
        avg(avg_days_to_result) as avg_days_to_result,
        sum(total_cost) as total_program_cost,
        avg(avg_cost_per_screening) as avg_cost_per_screening
        
    from screening_outcomes
    group by employer_id
),

final as (
    select
        -- Employer info
        e.employer_id,
        e.employer_name,
        e.industry,
        e.state,
        
        -- Volume metrics
        coalesce(s.total_screenings, 0) as total_screenings,
        coalesce(s.unique_members_screened, 0) as unique_members_screened,
        
        -- Result distribution
        coalesce(s.normal_results, 0) as normal_results,
        coalesce(s.abnormal_results, 0) as abnormal_results,
        coalesce(s.cancer_detections, 0) as cancer_detections,
        
        -- Result percentages
        round(safe_divide(s.normal_results, s.total_screenings) * 100, 2) as normal_rate_pct,
        round(safe_divide(s.abnormal_results, s.total_screenings) * 100, 2) as abnormal_rate_pct,
        round(safe_divide(s.cancer_detections, s.total_screenings) * 100, 2) as cancer_detection_rate_pct,
        
        -- Cancer detection rate (industry standard metric)
        round(safe_divide(s.cancer_detections, s.total_screenings) * 1000, 2) as cancers_detected_per_1000_screenings,
        
        -- Follow-up performance
        coalesce(s.follow_ups_needed, 0) as follow_ups_needed,
        coalesce(s.follow_ups_completed, 0) as follow_ups_completed,
        coalesce(s.follow_ups_missing, 0) as follow_ups_missing,
        round(safe_divide(s.follow_ups_completed, s.follow_ups_needed) * 100, 2) as follow_up_completion_rate_pct,
        
        -- Care gaps identified
        coalesce(s.abnormal_results, 0) + coalesce(s.cancer_detections, 0) as total_care_gaps_identified,
        coalesce(s.follow_ups_completed, 0) as care_gaps_addressed,
        coalesce(s.follow_ups_missing, 0) as care_gaps_remaining,
        
        -- Operational metrics
        round(s.avg_days_to_result, 1) as avg_days_to_result,
        coalesce(s.total_program_cost, 0) as total_program_cost,
        round(s.avg_cost_per_screening, 2) as avg_cost_per_screening,
        
        -- Cost per cancer detected
        round(safe_divide(s.total_program_cost, nullif(s.cancer_detections, 0)), 0) as cost_per_cancer_detected,
        
        -- Quality score (composite 0-100)
        round(
            (coalesce(safe_divide(s.follow_ups_completed, s.follow_ups_needed), 0) * 50) +     -- 50% weight on follow-up completion
            (case when s.avg_days_to_result <= 14 then 25 else 0 end) +                        -- 25 points if ≤14 days
            (case when safe_divide(s.cancer_detections, s.total_screenings) * 1000 >= 4 then 25 else 0 end)  -- 25 points if ≥4 per 1000
        , 0) as outcomes_quality_score,
        
        -- Metadata
        current_timestamp() as calculated_at
        
    from employers e
    left join employer_summary s on e.employer_id = s.employer_id
)

select * from final