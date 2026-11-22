{{config (
   materialized = 'incremental',
   unique_key = 'comment_dt',
   incremental_strategy='delete+insert',
)
}}
with recursive base as 
(select rd.dt,
       unnest(cast( json_extract(rd.raw_payload, '$[*]')  as varchar[]))  as r_pay_ld, 
       r_pay_ld ->> '$.story_id' as story_id, 
       r_pay_ld ->> '$.id' as id
from  {{ source("hn_trends_brnz", "raw_data")}} rd
where rd.type = 'comment'
{% if is_incremental() %}
     and rd.dt between '{{ var("start_date") }}' and '{{ var("end_date") }}'
{% endif %} 
), 
comment_nodes as ( 
--anchor
 select dt, b.story_id, b.id, unnest(cast(b.r_pay_ld ->> '$.children[*]'  as varchar[])) as node, 1 as ch_depth
 from base b 
 union all 
 select cn.dt, cn.story_id, cn.id, unnest(cast(cn.node ->> '$.children[*]' as varchar[])), cn.ch_depth + 1 
 from comment_nodes cn
)
select dt as comment_dt,
      story_id :: bigint as story_id,
      node->> '$.author' as comment_author,
      (node ->> '$.id')::bigint as comment_id , 
      (node ->> '$.created_at') :: timestamp as comment_created_at_ts , 
       --node ->> '$.created_at_i' as comment_created_unix_ts, 
      node ->> '$.text' as comment_text, 
      node ->> '$.url' as comment_url, 
      (node ->> '$.parent_id'):: bigint as comment_parent_id , 
      (node ->> '$.story_id'):: bigint as comment_story_id , 
      ch_depth as depth, 
      current_timestamp as date_loaded
from comment_nodes
