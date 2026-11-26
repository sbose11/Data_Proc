# Hacker News Trends Explorer

Pulls Hacker News stories and comments from the HN Algolia API, saves the raw JSON locally, loads it into a DuckDB **bronze** table, and uses dbt to build **silver** tables (gold is not built yet).

> Only what exists in the code is described here. Anything not built yet is marked **TODO**.

## Overview

```
HN Algolia API
     |  data_acquisition/hist_data_pull.py
     v
Local JSON files   data_acquisition/raw_data/<YYYY-MM-DD>/{story,comment}/
     |  data_load/bronze_load.py
     v
DuckDB   bronze.raw_data
     |  dbt project: hn_trends/
     v
silver._stg_hn_stories, silver._stg_hn_comments
     |
     v
gold  (TODO: no models yet)  ->  dashboard (TODO: not built)
```

| Step | Status |
|---|---|
| API pull to local JSON | Built (`data_acquisition/hist_data_pull.py`) |
| Bronze load into DuckDB | Built (`data_load/bronze_load.py`) |
| Silver models and schema drift tests (dbt) | Built, see [hn_trends/README.md](hn_trends/README.md) |
| Gold models | TODO |
| Dashboard | TODO |
| Airflow orchestration | TODO (`dags/` is empty) |
| Raw files in cloud storage | TODO (files are saved locally for now) |

## Folder structure

```
hn_trends_explorer/
├── README.md
├── CLAUDE.md
├── requirements.txt
├── data_acquisition/
│   ├── hist_data_pull.py        # pulls stories and comments from the API
│   └── raw_data/                # output: one folder per date
├── data_load/
│   ├── bronze_load.py           # loads one date of raw JSON into DuckDB
│   ├── bronze_ddl.sql           # creates schema bronze and table bronze.raw_data
│   ├── bronze_cleanup_dml.sql   # deletes existing rows for a date
│   └── bronze_dml.sql           # inserts one row per JSON file
├── hn_trends/                   # dbt project (silver models, drift tests, seeds)
├── dags/                        # empty. TODO: Airflow DAGs
└── archive/                     # earlier versions of the pull script (v1, v2)
```

## Prerequisites

This project uses `uv` as its package manager. To install it:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

By default, `uv` is installed at `~/.local/bin/uv`.

## Local setup

1. Go to the project directory:
   ```bash
   cd projects/hn_trends_explorer
   ```
2. Create a virtual environment with Python 3.13:
   ```bash
   uv venv --python 3.13
   ```
   TODO: confirm this matches the container's Python version. CLAUDE.md lists 3.13, but no Dockerfile is in this folder.
3. Activate it:
   ```bash
   source .venv/bin/activate
   ```
4. Install the Python dependencies:
   ```bash
   uv pip install -r requirements.txt
   ```

5. dbt is installed in the container using the curl. Version pinned to 2.0.12

6. To initialize dbt folder structure for our project in the project, run 
   ```bash
   dbt init --skip-profile-setup
   ```
7. Write own profile file at the projects/hn_trend_explorer_root so that it can be seen by airflow as well. 

`requirements.txt` contains `requests` and `duckdb` (pinned to `1.5.4`, the same version as dbt uses). It does **not** include dbt. 

## How it works

### 1. Pull from the API: `data_acquisition/hist_data_pull.py`

- Calls the HN Algolia API (`search_by_date` for stories, `items/<story_id>` for each story's comment tree).
- The `delta_days` variable in `main()` sets how many days to pull, counting back from the execution date (UTC). It is currently set to `1`, which means today only. The value must be **less than 7**. Otherwise the script logs an error and pulls nothing. TODO: make this a command-line argument or config.
- The API returns at most 1000 stories per request, so the script pages through a day by moving the timestamp filter back.
- Calls to the comments endpoint are throttled to one every 0.5 seconds.
- If a day has no stories, the script logs "No stories are posted for this date range".
- Output goes to `data_acquisition/raw_data/<YYYY-MM-DD>/`:
  - `story/<story_id>_<created_ts>.json`: one file per page of story results.
  - `comment/<story_id>_<created_ts>.json`: comment trees for up to 250 stories per file.
- Re-running a date deletes that date's folder first, then recreates it.

```bash
python data_acquisition/hist_data_pull.py
```

### 2. Load into bronze: `data_load/bronze_load.py`

For one processing date it:

1. Creates schema `bronze` and table `bronze.raw_data` if they don't exist (`bronze_ddl.sql`).
2. Deletes existing rows for that date (`bronze_cleanup_dml.sql`).
3. Inserts one row per JSON file found under `raw_data/<date>/` (`bronze_dml.sql`). The row's type is `story` or `comment`, taken from the file path.

`bronze.raw_data` columns:

| Column | Filled by the load? |
|---|---|
| `dt` | Yes, the processing date |
| `type` | Yes, `story` or `comment` |
| `raw_payload` | Yes, the full JSON file as `json` |
| `src_file` | Yes, the source file path |
| `loaded_at` | Yes, `current_timestamp` |
| `loaded_by_dag` | No. TODO: will be set once Airflow is in place |
| `dag_task_name` | No. TODO: same as above |

Where the DuckDB file lives: `hn_trends.duckdb` inside the folder given by the `DATA_DIR` environment variable. If `DATA_DIR` is not set, the script uses a `data/` folder four levels above `data_load/bronze_load.py`. TODO: confirm this location and make sure it matches the path in the dbt profile.

The processing date is currently hard-coded in `main()` of `bronze_load.py`. TODO: take the date as a command-line argument, as the comments in the file intend.

```bash
python data_load/bronze_load.py
```

### 3. Transform with dbt: `hn_trends/`

Builds `silver._stg_hn_stories` and `silver._stg_hn_comments` from `bronze.raw_data`, and runs data tests and schema drift checks. See [hn_trends/README.md](hn_trends/README.md) for models, tests, drift checks and design decisions.

### 4. Orchestration

TODO: the plan (in CLAUDE.md) is to run the whole flow from Airflow. The `dags/` folder is empty.

## Versions

Per CLAUDE.md, keep these in sync:

- dbt 2.0.12 (Mac and Docker)
- DuckDB 1.5.4 (bundled with dbt) and Python `duckdb==1.5.4`
- Python 3.13
