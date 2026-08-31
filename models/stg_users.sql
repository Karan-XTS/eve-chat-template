{{ config(materialized="view", alias="user") }}

with
    user_base as (
        select
            u.user_id,
            ifnull(cast(u.puser_id as int64), 0) as parent_user_id,
            trim(u.user_employee_id) as user_employee_id,
            trim(
                initcap(regexp_replace(u.user_firstname, r'[^A-Za-z0-9]+', ' '))
            ) as user_firstname,
            trim(
                initcap(regexp_replace(u.user_middlename, r'[^A-Za-z0-9]+', ' '))
            ) as user_middlename,
            trim(
                initcap(regexp_replace(u.user_lastname, r'[^A-Za-z0-9]+', ' '))
            ) as user_lastname,
            trim(
                initcap(
                    regexp_replace(
                        regexp_replace(u.user_firstname, r'[^A-Za-z0-9]+', ' '),
                        r'\s+',
                        ' '
                    )
                )
            ) as full_name_firstname,
            trim(
                initcap(
                    regexp_replace(
                        regexp_replace(u.user_lastname, r'[^A-Za-z0-9]+', ' '),
                        r'\s+',
                        ' '
                    )
                )
            ) as full_name_lastname,
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
        from {{ source("BRONZE_LEVEL", "mst_tblusers") }} as u
    ),

    enriched_users as (
        select
            u.*,
            trim(d.department_desc) as department_desc,
            trim(r.prole_desc) as process_role_desc
        from user_base as u
        join
            {{ source("BRONZE_LEVEL", "mst_tbldepartment") }} as d
            on u.department_id = d.department_id
        join
            {{ source("BRONZE_LEVEL_ODM", "mst_tbluser_processroles") }} as r
            on u.prole_id = r.prole_id
    )

select
    user_id as user_id,
    parent_user_id as parent_user_id,
    user_employee_id as user_employee_id,
    user_firstname as user_firstname,
    user_middlename as user_middlename,
    user_lastname as user_lastname,
    full_name_firstname || coalesce(' ' || full_name_lastname, '') as user_full_name,
    case
        when
            regexp_contains(
                normalized_user_email,
                r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
            )
        then normalized_user_email
        else 'Not Available'
    end as user_email,
    department_id as department_id,
    department_desc as department_desc,
    prole_id as prole_id,
    process_role_desc as process_role_desc,
    case
        when nullif(user_countrycode, '') is null
        then null
        when user_countrycode in ('0', '00')
        then '00'
        when regexp_contains(user_countrycode, r'^\+?[0-9]{1,3}$')
        then regexp_replace(user_countrycode, r'^\+', '')
        else '00'
    end as user_countrycode,
    case
        when nullif(user_mobile_digits, '') is null
        then null
        when regexp_contains(user_mobile_digits, r'^[1-9][0-9]{9,14}$')
        then user_mobile_digits
        else '0000000000'
    end as user_mobile,
    is_work_from_home as is_work_from_home,
    is_custom_access as is_custom_access,
    is_qa_auditor as is_qa_auditor,
    prdsubgroup_id as prdsubgroup_id,
    p_ata_id as p_ata_id,
    is_active as is_active,
    case
        when extension_id is null or extension_id <= 0
        then '0'
        else cast(extension_id as string)
    end as extension_id,
    created_dt as created_dt,
    edited_dt as edited_dt,
    edited_by as edited_by,
    current_timestamp() as source_loaded_at
from enriched_users
