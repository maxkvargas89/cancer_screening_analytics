{{
    config(
        materialized='table'
    )
}}

with feature_data as (
    select * from {{ ref('prep_followup_analysis') }}
),

-- Overall completion rate
overall_stats as (
    select
        'Overall' as segment_type,
        'All Records' as segment_value,
        COUNT(*) as total_records,
        SUM(outcome_binary) as completed,
        ROUND(AVG(outcome_binary) * 100, 1) as completion_rate_pct
    from feature_data
),

-- By age group
age_stats as (
    select
        'Age Group' as segment_type,
        age_group as segment_value,
        COUNT(*) as total_records,
        SUM(outcome_binary) as completed,
        ROUND(AVG(outcome_binary) * 100, 1) as completion_rate_pct
    from feature_data
    group by age_group
),

-- By gender
gender_stats as (
    select
        'Gender' as segment_type,
        gender as segment_value,
        COUNT(*) as total_records,
        SUM(outcome_binary) as completed,
        ROUND(AVG(outcome_binary) * 100, 1) as completion_rate_pct
    from feature_data
    group by gender
),

-- By screening type
screening_type_stats as (
    select
        'Screening Type' as segment_type,
        screening_type as segment_value,
        COUNT(*) as total_records,
        SUM(outcome_binary) as completed,
        ROUND(AVG(outcome_binary) * 100, 1) as completion_rate_pct
    from feature_data
    group by screening_type
),

-- By day of week
day_stats as (
    select
        'Day of Week' as segment_type,
        day_of_week_result_delivered as segment_value,
        COUNT(*) as total_records,
        SUM(outcome_binary) as completed,
        ROUND(AVG(outcome_binary) * 100, 1) as completion_rate_pct
    from feature_data
    group by day_of_week_result_delivered
),

-- By days to result (binned)
days_to_result_stats as (
    select
        'Days to Result' as segment_type,
        CASE 
            WHEN days_to_result <= 7 THEN '≤7 days'
            WHEN days_to_result <= 14 THEN '8-14 days'
            WHEN days_to_result <= 21 THEN '15-21 days'
            ELSE '>21 days'
        END as segment_value,
        COUNT(*) as total_records,
        SUM(outcome_binary) as completed,
        ROUND(AVG(outcome_binary) * 100, 1) as completion_rate_pct
    from feature_data
    group by segment_value
),

combined as (
    select * from overall_stats
    union all
    select * from age_stats
    union all
    select * from gender_stats
    union all
    select * from screening_type_stats
    union all
    select * from day_stats
    union all
    select * from days_to_result_stats
)

select 
    segment_type,
    segment_value,
    total_records,
    completed,
    completion_rate_pct,
    CURRENT_TIMESTAMP() as calculated_at
from combined
order by segment_type, completion_rate_pct desc