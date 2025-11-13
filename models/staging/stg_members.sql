with source as (
    select * from {{ source('raw', 'raw_members') }}
),

cleaned as (
    select
        -- Primary key
        member_id,
        
        -- Foreign keys
        employer_id,
        
        -- Member attributes
        first_name,
        last_name,
        date_of_birth,
        DATE_DIFF(CURRENT_DATE(), date_of_birth, YEAR) as age,
        gender,
        state,
        zip_code,
        
        -- Contact info
        email,
        phone,
        
        -- Risk flags
        high_risk_flag,
        
        -- Metadata
        created_at,
        current_timestamp() as loaded_at
        
    from source
)

select * from cleaned