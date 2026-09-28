FROM apache/airflow:3.3.1

USER root
RUN curl -fsSL https://public.cdn.getdbt.com/fs/install/install.sh | sh -s -- --update \
    && mv /root/.local/bin/dbt /usr/local/bin/dbt \
    && dbt --version

USER airflow