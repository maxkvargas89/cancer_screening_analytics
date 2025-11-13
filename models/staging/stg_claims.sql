with source as (
    select * from {{ source('raw', 'raw_claims') }}
),

cleaned as (
    select
        -- Primary key
        claim_id,
        
        -- Foreign keys
        member_id,
        provider_id,
        
        -- Claim dates
        claim_date,
        service_date,
        
        -- Procedure info
        procedure_code,
        procedure_description,
        diagnosis_code,
        
        -- Financial
        claim_amount,
        paid_amount,
        claim_status,
        
        -- Calculated fields
        claim_amount - paid_amount as unpaid_amount,
        
        -- Metadata
        CURRENT_TIMESTAMP() as loaded_at
        
    from source
)

select * from cleaned