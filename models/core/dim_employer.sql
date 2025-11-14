with employers as (
    select * from {{ ref('stg_employers') }}
),

final as (
    select
        -- Primary key
        {{ dbt_utils.generate_surrogate_key(['employer_id']) }} as employer_key,
        
        -- Natural key
        employer_id,
        
        -- Attributes
        employer_name,
        industry,
        employee_count,
        state,
        contract_start_date,
        
        -- Metadata
        loaded_at
        
    from employers
)

select * from final