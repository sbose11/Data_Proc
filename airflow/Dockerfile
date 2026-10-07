#This docker image has Python 3.13.14 as default python version 
FROM apache/airflow:3.3.1  

USER root
RUN curl -fsSL https://public.cdn.getdbt.com/fs/install/install.sh | sh -s -- --update \
    && mv /root/.local/bin/dbt /usr/local/bin/dbt \
    && dbt --version

USER airflow

#copy requirements file and install dependencies 
COPY projects/hn_trends_explorer/requirements.txt /tmp/requirements/hn_trends_explorer.txt
RUN pip install --no-cache-dir "apache-airflow==${AIRFLOW_VERSION}" -r /tmp/requirements/hn_trends_explorer.txt