{{
    config(
        materialized='table'
    )
}}

with predictions as (
    select * from {{ ref('mart_followup_risk_prediction') }}
),

overall_performance as (
    select
        'Overall Model Performance' as metric_category,
        'Total Predictions' as metric_name,
        cast(count(*) as string) as metric_value
    from predictions
    
    union all
    
    select
        'Overall Model Performance',
        'Model Accuracy',
        concat(round(avg(case when cast(actual_completed as int) = predicted_completed then 1.0 else 0.0 end) * 100, 1), '%')
    from predictions
    
    union all
    
    select
        'Overall Model Performance',
        'Average Predicted Completion Probability',
        concat(round(avg(predicted_completion_probability) * 100, 1), '%')
    from predictions
),

risk_distribution as (
    select
        'Risk Distribution' as metric_category,
        outreach_priority as metric_name,
        cast(count(*) as string) as metric_value
    from predictions
    group by outreach_priority
),

high_risk_profile as (
    select
        'High Risk Profile (Tier 1)' as metric_category,
        screening_type as metric_name,
        cast(count(*) as string) as metric_value
    from predictions
    where outreach_priority = 'Tier 1 - Critical Outreach'
    group by screening_type
    
    union all
    
    select
        'High Risk Profile (Tier 1)',
        concat('Results on ', day_of_week_result_delivered),
        cast(count(*) as string)
    from predictions
    where outreach_priority = 'Tier 1 - Critical Outreach'
    group by day_of_week_result_delivered
),

model_calibration as (
    select
        'Model Calibration' as metric_category,
        risk_category as metric_name,
        concat(round(avg(actual_completed_binary) * 100, 1), '% actual completion rate')
    from predictions
    group by risk_category
),

combined as (
    select * from overall_performance
    union all
    select * from risk_distribution
    union all
    select * from high_risk_profile
    union all
    select * from model_calibration
)

select 
    metric_category,
    metric_name,
    metric_value,
    current_timestamp() as calculated_at
from combined
order by metric_category, metric_name