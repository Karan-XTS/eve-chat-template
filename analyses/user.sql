with user_base as (
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
    from `BRONZE_LAYER.MST_TBLUSERS` as u
),

enriched_users as (
    select
        u.*,
        trim(d.department_desc) as department_desc,
        trim(r.prole_desc) as process_role_desc
    from user_base as u
    join `BRONZE_LAYER_ODM.MST_TBLDEPARTMENT` as d
        on u.department_id = d.department_id
    join `BRONZE_LAYER_ODM.MST_TBLUSER_PROCESSROLES` as r
        on u.prole_id = r.prole_id
)

select
    user_id as USER_ID,
    parent_user_id as PARENT_USER_ID,
    user_employee_id as USER_EMPLOYEE_ID,
    user_firstname as USER_FIRSTNAME,
    user_middlename as USER_MIDDLENAME,
    user_lastname as USER_LASTNAME,
    full_name_firstname || coalesce(' ' || full_name_lastname, '') as USER_FULL_NAME,
    case
        when regexp_contains(normalized_user_email, r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
            then normalized_user_email
        else 'Not Available'
    end as USER_EMAIL,
    department_id as DEPARTMENT_ID,
    department_desc as DEPARTMENT_DESC,
    prole_id as PROLE_ID,
    process_role_desc as PROCESS_ROLE_DESC,
    case
        when nullif(user_countrycode, '') is null then null
        when user_countrycode in ('0', '00') then '00'
        when regexp_contains(user_countrycode, r'^\+?[0-9]{1,3}$')
            then regexp_replace(user_countrycode, r'^\+', '')
        else '00'
    end as USER_COUNTRYCODE,
    case
        when nullif(user_mobile_digits, '') is null then null
        when regexp_contains(user_mobile_digits, r'^[1-9][0-9]{9,14}$') then user_mobile_digits
        else '0000000000'
    end as USER_MOBILE,
    is_work_from_home as IS_WORK_FROM_HOME,
    is_custom_access as IS_CUSTOM_ACCESS,
    is_qa_auditor as IS_QA_AUDITOR,
    prdsubgroup_id as PRDSUBGROUP_ID,
    p_ata_id as P_ATA_ID,
    is_active as IS_ACTIVE,
    case
        when extension_id is null or extension_id <= 0 then '0'
        else cast(extension_id as string)
    end as EXTENSION_ID,
    created_dt as CREATED_DT,
    edited_dt as EDITED_DT,
    edited_by as EDITED_BY,
    current_timestamp() as SOURCE_LOADED_AT
from enriched_users
