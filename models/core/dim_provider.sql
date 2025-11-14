with providers as (
    select * from {{ ref('stg_providers') }}
),

final as (
    select
        -- Primary key
        {{ dbt_utils.generate_surrogate_key(['provider_id']) }} as provider_key,
        
        -- Natural key
        provider_id,
        
        -- Attributes
        provider_name,
        specialty,
        state,
        npi_number,
        
        -- Metadata
        loaded_at
        
    from providers
)

select * from final