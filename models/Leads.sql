{{ config(materialized='table', alias='silver_lead') }}

with location_country as (
    select
        location_id,
        trim(initcap(location_desc)) as location_desc
    from {{ source('bronze_layer', 'mst_tbllocationelements') }}
    where location_type = 'Country'
),

location_state as (
    select
        location_id,
        trim(initcap(location_desc)) as location_desc
    from {{ source('bronze_layer', 'mst_tbllocationelements') }}
    where location_type = 'State'
),

location_city as (
    select
        location_id,
        trim(initcap(location_desc)) as location_desc
    from {{ source('bronze_layer', 'mst_tbllocationelements') }}
    where location_type = 'City'
)

select
    l.lead_id,
    farm_fingerprint(concat(upper(trim(regexp_replace(regexp_replace(l.company_name, r'[^\p{L}\p{N}\s]', ' '), r'\s+', ' '))), '|', case when regexp_contains(trim(lower(l.mail_domain)), r'^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') then upper(trim(lower(l.mail_domain))) else 'Not Available' end)) as company_id,
    trim(initcap(regexp_replace(regexp_replace(l.first_name, r'[^A-Za-z0-9]+', ' '), r'\s+', ' '))) as first_name,
    trim(initcap(regexp_replace(regexp_replace(l.last_name, r'[^A-Za-z0-9]+', ' '), r'\s+', ' '))) as last_name,
    l.salutation_id,
    s.salutation_desc as salutation_desc,
    trim(initcap(regexp_replace(regexp_replace(l.job_title, r'[^A-Za-z]+', ' '), r'\s+', ' '))) as job_title,
    l.job_level_id,
    jl.job_level_desc as job_level_desc,
    l.jobfunction_id,
    jf.jobfunction_desc as jobfunction_desc,
    case when l.tenurity is null then 'NA' when regexp_contains(upper(l.tenurity), 'HTTPS?://') then null else concat(coalesce(nullif(regexp_replace(regexp_extract(upper(l.tenurity), r'[0-9]{1,3}[ ]*(?:YEAR|YEARS|YR|Y)'), '[^0-9]', ''), ''), '0'), ' Years ', coalesce(nullif(regexp_replace(regexp_extract(upper(l.tenurity), r'[0-9]{1,2}[ ]*(?:MONTH|MONTHS|MON|MONS|MOS|M)'), '[^0-9]', ''), ''), '0'), ' Months') end as tenurity,
    case when regexp_contains(trim(lower(l.email_id)), r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') then trim(lower(l.email_id)) else 'Not Available' end as email_id,
    l.md5_email_id,
    case when regexp_contains(trim(lower(l.mail_domain)), r'^[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') then trim(lower(l.mail_domain)) else 'Not Available' end as mail_domain,
    case when nullif(trim(l.phone_number), '') is null then '00000000' when regexp_contains(regexp_replace(regexp_replace(trim(l.phone_number), r'[^0-9]', ''), r'^0+', ''), r'^[1-9][0-9]{6,14}$') then regexp_replace(regexp_replace(trim(l.phone_number), r'[^0-9]', ''), r'^0+', '') else '0000000000' end as phone_number,
    case when nullif(trim(l.country_code), '') is null then '00' when trim(l.country_code) in ('0', '00') then '00' when regexp_contains(trim(l.country_code), r'^\+?[0-9]{1,3}$') then regexp_replace(trim(l.country_code), r'^\+', '') else '00' end as country_code,
    case when nullif(trim(l.mobile_no), '') is null then '0000000000' when regexp_contains(regexp_replace(trim(l.mobile_no), r'[^0-9]', ''), r'^[1-9][0-9]{9,14}$') then regexp_replace(trim(l.mobile_no), r'[^0-9]', '') else '0000000000' end as mobile_no,
    case when nullif(trim(l.direct_dial_extension), '') is null then '0' when regexp_contains(trim(l.direct_dial_extension), r'^[1-9][0-9]{0,5}$') then trim(l.direct_dial_extension) else '0' end as direct_dial_extension,
    trim(regexp_replace(regexp_replace(l.company_name, r'[^\p{L}\p{N}\s]', ' '), r'\s+', ' ')) as company_name,
    trim(initcap(regexp_replace(regexp_replace(l.address1, r'[^\p{L}\p{N}\s.,/#()&-]', ' '), r'\s+', ' '))) as address1,
    trim(initcap(regexp_replace(regexp_replace(l.address2, r'[^\p{L}\p{N}\s.,/#()&-]', ' '), r'\s+', ' '))) as address2,
    at_tag.address_tag_desc as address_tag_desc,
    case when nullif(trim(l.zip_code), '') is null then 'Not Available' when regexp_contains(trim(l.zip_code), r'^[A-Za-z0-9][A-Za-z0-9 -]{2,9}$') then upper(trim(l.zip_code)) else 'Not Available' end as zip_code,
    l.country_id,
    lc.location_desc as country_desc,
    l.state_id,
    ls.location_desc as state_desc,
    l.city_id,
    lci.location_desc as city_desc,
    upper(trim(l.timezone_abbr)) as timezone_abbr,
    trim(initcap(regexp_replace(l.industry, r'[^A-Za-z0-9]+', ' '))) as industry,
    l.standard_industry_id,
    si.standard_industry_desc as standard_industry_desc,
    upper(trim(l.sic_code)) as sic_code,
    upper(trim(l.naics_code)) as naics_code,
    l.employee_size_id,
    es.employee_size_desc as employee_size_desc,
    trim(l.actual_employee_size) as actual_employee_size,
    l.revenue_size_id,
    rs.revenue_size_desc as revenue_size_desc,
    l.contact_success_attempts,
    l.datareuse_asis_until_dt,
    l.ismisupload as is_mis_upload,
    l.isuserupload as is_user_upload,
    l.ispurchasedata as is_purchased_data,
    l.uploaded_dt,
    l.uploaded_by,
    u_up.user_full_name as uploaded_by_name,
    array_to_string(regexp_extract_all(l.multi_uploadedby, r'\d+'), ', ') as multi_uploaded_by,
    l.unvr_id,
    l.orderkeyid as order_key_id_direct,
    trim(lower(l.suggestedemail_id)) as suggested_email_id,
    l.isdelete as is_deleted,
    l.edited_dt,
    l.edited_by,
    u_ed.user_full_name as edited_by_name,
    current_timestamp() as source_loaded_at
from {{ source('bronze_layer', 'tblleads_masterlist') }} as l
join {{ source('bronze_layer', 'mst_tblsalutation') }} as s on l.salutation_id = s.salutation_id
join {{ source('bronze_layer', 'mst_tbljoblevel') }} as jl on l.job_level_id = jl.job_level_id
join {{ source('bronze_layer', 'mst_tbljobfunction') }} as jf on l.jobfunction_id = jf.jobfunction_id
join {{ source('bronze_layer', 'mst_tbladdresstag') }} as at_tag on l.address_tag_id = at_tag.address_tag_id
join location_country as lc on l.country_id = lc.location_id
join location_state as ls on l.state_id = ls.location_id
join location_city as lci on l.city_id = lci.location_id
join {{ source('bronze_layer', 'mst_tblstandardindustry') }} as si on l.standard_industry_id = si.standard_industry_id
join {{ source('bronze_layer', 'mst_tblemployeesize') }} as es on l.employee_size_id = es.employee_size_id
join {{ source('bronze_layer', 'mst_tblrevenuesize') }} as rs on l.revenue_size_id = rs.revenue_size_id
join {{ ref('stg_users') }} as u_up on l.uploaded_by = u_up.user_id
join {{ ref('stg_users') }} as u_ed on l.edited_by = u_ed.user_id
