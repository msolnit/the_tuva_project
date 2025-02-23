{{ config(
     enabled = var('encounter_grouper_enabled',var('tuva_marts_enabled',True))
   )
}}

-- *************************************************
-- This dbt model assigns an encounter_start_date and
-- an encounter_end_date to each acute inpatient
-- encounter_id.
-- This returns a table with 4 fields:
--      patient_id
--      encounter_id
--      encounter_start_date
--      encounter_end_date
-- The number of rows in the table should be equal
-- to the number of acute inpatient encounters.
-- *************************************************




with add_encounter_id_to_acute_inpatient_encounters as (
select
  aip.claim_id as claim_id,
  aip.patient_id as patient_id,
  aip.start_date as start_date,
  aip.end_date as end_date,
  eid.encounter_id as encounter_id
from {{ ref('encounter_grouper__acute_inpatient_institutional_claims') }} aip
left join
{{ ref('encounter_grouper__acute_inpatient_institutional_encounter_id') }} eid
on aip.patient_id = eid.patient_id
and aip.claim_id = eid.claim_id
),


encounter_start_and_end_dates as (
select
  patient_id,
  encounter_id,
  min(start_date) as encounter_start_date,
  max(end_date) as encounter_end_date
from add_encounter_id_to_acute_inpatient_encounters
group by patient_id, encounter_id
)


select *
from encounter_start_and_end_dates
