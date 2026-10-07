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
*Inner workings:*

The python script pulls the data from hacker news api. 
1. Using the delta_days variable - we can pull historical data (up to 7 days) from the api starting from the execution date.   
2. As of now the script is saving the json files locally. This will be moved to cloud storage eventually.
3. Stories and comment files for a given date are stored under that date directory.