import os
import sys
import subprocess
import zipfile
import urllib.request
import time

PG_ZIP_URL = "https://get.enterprisedb.com/postgresql/postgresql-16.4-1-windows-x64-binaries.zip"
TARGET_DIR = r"C:\laragon\bin\postgresql"
ZIP_PATH = r"C:\laragon\bin\postgresql.zip"
DATA_DIR = r"C:\laragon\bin\postgresql\data"
LOG_FILE = r"C:\laragon\bin\postgresql\logfile.log"

def download_file(url, target_path):
    print(f"[*] Mengunduh PostgreSQL 16 Windows Binaries dari {url}...")
    headers = {'User-Agent': 'Mozilla/5.0'}
    req = urllib.request.Request(url, headers=headers)

    with urllib.request.urlopen(req) as response, open(target_path, 'wb') as out_file:
        total_size = int(response.headers.get('Content-Length', 0))
        downloaded = 0
        block_size = 1024 * 1024  # 1MB

        while True:
            chunk = response.read(block_size)
            if not chunk:
                break
            out_file.write(chunk)
            downloaded += len(chunk)
            if total_size > 0:
                percent = int(downloaded * 100 / total_size)
                sys.stdout.write(f"\r    Progress: {percent}% [{downloaded / (1024*1024):.1f} MB / {total_size / (1024*1024):.1f} MB]")
                sys.stdout.flush()
    print("\n[SUCCESS] Unduhan PostgreSQL selesai!")

def extract_zip(zip_path, extract_to):
    print(f"[*] Mengekstrak {zip_path} ke {extract_to}...")
    os.makedirs(extract_to, exist_ok=True)
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(extract_to)
    print("[SUCCESS] Ekstraksi selesai!")

def main():
    os.makedirs(TARGET_DIR, exist_ok=True)
    bin_dir = os.path.join(TARGET_DIR, "pgsql", "bin")
    initdb_exe = os.path.join(bin_dir, "initdb.exe")
    pg_ctl_exe = os.path.join(bin_dir, "pg_ctl.exe")
    psql_exe = os.path.join(bin_dir, "psql.exe")
    createdb_exe = os.path.join(bin_dir, "createdb.exe")

    if not os.path.exists(initdb_exe):
        if not os.path.exists(ZIP_PATH):
            download_file(PG_ZIP_URL, ZIP_PATH)
        extract_zip(ZIP_PATH, TARGET_DIR)
        if os.path.exists(ZIP_PATH):
            try:
                os.remove(ZIP_PATH)
            except:
                pass

    if not os.path.exists(initdb_exe):
        print(f"[ERROR] initdb.exe tidak ditemukan di {initdb_exe}")
        return

    # Initialize data cluster if not exists
    if not os.path.exists(DATA_DIR) or not os.listdir(DATA_DIR):
        print(f"[*] Menginisialisasi cluster database PostgreSQL di {DATA_DIR}...")
        cmd = [initdb_exe, "-D", DATA_DIR, "-U", "postgres", "--auth=trust", "--encoding=UTF8", "--locale=C"]
        subprocess.run(cmd, check=True)
        print("[SUCCESS] Inisialisasi data cluster selesai!")

    # Start PostgreSQL Server
    print("[*] Menjalankan server PostgreSQL...")
    cmd_start = [pg_ctl_exe, "-D", DATA_DIR, "-l", LOG_FILE, "-o", "-p 5432", "start"]
    subprocess.run(cmd_start)
    time.sleep(2)

    # Check status
    cmd_status = [pg_ctl_exe, "-D", DATA_DIR, "status"]
    subprocess.run(cmd_status)

    # Create database kantin_digital
    print("[*] Membuat database 'kantin_digital'...")
    subprocess.run([createdb_exe, "-U", "postgres", "-p", "5432", "kantin_digital"], stderr=subprocess.DEVNULL)

    # Import schema & seed data
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    schema_sql = os.path.join(base_dir, "database_backup", "init_postgres_standalone.sql")
    data_sql = os.path.join(base_dir, "database_backup", "full_backup_data.sql")

    if os.path.exists(schema_sql):
        print(f"[*] Mengimpor skema database dari {schema_sql}...")
        subprocess.run([psql_exe, "-U", "postgres", "-p", "5432", "-d", "kantin_digital", "-f", schema_sql])

    if os.path.exists(data_sql):
        print(f"[*] Mengimpor data awal pengguna, saldo, & menu dari {data_sql}...")
        subprocess.run([psql_exe, "-U", "postgres", "-p", "5432", "-d", "kantin_digital", "-f", data_sql])

    # Set password postgres
    subprocess.run([psql_exe, "-U", "postgres", "-p", "5432", "-d", "kantin_digital", "-c", "ALTER USER postgres WITH PASSWORD 'postgres';"])

    print("\n[READY] PostgreSQL 16 & Database 'kantin_digital' berhasil aktif dan siap!")

if __name__ == "__main__":
    main()
