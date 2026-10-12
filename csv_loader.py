import os
import glob
import pyodbc
from dotenv import load_dotenv
import pandas as pd
import numpy as np
from datetime import datetime

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# ---------------------------------------------------------
# Load environment file
# ---------------------------------------------------------
def load_env(env_file):
	if not os.path.exists(env_file):
		raise FileNotFoundError(f"Environment file not found {env_file}")
	load_dotenv(env_file)

# ---------------------------------------------------------
# Build connection string
# ---------------------------------------------------------
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

# ---------------------------------------------------------
# Minimal type conversion so SQL Server accepts values
# ---------------------------------------------------------
def convert_value(v):
	if v is None:
		return None

	# pandas NA
	if isinstance(v, pd._libs.missing.NAType):
		return None

	# numpy scalar → python scalar
	if hasattr(v, "item"):
		v = v.item()

	# pandas Timestamp → datetime
	if isinstance(v, pd.Timestamp):
		return v.to_pydatetime()

	# numpy datetime64 → datetime
	if isinstance(v, np.datetime64):
		return pd.to_datetime(v).to_pydatetime()

	# empty strings → None
	if isinstance(v, str) and v.strip() == "":
		return None

	return v

# ---------------------------------------------------------
# Insert rows
# ---------------------------------------------------------
def insert_rows(cursor, table_name, columns, df):
	rows_processed = 0
	rows_skipped = 0

	col_list = ", ".join([f"[{c}]" for c in columns])
	placeholders = ", ".join(["?"] * len(columns))
	sql = f"insert into {table_name} ({col_list}) values ({placeholders})"

	for row in df.itertuples(index=False):
		try:
			converted = tuple(convert_value(v) for v in row)
			cursor.execute(sql, converted)
			rows_processed += 1
		except Exception as e:
			print(f"Skipping row due to error: {e}")
			rows_skipped += 1

	return rows_processed, rows_skipped

# ---------------------------------------------------------
# Main
# ---------------------------------------------------------
if __name__ == "__main__":
	role = "admin"
	conn_str = build_connection_string(role)

	initial_dir = os.path.join(BASE_DIR, "data", "initial")
	csv_files = glob.glob(os.path.join(initial_dir, "*.csv"))

	if not csv_files:
		raise FileNotFoundError(f"No CSV files found in {initial_dir}")

	with pyodbc.connect(conn_str, autocommit=True) as conn:
		cursor = conn.cursor()

		for csv_path in csv_files:
			table_name = os.path.splitext(os.path.basename(csv_path))[0]
			table_name = f"staging.{table_name}"

			print(f"Processing: {csv_path} → table {table_name}")

			# Load CSV with NO NA parsing
			df = pd.read_csv(
				csv_path,
				dtype=str,
				keep_default_na=False,
				na_values=[]
			)

			columns = list(df.columns)

			# TRUNCATE existing table
			cursor.execute(f"truncate table {table_name}")

			# Insert rows
			processed, skipped = insert_rows(cursor, table_name, columns, df)

			print(f"Completed: {table_name}")
			print(f"Rows processed: {processed}")
			print(f"Rows skipped: {skipped}")
			print("--------------------------------------------------")
