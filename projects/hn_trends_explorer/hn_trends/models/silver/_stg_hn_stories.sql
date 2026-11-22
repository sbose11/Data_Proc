{{config (
   materialized = 'incremental',
   unique_key = 'story_dt',
   incremental_strategy='delete+insert',
)
}}

--pull the stories for the given date range 
--(controlled by delta days as used in the  ?) 
with base as 
(
   select rd.dt, unnest( rd.raw_payload->> '$.hits[*]') as hits
   from {{source("hn_trends_brnz", "raw_data")}} rd
   where rd.type = 'story'
   {% if is_incremental() %}
   and rd.dt between '{{ var("start_date") }}' and '{{ var("end_date") }}'
   {% endif %}
)

select dt as story_dt, 
       (hits ->> '$.story_id' ) :: bigint as story_id,
       hits ->> '$.author' as author, 
       hits ->> '$.title' as title, 
       hits ->> '$.url' as url, 
       (hits ->> '$.points'):: int as points , 
       (hits ->> '$.num_comments') :: int as num_comments,       
       (hits ->> '$.created_at') ::timestamp as story_created_at_ts, 
       --hits ->> '$.created_at_i' as  story_created_at_unix_ts,       
       (hits ->> '$.updated_at') ::timestamp as updated_at, 
       (hits ->> '$._tags') :: varchar[] as tags, 
       list_contains(tags, 'front_page') as front_page, 
       list_contains(tags, 'ask_hn') as ask_hn, 
       list_contains(tags, 'show_hn') as show_hn, 
       (hits ->> '$.children') :: varchar[] as children,
       current_timestamp as date_loaded
from base