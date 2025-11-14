select *
from {{ ref('fct_screenings') }}
where result_date < screening_date