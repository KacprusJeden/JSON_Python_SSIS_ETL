import json
import pandas as pd
from sqlalchemy import create_engine, URL
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime as dt

'''
Author: Kacper Prusinski
Load data from JSON file to SQL Server (multithreaded)
'''

def get_connection_url(host: str, db: str, user: str, password: str) -> str:
    driver = "ODBC Driver 17 for SQL Server"
    connection_string = f'DRIVER={driver};SERVER={host};PORT=1433;DATABASE={db};UID={user};PWD={password};&autocommit=true'
    return URL.create("mssql+pyodbc", query={"odbc_connect": connection_string})

def insert_chunk(chunk, table_name, engine):
    try:
        chunk.to_sql(con=engine, schema='docsexample', name=table_name, if_exists='append', index=False)
        time = dt.today()
        print(f"Wstawiono {len(chunk)} rekordow do {table_name} - {time}")
    except Exception as e:
        print(f"Blad wstawiania do {table_name}: {e}")

if __name__ == "__main__":
    conn_url = get_connection_url(host='localhost', db='JsonDocsExample', user='prog', password='prog123')

    try:
        engine = create_engine(conn_url, use_setinputsizes=False, echo=False)
        db_connection = engine.connect()

        # JSON Source
        src = 'in_1000000.json'

        time = dt.today()
        print(f'Start ETL on: {time}')

        with open(src, encoding="UTF8") as file:
            data = json.load(file)

        package_types = {"id_type": [], "type": []}
        items = {"id_entry": [], "package": [], "created_at": [], "period": [], "incomes": [], "expenses": []}

        i = 1
        # Przetwarzanie JSON do DataFrame
        for item in data["items"]:
            package = item["package"]
            created = item["created"]
            summaries = item.get("summary", [])

            if package not in package_types["type"]:
                package_types["type"].append(package)

            if not summaries:
                items["id_entry"].append(i)
                items["package"].append(package)
                items["created_at"].append(created)
                items["period"].append(None)
                items["incomes"].append(None)
                items["expenses"].append(None)
                i += 1
            else:
                for summary in summaries:
                    period = summary.get("period", None)
                    documents = summary.get("documents", {})
                    incomes = documents.get("incomes", None)
                    expenses = documents.get("expenses", None)

                    items["id_entry"].append(i)
                    items["package"].append(package)
                    items["created_at"].append(created)
                    items["period"].append(period)
                    items["incomes"].append(incomes)
                    items["expenses"].append(expenses)
                    i += 1

        del data

        package_types["id_type"] = [i + 1 for i in range(len(package_types["type"]))]

        items_df = pd.DataFrame(items)
        package_types_df = pd.DataFrame(package_types)

        items_df = pd.merge(items_df, package_types_df, left_on='package', right_on='type', how='left')
        items_df = items_df[['id_entry', 'id_type', 'created_at', 'period', 'incomes', 'expenses']]
        items_df = items_df.rename({'id_type': 'id_pkg_type'}, axis=1)

        # Podzial na batch'e po 10,000 rekordow
        def split_dataframe(df, chunk_size):
            return [df.iloc[i:i + chunk_size] for i in range(0, df.shape[0], chunk_size)]

        package_batches = split_dataframe(package_types_df, 10000)
        item_batches = split_dataframe(items_df, 10000)

        # Wielowatkowe wstawianie danych
        with ThreadPoolExecutor(max_workers=4) as executor:
            executor.map(insert_chunk, package_batches, ["pkg_type"] * len(package_batches), [engine] * len(package_batches))
            executor.map(insert_chunk, item_batches, ["documents_facts"] * len(item_batches), [engine] * len(item_batches))

        time = dt.today()
        print(f"Wszystkie dane zostaly zapisane! - {time}")

        del package_batches, package_types_df, package_types
        del item_batches, items_df, items

        db_connection.close()

    except Exception as e:
        db_connection.close()
        print(e)