import os
import glob
import duckdb
import pyodbc
from dotenv import load_dotenv
import pandas as pd
import uuid
import math
from datetime import datetime

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def load_env(env_file):
	if not os.path.exists(env_file):
		raise FileNotFoundError(f"Environment file not found {env_file}")
	load_dotenv(env_file)

def build_connection_string(role):

	allowed = {"admin"}

	if role not in allowed:
		raise ValueError(f"Invalid role '{role}'. Allowed values: {allowed}")

	ENV_PATH = os.path.join(BASE_DIR, role + ".env")
	load_env(ENV_PATH)

	server = os.getenv("SQL_SERVER")
	database = os.getenv("SQL_DATABASE")
	username = os.getenv("SQL_USERNAME")
	password = os.getenv("SQL_PASSWORD")

	return (
		"Driver={ODBC Driver 18 for SQL Server};"
		f"Server={server};"
		f"Database={database};"
		f"UID={username};"
		f"PWD={password};"
		"Encrypt=no;"
	)

INSERT_SQL = """
INSERT INTO staging.YellowTripData (
	VendorID, tpep_pickup_datetime, tpep_dropoff_datetime,
	passenger_count, trip_distance, RatecodeID,
	store_and_fwd_flag, PULocationID, DOLocationID,
	payment_type, fare_amount, extra, mta_tax,
	tip_amount, tolls_amount, improvement_surcharge,
	total_amount, congestion_surcharge, Airport_fee,
	file_name, uploading_process, ingesting_errors
)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
"""

# ---------------------------------------------------------
# Minimal type conversion (NOT sanitising)
# ---------------------------------------------------------
def convert_types(row):
	converted = []
	for v in row:

		# pandas NA
		if isinstance(v, pd._libs.missing.NAType):
			converted.append(None)
			continue

		# pandas Timestamp → datetime
		if isinstance(v, pd.Timestamp):
			converted.append(v.to_pydatetime())
			continue

		# numpy scalar → python scalar
		if hasattr(v, "item"):
			v = v.item()

		# floats: convert NaN/inf to None (SQL Server cannot bind them)
		if isinstance(v, float):
			if math.isnan(v) or math.isinf(v):
				converted.append(None)
				continue

		converted.append(v)

	return tuple(converted)

def upload_parquets(conn_str):

	raw_dir = os.path.join(BASE_DIR, "data", "raw")
	parquet_files = glob.glob(os.path.join(raw_dir, "yellow_tripdata*.parquet"))

	if not parquet_files:
		raise FileNotFoundError(f"No parquet files found in {raw_dir}")

	process_id = str(uuid.uuid4())

	rows_processed = 0
	rows_skipped = 0

	with pyodbc.connect(conn_str, autocommit=True) as conn:
		cursor = conn.cursor()

		for file_path in parquet_files:
			print(f"Loading: {file_path}")

			file_name = os.path.basename(file_path)
			df = duckdb.read_parquet(file_path).to_df()

			for row in df.itertuples(index=False):

				raw_row = convert_types(row)

				try:
					final_row = raw_row + (file_name, process_id, None)
					cursor.execute(INSERT_SQL, final_row)
					rows_processed += 1

				except Exception as e:
					error_msg = str(e)

					safe_nulls = (None,) * 19
					error_row = safe_nulls + (file_name, process_id, error_msg)

					cursor.execute(INSERT_SQL, error_row)
					rows_skipped += 1

			print(f"Completed: {file_path}")

	print("--------------------------------------------------")
	print(f"Rows successfully processed: {rows_processed}")
	print(f"Rows skipped due to errors: {rows_skipped}")
	print("--------------------------------------------------")

if __name__ == "__main__":
	role = "admin"
	conn_str = build_connection_string(role)
	upload_parquets(conn_str)
