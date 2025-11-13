with source as (
    select * from {{ source('raw', 'raw_enrollments') }}
),

cleaned as (
    select
        -- Primary key
        enrollment_id,
        
        -- Foreign keys
        member_id,
        employer_id,
        
        -- Enrollment attributes
        enrollment_date,
        enrollment_channel,
        status,
        consent_given,
        
        -- Metadata
        CURRENT_TIMESTAMP() as loaded_at
        
    from source
)

select * from cleaned