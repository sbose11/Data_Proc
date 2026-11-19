
{{config ( tags = ["schema_drift"] ,
           severity = 'warn')
}}

with k as (
    select distinct rd.dt, unnest(json_keys(h.value)) as key_name
    from {{ source('hn_trends_brnz', 'raw_data') }} rd,
         json_each(rd.raw_payload, '$.hits') h
    where rd.type = 'story'
    and   rd.dt between '{{ var("start_date") }}' and '{{ var("end_date") }}'
)
select * 
from k
where key_name not in (select lower(key_name) from {{ ref('expected_story_keys') }})
--group by dt, key_name
