--insert the records for the provided date 
insert into bronze.raw_data (dt, type, raw_payload, src_file, loaded_at) 
values ($dt_param, $file_type,  $file_txt_param, $src_file_param, current_timestamp)