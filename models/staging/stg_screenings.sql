with source as (
    select * from {{ source('raw', 'raw_screenings') }}
),

cleaned as (
    select
        -- Primary key
        screening_id,
        
        -- Foreign keys
        member_id,
        employer_id,
        provider_id,
        
        -- Screening attributes
        screening_type,
        screening_date,
        result,
        result_date,
        
        -- Follow-up tracking
        follow_up_needed,
        follow_up_completed,
        
        -- Financial
        cost,
        
        -- Calculated fields
        DATE_DIFF(result_date, screening_date, DAY) as days_to_result,
        
        -- Metadata
        CURRENT_TIMESTAMP() as loaded_at
        
    from source
)

select * from cleaned