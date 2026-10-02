
## AIRFLOW SETUP 

1. Utilizing docker containers to spin up Airflow
2. Since this is not production workload- using local executor instead of celery executor
3. Utilizing a Dockerfile to build custom image with dbt installed. 
4. Have added a .dockerignore file as the context of build is not set to the airflow directory but to the root of project (data_proc). The .dockerignore limits which files the docker can see while building the image. This keeps the builds fast and makes sure the data or venvs are not copied into the image by accident. 
5. this was done to make sure the required python libraries are correctly loaded for each project.  

## To build the docker image and get it running
1. To build new image containing dbt run  `docker compose build`
2. To start up services using the new image - `docker compose up -d`
3. To stop and remove containers use `docker compose down`

## DuckDB
We have already mounted the volume so that the data/ folder shared between the container and the local machne. 