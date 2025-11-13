{{ config(schema='staging', materialized='view') }}

select
  event_id,
  member_id,
  lower(event_name) as event_name,
  timestamp(event_ts) as event_ts,
  lower(device) as device,
  app_version
from {{ source('raw','raw_app_events') }}