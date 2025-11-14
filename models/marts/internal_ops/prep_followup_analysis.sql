{{
    config(
        materialized='table'
    )
}}

with screenings_needing_followup as (
    select * 
    from {{ ref('fct_screenings') }}
    where follow_up_needed = TRUE
),

members as (
    select * from {{ ref('dim_member') }}
),

feature_prep as (
    select
        -- IDs
        s.screening_id,
        s.screening_key,
        s.member_id,
        s.member_key,
        
        -- Outcome variable (dependent variable for logistic regression)
        CASE WHEN s.follow_up_completed_flag = 1 THEN TRUE ELSE FALSE END as outcome,
        CAST(s.follow_up_completed_flag AS INT64) as outcome_binary,
        
        -- Predictor 1: Age group (categorical - from dimension)
        m.age_group,
        CASE WHEN m.age_group = 'Under 40' THEN 1 ELSE 0 END as age_under_40,
        CASE WHEN m.age_group = '40-49' THEN 1 ELSE 0 END as age_40_49,
        CASE WHEN m.age_group = '50-64' THEN 1 ELSE 0 END as age_50_64,
        CASE WHEN m.age_group = '65+' THEN 1 ELSE 0 END as age_65_plus,
        
        -- Predictor 2: Gender (categorical - from dimension)
        m.gender,
        CASE WHEN m.gender = 'M' THEN 1 ELSE 0 END as gender_male,
        CASE WHEN m.gender = 'F' THEN 1 ELSE 0 END as gender_female,
        CASE WHEN m.gender = 'Other' THEN 1 ELSE 0 END as gender_other,
        
        -- Predictor 3: Screening type (categorical - from fact)
        s.screening_type,
        CASE WHEN s.screening_type = 'Mammogram' THEN 1 ELSE 0 END as screening_mammogram,
        CASE WHEN s.screening_type = 'Colonoscopy' THEN 1 ELSE 0 END as screening_colonoscopy,
        CASE WHEN s.screening_type = 'Prostate Screening' THEN 1 ELSE 0 END as screening_prostate,
        CASE WHEN s.screening_type = 'Cervical Screening' THEN 1 ELSE 0 END as screening_cervical,
        CASE WHEN s.screening_type NOT IN ('Mammogram', 'Colonoscopy', 'Prostate Screening', 'Cervical Screening') 
             THEN 1 ELSE 0 END as screening_other,
        
        -- Predictor 4: Days to result (continuous - from fact)
        s.days_to_result,
        
        -- Predictor 5: Day of week result delivered (categorical - calculated from date)
        FORMAT_DATE('%A', s.result_date) as day_of_week_result_delivered,
        CASE WHEN FORMAT_DATE('%A', s.result_date) = 'Monday' THEN 1 ELSE 0 END as day_monday,
        CASE WHEN FORMAT_DATE('%A', s.result_date) = 'Tuesday' THEN 1 ELSE 0 END as day_tuesday,
        CASE WHEN FORMAT_DATE('%A', s.result_date) = 'Wednesday' THEN 1 ELSE 0 END as day_wednesday,
        CASE WHEN FORMAT_DATE('%A', s.result_date) = 'Thursday' THEN 1 ELSE 0 END as day_thursday,
        CASE WHEN FORMAT_DATE('%A', s.result_date) = 'Friday' THEN 1 ELSE 0 END as day_friday,
        CASE WHEN FORMAT_DATE('%A', s.result_date) = 'Saturday' THEN 1 ELSE 0 END as day_saturday,
        CASE WHEN FORMAT_DATE('%A', s.result_date) = 'Sunday' THEN 1 ELSE 0 END as day_sunday,
        
        -- Additional context fields
        s.screening_date,
        s.result_date,
        s.result,
        s.cost,
        m.high_risk_flag,
        
        -- Metadata
        CURRENT_TIMESTAMP() as analysis_timestamp
        
    from screenings_needing_followup s
    inner join members m on s.member_key = m.member_key
)

select * from feature_prep