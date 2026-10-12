import os
import pyodbc
from dotenv import load_dotenv
import re

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

def create_db(folder, conn_str):
	files = sorted(f for f in os.listdir(folder) if f.lower().endswith(".sql"))

	if not files:
		raise FileNotFoundError("No SQL files found in {folder}")

	for file in files:
		path = os.path.join(folder, file)
		print(f"Executing: {file}")

		with open(path, "r", encoding="utf-8") as f:
			sql = f.read()

		commands = [
			cmd.strip()
			for cmd in re.split(r"(?i)\bGO\b", sql)
			if cmd.strip()
		]

		try:
			for cmd in commands:
				with pyodbc.connect(conn_str, autocommit=True) as conn:
					conn.cursor().execute(cmd)
		except Exception as e:
			print(f"Error in {file}")
			print(e)
			break
	print("Done!")

if __name__ == "__main__":
	role = "admin"
	conn_str = build_connection_string(role)

	SQL_FOLDER = os.path.join(BASE_DIR, r"SQL")
	create_db(SQL_FOLDER, conn_str)