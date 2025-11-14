{{
    config(
        materialized='incremental',
        unique_key='screening_key'
    )
}}

with screenings as (
    select * from {{ ref('stg_screenings') }}
    {% if is_incremental() %}
    -- Hybrid incremental strategy to handle late-arriving data:
    -- 1. Capture new records by loaded_at (primary mechanism)
    -- 2. Recapture screenings from last 7 days to catch late arrivals
    --    (e.g., a screening dated Jan 5 arriving after Jan 10 screening)
    -- This ensures we don't miss records while avoiding full table scans
    where loaded_at > (select max(loaded_at) from {{ this }})
       or screening_date >= date_sub(
            (select max(screening_date) from {{ this }}),
            interval 7 day
          )
{% endif %}
),

final as (
    select
        -- Primary key
        {{ dbt_utils.generate_surrogate_key(['screening_id']) }} as screening_key,
        
        -- Natural key
        screening_id,
        
        -- Foreign keys (surrogate keys generated from natural keys)
        {{ dbt_utils.generate_surrogate_key(['member_id']) }} as member_key,
        {{ dbt_utils.generate_surrogate_key(['employer_id']) }} as employer_key,
        {{ dbt_utils.generate_surrogate_key(['provider_id']) }} as provider_key,
        
        -- Degenerate dimensions (natural keys for reference)
        member_id,
        employer_id,
        provider_id,
        
        -- Date keys
        screening_date,
        result_date,
        
        -- Screening attributes
        screening_type,
        result,
        follow_up_needed,
        follow_up_completed,
        
        -- Metrics
        cost,
        days_to_result,
        
        -- Calculated flags
        case when result = 'Cancer Detected' then 1 else 0 end as cancer_detected_flag,
        case when result = 'Abnormal - Benign' then 1 else 0 end as abnormal_flag,
        case when result = 'Normal' then 1 else 0 end as normal_flag,
        case 
            when follow_up_needed and follow_up_completed then 1 
            else 0 
        end as follow_up_completed_flag,
        case 
            when follow_up_needed and not follow_up_completed then 1 
            else 0 
        end as follow_up_missing_flag,
        
        -- Metadata
        loaded_at
        
    from screenings
)

select * from final