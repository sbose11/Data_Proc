{{
  config( tags= ["schema_drift"])
}}

with k as 
(
   select distinct rd.dt, unnest(json_keys(py.value)) as key_name
    from {{ source('hn_trends_brnz', 'raw_data') }} rd,
         json_each(rd.raw_payload) py
    where rd.type = 'comment'
    and   rd.dt between '{{ var("start_date") }}' and '{{ var("end_date") }}'
)
select *
from (
select dt, e.key_name ref_kn, k.key_name actual_kn
from {{ref('expected_comment_keys')}} e
left join k on (k.key_name = lower(e.key_name))
where is_required = true 
) 
where actual_kn is null 