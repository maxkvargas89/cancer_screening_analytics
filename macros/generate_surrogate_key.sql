{% macro generate_surrogate_key(cols) -%}
  {{ return(dbt_utils.generate_surrogate_key(cols)) }}
{%- endmacro %}