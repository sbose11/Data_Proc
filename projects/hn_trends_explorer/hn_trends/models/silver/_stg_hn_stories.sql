{{config (
   materialized = 'incremental',
   unique_key = 'story_dt',
   incremental_strategy='delete+insert',
)
}}

--pull the stories for the given date range 
--(controlled by delta days as used in the  ?) 
select rd.dt as story_dt, 
       (h.value ->> '$.story_id' ) :: bigint as story_id,
       h.value ->> '$.author' as author, 
       h.value ->> '$.title' as title, 
       h.value ->> '$.url' as url, 
       (h.value ->> '$.points'):: int as points , 
       (h.value ->> '$.num_comments') :: int as num_comments,       
       (h.value ->> '$.created_at') ::timestamp as story_created_at_ts, 
       --h.value ->> '$.created_at_i' as  story_created_at_unix_ts,       
       (h.value ->> '$.updated_at') ::timestamp as updated_at, 
       (h.value ->> '$._tags') :: varchar[] as tags, 
       list_contains(tags, 'front_page') as front_page, 
       list_contains(tags, 'ask_hn') as ask_hn, 
       list_contains(tags, 'show_hn') as show_hn, 
       (h.value ->> '$.children') :: varchar[] as children,
       current_timestamp as date_loaded
from {{source("hn_trends_brnz", "raw_data")}} rd, 
     json_each(rd.raw_payload, '$.hits') as h 
where rd.type = 'story'
{% if is_incremental() %}
and rd.dt between '{{ var("start_date") }}' and '{{ var("end_date") }}'
{% endif %}
;