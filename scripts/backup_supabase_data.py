import urllib.request
import json
import os
import sys

SUPABASE_URL = "https://vgainyzrpfyaakqttjbm.supabase.co"
SUPABASE_KEY = "sb_publishable_kI9Am0ws3AUeIk84mS3hBQ_NZ-bwoAI"

TABLES = [
    "profiles",
    "students",
    "canteen_operators",
    "finance_officers",
    "parent_students",
    "products",
    "orders",
    "order_items",
    "order_messages",
    "transactions",
    "transaction_items",
    "balance_adjustments",
    "notifications",
    "audit_logs",
    "system_settings",
    "user_sessions"
]

def fetch_table_data(table_name):
    url = f"{SUPABASE_URL}/rest/v1/{table_name}?select=*"
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json"
    }

    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req) as response:
            if response.status == 200:
                data = json.loads(response.read().decode('utf-8'))
                return data
    except urllib.error.HTTPError as e:
        print(f"[WARN] Error fetching table '{table_name}': {e.code} {e.reason}")
        try:
            err_body = e.read().decode('utf-8')
            print(f"       Details: {err_body}")
        except:
            pass
        return None
    except Exception as e:
        print(f"[ERROR] Exception on '{table_name}': {e}")
        return None

def format_sql_value(val):
    if val is None:
        return "NULL"
    elif isinstance(val, bool):
        return "TRUE" if val else "FALSE"
    elif isinstance(val, (int, float)):
        return str(val)
    elif isinstance(val, (dict, list)):
        escaped_json = json.dumps(val).replace("'", "''")
        return f"'{escaped_json}'::jsonb"
    else:
        escaped_str = str(val).replace("'", "''")
        return f"'{escaped_str}'"

def main():
    backup_dir = "database_backup"
    json_dir = os.path.join(backup_dir, "json")
    os.makedirs(json_dir, exist_ok=True)

    full_dump = {}
    total_records = 0
    sql_lines = [
        "-- =====================================================================",
        "-- KANTIN DIGITAL v2.0 - FULL DATABASE BACKUP DATA",
        "-- Auto-generated backup from Supabase Remote Database",
        "-- =====================================================================\n",
        "SET statement_timeout = 0;",
        "SET lock_timeout = 0;",
        "SET client_encoding = 'UTF8';",
        "SET standard_conforming_strings = on;",
        "SET check_function_bodies = false;",
        "SET client_min_messages = warning;",
        "SET row_security = off;\n"
    ]

    print("=== STARTING SUPABASE DATABASE BACKUP ===")

    for table in TABLES:
        print(f"[*] Fetching table: {table}...")
        data = fetch_table_data(table)

        if data is not None:
            count = len(data)
            total_records += count
            full_dump[table] = data
            print(f"    -> [SUCCESS] Retrieved {count} records from '{table}'")

            # Write individual JSON
            table_json_path = os.path.join(json_dir, f"{table}.json")
            with open(table_json_path, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2, ensure_ascii=False)

            # Generate SQL INSERTs
            if count > 0:
                sql_lines.append(f"\n-- ---------------------------------------------------------------------")
                sql_lines.append(f"-- Data for table: public.{table} ({count} rows)")
                sql_lines.append(f"-- ---------------------------------------------------------------------")

                # Get column list from first row
                sample_cols = list(data[0].keys())
                col_names_str = ", ".join([f'"{c}"' for c in sample_cols])

                for row in data:
                    val_strs = [format_sql_value(row.get(c)) for c in sample_cols]
                    sql_lines.append(f"INSERT INTO public.{table} ({col_names_str}) VALUES ({', '.join(val_strs)}) ON CONFLICT DO NOTHING;")

    # Save full dump JSON
    full_json_path = os.path.join(backup_dir, "supabase_full_dump.json")
    with open(full_json_path, "w", encoding="utf-8") as f:
        json.dump(full_dump, f, indent=2, ensure_ascii=False)

    # Save full SQL restore file
    sql_path = os.path.join(backup_dir, "full_backup_data.sql")
    with open(sql_path, "w", encoding="utf-8") as f:
        f.write("\n".join(sql_lines))

    print("\n=========================================")
    print(f"[SUMMARY] Total tables processed : {len(TABLES)}")
    print(f"[SUMMARY] Total records backed up: {total_records}")
    print(f"[SAVED] Full JSON dump          : {full_json_path}")
    print(f"[SAVED] SQL Insert statements   : {sql_path}")
    print(f"[SAVED] Individual JSON files   : {json_dir}/")
    print("=========================================\n")

if __name__ == "__main__":
    main()
