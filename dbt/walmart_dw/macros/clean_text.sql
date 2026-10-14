{# Strip leading/trailing whitespace (incl. tabs) and turn empty strings into null #}
{% macro clean_text(column) -%}
    nullif(regexp_replace({{ column }}, '^\s+|\s+$', '', 'g'), '')
{%- endmacro %}

{# Parse the boolean spellings found in the raw file (TRUE/true/Yes/Y/1 ...) #}
{% macro clean_bool(column) -%}
    case
        when lower({{ clean_text(column) }}) in ('true', 't', 'yes', 'y', '1')  then true
        when lower({{ clean_text(column) }}) in ('false', 'f', 'no', 'n', '0') then false
    end
{%- endmacro %}
