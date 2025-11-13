with source as (
    select * from {{ source('raw', 'raw_app_events') }}
),

cleaned as (
    select
        -- Primary key
        event_id,
        
        -- Foreign keys
        member_id,
        
        -- Event attributes
        event_type,
        event_timestamp,
        session_id,
        device_type,
        
        -- Extracted date for partitioning/grouping
        DATE(event_timestamp) as event_date,
        
        -- Metadata
        CURRENT_TIMESTAMP() as loaded_at
        
    from source
)

select * from cleaned