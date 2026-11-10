import logging
from datetime import date, datetime
from pathlib import Path
import os
import duckdb

#duckdb.sql("SELECT 'Hello World'").show()
#for the files which are in data_acquisition/raw_data - load them into a duck db table 
#The program should take the date as an argument and load for that date 
# need to traverse the story and comment folders
# We need to create a table that will hold the raw data with the following columns 
# 1. the date representing the folder (dt), 
# 2. data_type (story/comment)
# 3. the full json will be in 1 column (raw_data), 
# 4. date it was loaded and (data_load_dt)
# 5. the source file it came from  (src_file)
# 6. dag name that populated this table 
 

class LoadBronzeData: 

    def __init__(self, date_to_be_processed :date ): 
        self.__logger = logging.getLogger(__name__)
        self.proc_date = date_to_be_processed #processing date
        self.exec_date = datetime.now()
        self.project_root= Path(__file__).resolve().parent.parent.parent.parent
        self.db_dir = Path(os.environ.get("DATA_DIR", self.project_root/"data"))
        self.db_path = Path(self.db_dir/"hn_trends.duckdb")
        #self.raw_file_dir = Path(f"{Path(__file__).resolve().parent.parent}/data_acquisition/raw_data/{self.proc_date}")


    def set_duckdb_ddl(self):
        ddl_file = (Path(__file__).parent/"bronze_ddl.sql").read_text()
        try :
            with duckdb.connect(str(self.db_path)) as con :
                con.execute(ddl_file)
                print(con.execute("show all tables;").fetchall())
                print("DB file:", self.db_path.resolve())
                print(con.execute("""
                    SELECT table_schema, table_name
                    FROM information_schema.tables
                    WHERE table_schema = 'bronze'
                    """).fetchall())
            self.__logger.info("Bronze ddl executed, table created")
        except Exception as e: 
            self.__logger.error(f"Error in ddl execution when creating bronze schema/tables : {e}")

    def cleanup_duckdb_dml(self):
        # This will delete the entries in the bronze.raw_data table for the provided processing date 
       dml_file =(Path(__file__).parent/"bronze_cleanup_dml.sql").read_text()
       params = {"dt_param": self.proc_date}
       try: 
            with duckdb.connect(str(self.db_path)) as con :
                    delete_cnt = con.execute(dml_file, params).fetchone()
                    self.__logger.info(f"Deleted {delete_cnt} entries from bronze.raw_data table for dt = {self.proc_date}")
       except Exception as e: 
            self.__logger.error(f"Encountered an exception while deleting from raw_data table in bronze {e}")
   
    def load_duckdb_dml (self, ld_path ):
        #This will load the raw json files into the duckdb bronze table for the provided processing date
        dml_file =(Path(__file__).parent/"bronze_dml.sql").read_text()
        try : 
            with duckdb.connect(str(self.db_path)) as con :
                for json_file_path in ld_path.rglob("*.json"):
                    self.__logger.info(f"Load file set to: {json_file_path}")
                    file_contents = json_file_path.read_text()
                    if "comment" in str(json_file_path):
                        file_type = "comment"
                    if "story" in str(json_file_path): 
                        file_type = "story"   
                    self.__logger.info(f"file_type set to -{file_type}")
                    params = {"dt_param": self.proc_date, "file_type": file_type,  "src_file_param":str(json_file_path), "file_txt_param": file_contents}
                    con.execute(dml_file, params)
            self.__logger.info(f'Inserted fresh data for dt = {self.proc_date}')
        except Exception as e: 
            self.__logger.error(f'Encountered error when inserting data into bronze layer for dt = {self.proc_date}, {e}')

    def query_data(self):
        self.__logger.info('Print the # of rows in raw_data table :')
        with duckdb.connect(str(self.db_path)) as con :
            print(con.execute ("select count(*) from bronze.raw_data;").fetchall())
            #print(con.execute("select *from bronze.raw_data;").fetchall())
    def set_load_dir (self):
        file_load_path = Path(__file__).resolve().parent.parent
        path = Path(f"{file_load_path}/data_acquisition/raw_data/{self.proc_date}")

        if path.exists():
              self.__logger.info(f" Raw data load dir path set to -> {path}")
              self.set_duckdb_ddl()
              self.cleanup_duckdb_dml()
              self.load_duckdb_dml(path)
              self.query_data()
        else :
            self._logger.info("The provided date folder does not exist. Need to pull the data for provided date from hacker news api first.")
        

def main():
    logging.basicConfig(
        level = logging.INFO, #minimum threshold for logging
        format="{levelname}:{name}:{message}",
        style ="{"
        )

    logger = logging.getLogger(__name__)

    dl = LoadBronzeData('2026-10-08')
    dl.set_load_dir()

if __name__ == "__main__":
    main()