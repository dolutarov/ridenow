# 🚖 RIDENOW – Fabric‑Ready Medallion Pipeline

This repository implements a **Bronze → Silver ingestion pipeline** for NYC Taxi data using **Python + SQL Server**.
It automates database creation, raw data ingestion, and historised transformations.

---

## 📂 Project Structure

IDENOW/
│
├── data/
│   ├── initial/
│   │   └── taxi_zone_lookup.csv
│   └── raw/
│       ├── yellow_tripdata_2024-01.parquet
│       ├── yellow_tripdata_2024-02.parquet
│       └── yellow_tripdata_2024-03.parquet
│
├── sql/
│   ├── 100_create_schema.sql
│   ├── 200_create_administrative_tables.sql
│   ├── 205_create_security_tables.sql
│   ├── 210_create_audit_tables.sql
│   ├── 215_create_config_tables.sql
│   ├── 220_create_tables_staging.sql
│   ├── 230_create_tables_silver.sql
│   ├── 600_datainitialisation_items.sql
│   ├── 610_data_initialisation_silver.sql
│   ├── 700_create_views.sql
│   └── 820_create_procedures_silver.sql
│
├── admin.env.sample
├── create_db.py
├── csv_loader.py
├── upload_raw.py
└── readme.md


---

## 🏗️ Database Creation (`create_db.py`)

`create_db.py` builds the database automatically.

### ✔ How it works
1. Reads credentials from **admin.env**:
   - `SQL_SERVER`
   - `SQL_DATABASE`
   - `SQL_USERNAME`
   - `SQL_PASSWORD`
2. Executes all `.sql` files from `/sql` **in name order**.
3. Splits scripts by `GO` statements.
4. Creates schemas, tables, constraints, and stored procedures.

This ensures a reproducible, deterministic database build.

---

## 📥 Raw Data Ingestion (`csv_loader.py`)

Loads all CSVs from `data/initial/` into staging tables.

### ✔ Features
- Reads all CSVs automatically.
- Uses `dtype=str`, `keep_default_na=False`, `na_values=[]`.
- Prevents pandas NA → float conversion.
- Truncates existing staging tables before loading.
- Uses credentials from `admin.env`.

---

## 🚀 Raw Upload Orchestration (`upload_raw.py`)

Coordinates:
1. CSV ingestion
2. Staging table truncation
3. Logging
4. Triggering Silver‑layer stored procedures

This is the entry point for the raw ingestion pipeline.

---

## 🥈 Silver Layer Stored Procedures

### `silver.merge_locations`
- Inserts/updates `silver.locations`.
- Uses `IDENTITY_INSERT` to align primary keys.
- Resolves FK references to `administrative.items`.
- Historisation‑safe (system‑versioned table).

### `silver.insert_YellowTrips`
- Inserts **only new or failed** staging rows.
- Uses **CTE + SELECT INTO #resolved**.
- Resolves all foreign keys:
  - vendor
  - ratecode
  - payment_type
  - pickup/dropoff locations
- Logs ingestion results in `staging.YellowTripData_transform_log`.
- Runs in **one transaction**.
- Append‑only (no updates).

---

## 🔄 Ingestion Flow

```bash
python create_db.py
python csv_loader.py
python upload_raw.py
```

In SQL Server:

EXEC silver.merge_locations;
EXEC silver.insert_YellowTrips;

