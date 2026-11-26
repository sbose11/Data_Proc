## Project Overview
- The project HN Pulse puts together a dashboard to visualize the stories and comments posted on the hacker news website in the last 7 days. The project pulls data from the HN Algolia API, stores the raw JSON data -> loads this data to DuckDB using data/projects/hn_trends__explorer/data_load/bronze_load.py . Following this it uses dbt to move that data to silver and gold layers. This entire flow will be orchestrated by Airflow. 

## Environment & Commands 
- Package manager: 'uv' (do not use pip directly) 

## Versions (keep in sync)
- dbt 2.0.12 (Mac and Docker), bundled DuckDB v1.5.4, Python `duckdb==1.5.4`, Python 3.13

## Rules & Conventions 
- Rely only on trusted sources. Do not make up stuff. If you don't know it is okay to say so.
- As of now do not commit any code. 
