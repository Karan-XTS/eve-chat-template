{{ config(materialized='table', alias='user') }}

with cleaned_users as (
    select
        u.user_id,
        ifnull(cast(u.puser_id as int64), 0) as parent_user_id,
        trim(u.user_employee_id) as user_employee_id,
        trim(initcap(regexp_replace(u.user_firstname, r'[^A-Za-z0-9]+', ' '))) as user_firstname,
        trim(initcap(regexp_replace(u.user_middlename, r'[^A-Za-z0-9]+', ' '))) as user_middlename,
        trim(initcap(regexp_replace(u.user_lastname, r'[^A-Za-z0-9]+', ' '))) as user_lastname,
        trim(initcap(regexp_replace(regexp_replace(u.user_firstname, r'[^A-Za-z0-9]+', ' '), r'\s+', ' '))) as full_name_firstname,
        trim(initcap(regexp_replace(regexp_replace(u.user_lastname, r'[^A-Za-z0-9]+', ' '), r'\s+', ' '))) as full_name_lastname,
        trim(lower(u.user_email)) as normalized_user_email,
        trim(u.user_countrycode) as user_countrycode,
        regexp_replace(trim(u.user_mobile), r'[^0-9]', '') as user_mobile_digits,
        u.department_id,
        u.prole_id,
        u.iswfh as is_work_from_home,
        u.iscustomaccess as is_custom_access,
        u.isataqualityauditor as is_qa_auditor,
        u.prdsubgroup_id,
        u.p_ata_id,
        u.isactive as is_active,
        u.extension_id,
        u.created_dt,
        u.edited_dt,
        u.edited_by
    from {{ source('bronze_layer', 'mst_tblusers') }} as u
)

select
    users.user_id as USER_ID,
    users.parent_user_id as PARENT_USER_ID,
    users.user_employee_id as USER_EMPLOYEE_ID,
    users.user_firstname as USER_FIRSTNAME,
    users.user_middlename as USER_MIDDLENAME,
    users.user_lastname as USER_LASTNAME,
    users.full_name_firstname || coalesce(' ' || users.full_name_lastname, '') as USER_FULL_NAME,
    case
        when regexp_contains(users.normalized_user_email, r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
            then users.normalized_user_email
        else 'Not Available'
    end as USER_EMAIL,
    users.department_id as DEPARTMENT_ID,
    trim(departments.department_desc) as DEPARTMENT_DESC,
    users.prole_id as PROLE_ID,
    trim(process_roles.prole_desc) as PROCESS_ROLE_DESC,
    case
        when nullif(users.user_countrycode, '') is null then null
        when users.user_countrycode in ('0', '00') then '00'
        when regexp_contains(users.user_countrycode, r'^\+?[0-9]{1,3}$')
            then regexp_replace(users.user_countrycode, r'^\+', '')
        else '00'
    end as USER_COUNTRYCODE,
    case
        when nullif(users.user_mobile_digits, '') is null then null
        when regexp_contains(users.user_mobile_digits, r'^[1-9][0-9]{9,14}$') then users.user_mobile_digits
        else '0000000000'
    end as USER_MOBILE,
    users.is_work_from_home as IS_WORK_FROM_HOME,
    users.is_custom_access as IS_CUSTOM_ACCESS,
    users.is_qa_auditor as IS_QA_AUDITOR,
    users.prdsubgroup_id as PRDSUBGROUP_ID,
    users.p_ata_id as P_ATA_ID,
    users.is_active as IS_ACTIVE,
    case
        when users.extension_id is null or users.extension_id <= 0 then '0'
        else cast(users.extension_id as string)
    end as EXTENSION_ID,
    users.created_dt as CREATED_DT,
    users.edited_dt as EDITED_DT,
    users.edited_by as EDITED_BY,
    current_timestamp() as SOURCE_LOADED_AT
from cleaned_users as users
join {{ source('bronze_layer_odm', 'mst_tbldepartment') }} as departments
    on users.department_id = departments.department_id
join {{ source('bronze_layer_odm', 'mst_tbluser_processroles') }} as process_roles
    on users.prole_id = process_roles.prole_id
