{{
   config (
    tags = ["schema drift"], 
    severity = "warn"
   )
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
from final_set_of_keys fsk 
where fsk.file_keys not in (select lower(key_name) 
                            from {{ref('expected_comment_keys')}}
                            )