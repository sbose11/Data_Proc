
{{
  config( tags= ["schema_drift"])
}}

with 

base as 
(
   select  distinct rd.dt as story_dt, 
           json_keys(unnest( rd.raw_payload->> '$.hits[*]'))  as hits
   from {{source("hn_trends_brnz", "raw_data")}} rd
   where rd.type = 'story'
   and rd.dt between '{{ var("start_date") }}' and '{{ var("end_date") }}'
),
unq_key_list as 
(select distinct story_dt, unnest(hits) as actual_kn
 from base
),
final as 
(select * 
from hn_proj_silver.expected_story_keys esk left join unq_key_list ukl on (ukl.actual_kn = lower(esk.key_name) ) 
where esk.is_required = true
) 
select * 
from final where final.actual_kn is null