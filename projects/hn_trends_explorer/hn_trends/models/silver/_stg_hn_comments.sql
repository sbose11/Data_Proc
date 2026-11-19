{{config (
   materialized = 'incremental',
   unique_key = 'comment_dt',
   incremental_strategy='delete+insert',
)
}}

with recursive  stories as
                   (select rp.value as story_dtls,
                           rp.value ->> '$.story_id' as story_id, 
                           rp.value->>'$.id' as id,
                           rd.dt 
                    from {{ source("hn_trends_brnz", "raw_data")}}rd,
                         json_each(raw_payload) rp
                   where rd.type = 'comment'
                   {% if is_incremental() %}
                    and rd.dt between '{{ var("start_date") }}' and '{{ var("end_date") }}'
                   {% endif %} 
                   ), 
                   comment_nodes as ( 
                    --anchor
                   select dt, s.story_id, s.id, sd.value as node, 1 as depth 
                   from stories as  s, 
                        json_each(story_dtls, '$.children') as sd 
                   union all
                   --recursive step
                   select dt, cn.story_id, cn.id, ch.value, cn.depth + 1  
                   from comment_nodes cn, 
                        json_each(cn.node, '$.children') as ch
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
                          depth, 
                          current_timestamp as date_loaded
                   from comment_nodes
                   ;