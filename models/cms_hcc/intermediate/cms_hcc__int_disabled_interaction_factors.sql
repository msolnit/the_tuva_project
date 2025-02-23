{{ config(
     enabled = var('cms_hcc_enabled',var('tuva_marts_enabled',True))
   )
}}
/*
The hcc_model_version var has been set here so it gets compiled.
*/

{% set model_version_compiled = var('cms_hcc_model_version') -%}

with demographics as (

    select
          patient_id
        , enrollment_status
        , institutional_status
        , model_version
        , payment_year
    from {{ ref('cms_hcc__int_demographic_factors') }}

)

, hcc_hierarchy as (

    select
          patient_id
        , hcc_code
    from {{ ref('cms_hcc__int_hcc_hierarchy') }}

)

, seed_interaction_factors as (

    select
          model_version
        , enrollment_status
        , institutional_status
        , short_name
        , description
        , hcc_code
        , coefficient
    from {{ ref('cms_hcc__disabled_interaction_factors') }}
    where model_version = '{{ model_version_compiled }}'

)

, demographics_with_hccs as (

    select
          demographics.patient_id
        , demographics.enrollment_status
        , demographics.institutional_status
        , demographics.model_version
        , demographics.payment_year
        , hcc_hierarchy.hcc_code
    from demographics
         inner join hcc_hierarchy
         on demographics.patient_id = hcc_hierarchy.patient_id

)

, interactions as (

    select
          demographics_with_hccs.patient_id
        , demographics_with_hccs.model_version
        , demographics_with_hccs.payment_year
        , seed_interaction_factors.description
        , seed_interaction_factors.coefficient
    from demographics_with_hccs
         inner join seed_interaction_factors
         on demographics_with_hccs.enrollment_status = seed_interaction_factors.enrollment_status
         and demographics_with_hccs.institutional_status = seed_interaction_factors.institutional_status
         and demographics_with_hccs.hcc_code = seed_interaction_factors.hcc_code

)

, add_data_types as (

select
      cast(patient_id as {{ dbt.type_string() }}) as patient_id
    , cast(description as {{ dbt.type_string() }}) as description
    , round(cast(coefficient as {{ dbt.type_numeric() }}),3) as coefficient
    , cast(model_version as {{ dbt.type_string() }}) as model_version
    , cast(payment_year as integer) as payment_year
    , cast('{{ dbt_utils.pretty_time(format="%Y-%m-%d %H:%M:%S") }}' as {{ dbt.type_timestamp() }}) as date_calculated
from interactions

)

select
      patient_id
    , description
    , coefficient
    , model_version
    , payment_year
    , date_calculated
from add_data_types