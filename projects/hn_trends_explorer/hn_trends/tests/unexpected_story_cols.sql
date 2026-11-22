
{{config ( tags = ["schema_drift"] ,
           severity = 'warn')
}}

with 

base as 
(
   select  distinct rd.dt as story_dt, 
           json_keys(unnest( rd.raw_payload->> '$.hits[*]'))  as key_names
   from {{source("hn_trends_brnz", "raw_data")}} rd
   where rd.type = 'story'
   and rd.dt between '{{ var("start_date") }}' and '{{ var("end_date") }}'
),


k_list as
(
   select distinct story_dt, unnest(key_names)keys
   from base 
)
select * 
from k_list
where keys not in (select lower(key_name) from {{ ref('expected_story_keys') }})
