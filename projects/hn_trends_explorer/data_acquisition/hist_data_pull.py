import requests 
import logging
from pathlib import Path
import time
from datetime import date,  datetime, timedelta, timezone#,  time as dt_time
import json 


class Throttle:
    def __init__(self, min_interval):
        self.min_interval = min_interval
        self._last = 0.0

    def wait(self):
        elapsed = time.monotonic() - self._last
        if elapsed < self.min_interval:
            time.sleep(self.min_interval - elapsed)
        self._last = time.monotonic()

class DataLoad:

    def __init__(self):
        self._logger = logging.getLogger(__name__)
        
        self._exec_ts = datetime.now(timezone.utc).timestamp()
        self._exec_dt_tm = datetime.fromtimestamp(self._exec_ts, tz=timezone.utc) 
        
        #Set local path where we want to save the json files 
        self._base_dir= Path(__file__).resolve().parent 
        self._logger.info(f"Base Dir set to -{self._base_dir}")

        #Set the api endpoint 
        self._base_url = "https://hn.algolia.com/api/v1"


    @property
    def execution_dt(self):
        return {"datetime" : self._exec_dt_tm, 
                "timestamp": self._exec_ts
                }

    #will return the start_date and timestamp after calculating the data pull window based on tdelta passed in 
    def calc_start_dt(self, tdelta:int):
       start_dt_tm = self._exec_dt_tm - timedelta(days=tdelta)
       start_ts = start_dt_tm.timestamp()
       return {"datetime": start_dt_tm, 
               "timestamp": start_ts
               }

    def get_stories(self, start_ts, end_ts):

        # this endpoint orders results in strict reverse chronological order (newest first)
        search_url = f"{self._base_url}/search_by_date"
        
        search_payload = {
                            "tags":"story",
                            "numericFilters":f"created_at_i >={start_ts}, created_at_i<={end_ts}" ,

                            # no of results to show on a given page (20 is default, 1000 is max)
                            "hitsPerPage":1000
                        }
        #self._logger.info(f" Search URL value :{search_url}{search_payload}") 

        try:           
            response = requests.get(search_url, params=search_payload, timeout=10)
            response.raise_for_status()
            self._logger.info(f"Retrieved story from search endpoint, response.status_code::{response.status_code}")
            data = response.json() # returns dict 
            return data
        except requests.exceptions.HTTPError as h_err:  #catches bad status code from raise_for_status()
            self._logger.error(f"Exception occured when getting data from search_endpoint:{h_err}") 
        except Exception as err:
            self._logger.error(f"Exception occured when pulling from search api -  {err}")
    
    
    def get_comments (self, story_id):
        item_url = f"{self._base_url}/items/{story_id}"
        #self._logger.info(f"Item URL value :{item_url}")
        try:
            response = requests.get(item_url, timeout =10)
            response.raise_for_status()
            self._logger.info(f"Retrieved Comments for Story_id-{story_id}")
            data = response.json()
            return data
        except requests.exceptions.HTTPError as h_err:  #catches bad status code from raise_for_status()
            self._logger.error(f"Exception occured when getting data from comment_endpoint:{h_err}") 
        except Exception as err:
            self._logger.error(f"Exception occured when pulling from comment api -  {err}")

   
    #type shows if the file is of type 'story' or 'comment'
    #ts is the timestamp when the story/comment was created
    def write_json(self, data, type:str, ts, story_id):
        
        exec_dt = self._exec_dt_tm.date()
        #set the file path where we want to store the data 
        filepath = Path(f"{self._base_dir}/raw_data/{exec_dt}/{type}/{story_id}_{ts}.json")
        #self._logger.info(f"Filepath set to - {filepath}")

        #helps with dynamic creation of directories
        filepath.parent.mkdir(parents=True, exist_ok = True)
       
        #wite this file 
        try:
            with open(filepath, "w",encoding= "utf-8") as file:
                json.dump(data, file, indent=4)
                self._logger.info (f"{type} file written at {filepath} ")

        except Exception as err: 
            self._logger.error(f"Problem writing json {type} : {err}")

    
def main():

    logging.basicConfig(
        level = logging.INFO, #minimum threshold for logging
        format="{levelname}:{name}:{message}",
        style ="{"
        )

    logger = logging.getLogger(__name__)

    #using half of a second as min_interval to control api calls
    throttle = Throttle(min_interval=0.50) 
    
    #As of now we are pulling all the data starting 1 day prior to the programs execution date
    delta_days = 1 ; 
    
    dl = DataLoad()
    

    start_window = dl.calc_start_dt(delta_days)
    end_window = dl.execution_dt
    
    
    end_ts = end_window["timestamp"]
    start_ts = start_window["timestamp"]

    logger.info(f"Start dt and timestamp in UTC are set to : {start_window['datetime']}   {start_window['timestamp']}")
    logger.info(f"End dt and timestamp in UTC are set to : {end_window['datetime']}   {end_window['timestamp']}")
    
    curr_max_ts = end_ts
    
    while curr_max_ts >= start_ts:

        #the search url will return 1000 hits/results maximum. If we want ee can break it(1000 hits) into 10 pages or 100 
        #but the problem is we cannot get more than 1000 results at a time. 
        #We are trying to get all stories submitted since yesterday, that number can be > 1000 so 
        #we have to iterate or call the api multiple times with a different  timestamp filter to 
        #return all the stories submitted between the timestamp values 
        raw_data = dl.get_stories(start_ts, curr_max_ts)

        #extract the hits list from raw data
        hits = raw_data["hits"] # will give a list of dicts
       
        #iterate through the hits
        for itm in hits: 
            story_id= itm["story_id"]
            story_comment_cnt = itm["num_comments"]
            story_creation_ts = itm["created_at_i"]
            
            #pull the comment tree for each story_id
            if story_comment_cnt > 0:  
                throttle.wait()
                comments_tree = dl.get_comments(story_id)
                dl.write_json(comments_tree, 'comment',  str(story_creation_ts), str(story_id)) 

        #write the file containing all the stories retrieved
        dl.write_json(raw_data, 'story', str(story_creation_ts), str(story_id))

        #set the parameters for pagination via timestamps
        #Since we have capped the nb of hits to 1000 per page, if the
        #nbhits is greater than 1000 then we have more pages to traverse
        if raw_data["nbHits"]>1000:
            #retrieve the record with minimum timestamp from the hits list returned
            rec_with_min_ts = min(hits, default=None, key=lambda x:x["created_at_i"]) 

            curr_max_ts = float(rec_with_min_ts["created_at_i"])
            logger.info(f'curr_min_ts - {curr_max_ts}')
        else:
            logger.info("Reached iterating through all the stories for the given time window") 
            break   
      
        

if __name__ == "__main__":
    main()
    