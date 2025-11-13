with source as (
    select * from {{ source('raw', 'raw_providers') }}
),

cleaned as (
    select
        -- Primary key
        provider_id,
        
        -- Provider attributes
        provider_name,
        specialty,
        state,
        npi_number,
        
        -- Metadata
        CURRENT_TIMESTAMP() as loaded_at
        
    from source
)

select * from cleaned