select *
from {{ ref('fct_screenings') }}
where cost < 0