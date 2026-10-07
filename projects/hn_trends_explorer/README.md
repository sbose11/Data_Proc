# Hacker News Trends Explorer

To create a virtual environment on your local machine for the hackernews project, follow the steps below: 

----

## Prerequisites
I have used `uv` packet manager. To install `uv` run:

```bash
curl -LsSf [https://astral.sh/uv/install.sh](https://astral.sh/uv/install.sh) | sh
```

- Note: By default, uv will be installed at ~/.local/bin/uv  

----------
*Local Setup and environment creation:* 

1. Navigate to the project directory:
  ```bash
      cd projects/hn_trends_explorer
  ```
2. Create a virtual environment (using Python 3.13):
  ```bash 
    uv venv --python 3.13
  ``` 
  (Matches the container python version)

3. Activate the virtual environment:
  ```bash 
       source .venv/bin/activate
  ``` 
4. Install project dependencis:  
  ```bash 
     uv pip install -r requirements.txt
  ```

----------
*Inner workings

The python script pulls the data from hacker news api. The code fetches all stories and comments posted in the last 24 hrs (1 day) (UTC time). As of now the script is saving the json files locally. This will be moved to cloud storage in next iteration.