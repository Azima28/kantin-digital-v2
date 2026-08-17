import os
import sys
import zipfile
import urllib.request

GO_ZIP_URL = "https://go.dev/dl/go1.22.6.windows-amd64.zip"
TARGET_DIR = r"C:\laragon\bin\go"
ZIP_PATH = r"C:\laragon\bin\go1.22.6.zip"

def download_file(url, target_path):
    print(f"[*] Downloading {url} to {target_path}...")
    def reporthook(count, block_size, total_size):
        percent = int(count * block_size * 100 / total_size)
        sys.stdout.write(f"\r    Downloading: {percent}% [{count * block_size / (1024*1024):.1f} MB / {total_size / (1024*1024):.1f} MB]")
        sys.stdout.flush()

    urllib.request.urlretrieve(url, target_path, reporthook)
    print("\n[SUCCESS] Download completed!")

def extract_zip(zip_path, extract_to):
    print(f"[*] Extracting {zip_path} to {extract_to}...")
    os.makedirs(extract_to, exist_ok=True)
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(extract_to)
    print("[SUCCESS] Extraction completed!")

def main():
    if not os.path.exists(TARGET_DIR):
        os.makedirs(TARGET_DIR, exist_ok=True)

    go_exe = os.path.join(TARGET_DIR, "go", "bin", "go.exe")
    if os.path.exists(go_exe):
        print(f"[ALREADY INSTALLED] Go is already present at {go_exe}")
        return

    if not os.path.exists(ZIP_PATH):
        download_file(GO_ZIP_URL, ZIP_PATH)

    extract_zip(ZIP_PATH, TARGET_DIR)

    if os.path.exists(ZIP_PATH):
        try:
            os.remove(ZIP_PATH)
            print("[CLEANUP] Removed temporary zip file.")
        except:
            pass

    if os.path.exists(go_exe):
        print(f"\n[READY] Go installed successfully at: {go_exe}")
    else:
        print(f"[ERROR] Could not find {go_exe} after extraction.")

if __name__ == "__main__":
    main()
