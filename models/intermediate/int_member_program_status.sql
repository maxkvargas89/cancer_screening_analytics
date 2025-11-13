{{ config(schema='intermediate', materialized='view') }}

with ranked as (
  select
    member_id,
    program,
    enrollment_status,
    enrollment_date,
    disenrollment_date,
    row_number() over (
      partition by member_id, program
      order by enrollment_date desc
    ) as rn
  from {{ ref('stg_enrollments') }}
  where program = 'cancer_screening'
)
select * from ranked where rn = 1