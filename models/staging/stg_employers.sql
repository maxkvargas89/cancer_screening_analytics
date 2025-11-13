with source as (
    select * from {{ source('raw', 'raw_employers') }}
),

cleaned as (
    select
        -- Primary key
        employer_id,
        
        -- Employer attributes
        employer_name,
        industry,
        employee_count,
        state,
        
        -- Contract info
        contract_start_date,
        
        -- Metadata
        CURRENT_TIMESTAMP() as loaded_at
        
    from source
)

select * from cleaned