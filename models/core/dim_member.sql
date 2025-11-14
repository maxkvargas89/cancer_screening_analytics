with members as (
    select * from {{ ref('stg_members') }}
),

final as (
    select
        -- Primary key
        {{ dbt_utils.generate_surrogate_key(['member_id']) }} as member_key,
        
        -- Natural key
        member_id,
        
        -- Foreign keys
        employer_id,
        
        -- Attributes
        first_name,
        last_name,
        date_of_birth,
        age,
        gender,
        state,
        zip_code,
        email,
        phone,
        high_risk_flag,
        
        -- Calculated attributes
        case 
            when age < 40 then 'Under 40'
            when age between 40 and 49 then '40-49'
            when age between 50 and 64 then '50-64'
            when age >= 65 then '65+'
        end as age_group,
        
        -- Metadata
        created_at,
        loaded_at
        
    from members
)

select * from final