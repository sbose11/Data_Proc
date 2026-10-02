# Hacker News Trends Explorer

To create a virtual environment on your local machine for the hackernews project, 
Follow the steps
----
## Prerequisites- 
I have used uv packet manager, 
to install uv use - ```bash curl -LsSf https://astral.sh/uv/install.sh | sh ```
### Note: By default, uv will be installed at ~/.local/bin/uv  

----------
### Navigate to the project directory

`cd projects/hn_trends_explorer`
`uv venv --python 3.13`. Using the same version of python as in the container
`source .venv/bin/activate`
`uv pip install -r requirements.txt`