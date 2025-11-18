{{
    config(
        materialized='table'
    )
}}

with base_features as (
    select * from {{ ref('prep_followup_analysis') }}
),

-- Load predictions from Python model (we'll seed this)
predictions as (
    select * from {{ source('raw', 'raw_followup_predictions') }}
),

final as (
    select
        -- IDs
        b.screening_id,
        b.member_id,
        
        -- Actual outcome
        b.outcome as actual_completed,
        b.outcome_binary as actual_completed_binary,
        
        -- Model predictions
        p.predicted_completion_probability,
        p.predicted_outcome as predicted_completed,
        p.risk_category,
        
        -- Risk score (0-100 scale for business users)
        round((1 - p.predicted_completion_probability) * 100, 0) as non_completion_risk_score,
        
        -- Risk tier (for operational prioritization)
        case
            when p.predicted_completion_probability < 0.40 then 'Tier 1 - Critical Outreach'
            when p.predicted_completion_probability < 0.70 then 'Tier 2 - Standard Outreach'
            else 'Tier 3 - Monitor Only'
        end as outreach_priority,
        
        -- Feature context (for explaining predictions)
        b.age_group,
        b.gender,
        b.screening_type,
        b.days_to_result,
        b.day_of_week_result_delivered,
        b.result_date,
        
        -- Metadata
        current_timestamp() as prediction_generated_at
        
    from base_features b
    inner join predictions p on b.screening_id = p.screening_id
)

select * from final
