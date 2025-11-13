{{ config(schema='staging', materialized='view') }}

select
  member_id,
  lower(program) as program,
  lower(enrollment_status) as enrollment_status,
  date(enrollment_date) as enrollment_date,
  date(disenrollment_date) as disenrollment_date
from {{ source('raw','raw_enrollments') }}