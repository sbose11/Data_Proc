{{
  config( tags= ["schema_drift"])
}}

with base as 
(
    select distinct rd.dt, json_keys(unnest(cast(json_extract(rd.raw_payload, '$[*]') as varchar[]))) as val
    from {{source("hn_trends_brnz", "raw_data")}} rd
    where rd.type = 'comment'
    and rd.dt between '{{ var("start_date") }}' and '{{ var("end_date") }}'
),   

final_set_of_keys as
(select distinct dt, unnest(val) file_keys
from base
) 
select *
from (
select dt, e.key_name, fsk.file_keys as  actual_kn
from {{ref('expected_comment_keys')}} e
left join final_set_of_keys fsk on (fsk.file_keys = lower(e.key_name))
where is_required = true 
) 
where actual_kn is null 