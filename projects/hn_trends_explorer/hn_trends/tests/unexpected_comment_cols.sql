{{
   config (
    tags = ["schema drift"], 
    severity = "warn"
   )
}}
with k as 
(
    /* even though the comments are deeply nested trees, the keys will be the same at every level so just getting them from the top lvl*/
    select distinct rd.dt, unnest(json_keys(py.value)) as key_name
    from {{source("hn_trends_brnz", "raw_data")}} rd, 
    json_each(rd.raw_payload) py
    where rd.type = 'comment'
    and  rd.dt between '{{ var("start_date") }}' and '{{ var("end_date") }}'
)
--gets hold of key names that are not in predefined csv
select * 
from k 
where k.key_name not in (select lower(key_name) from {{ref('expected_comment_keys')}})
                  
