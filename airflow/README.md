
This ReadMe documents the steps done to set up the environment correctly.

# AIRFLOW SETUP 

1. Utilizing docker containers to spin up Airflow on my local machine
2. Since this is not production workload- using local executor instead of celery executor
3. Utilizing a Dockerfile to build custom image with dbt installed. 
4. To build new image containing dbt run  `docker compose build`
5. To start up services using the new image - `docker compose up -d`

# DuckDB
We have already mounted the volume (mapped the data folder) so that the data/ folder shared between the container and the local machne. 