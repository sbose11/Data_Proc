CREATE SCHEMA IF NOT EXISTS bronze;

CREATE TABLE IF NOT EXISTS bronze.raw_data( 
                            dt  date, 
                            type varchar(30),
                            raw_payload json, 
                            src_file  varchar(500), 
                            loaded_at timestamp,
                            loaded_by_dag varchar(50),
                            dag_task_name varchar(50)
                            ) ;
                            