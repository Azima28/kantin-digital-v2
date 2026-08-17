import os
import json
import urllib.request
from urllib.parse import urlparse

def download_file(url, target_path):
    os.makedirs(os.path.dirname(target_path), exist_ok=True)
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as resp, open(target_path, 'wb') as out_file:
            out_file.write(resp.read())
        return True
    except Exception as e:
        print(f"[ERROR] Failed to download {url}: {e}")
        return False

def main():
    backup_media_dir = "database_backup/media"
    products_dir = os.path.join(backup_media_dir, "products")
    avatars_dir = os.path.join(backup_media_dir, "avatars")

    os.makedirs(products_dir, exist_ok=True)
    os.makedirs(avatars_dir, exist_ok=True)

    print("=== STARTING MEDIA & IMAGES BACKUP ===")

    # 1. Products images
    products_file = "database_backup/json/products.json"
    downloaded_products = 0
    if os.path.exists(products_file):
        with open(products_file, 'r', encoding='utf-8') as f:
            products = json.load(f)

        for p in products:
            img_url = p.get('image_url')
            if img_url and img_url.startswith('http'):
                filename = os.path.basename(urlparse(img_url).path)
                if not filename:
                    filename = f"prod_{p['id']}.png"
                target = os.path.join(products_dir, filename)
                print(f"[*] Downloading product image ({p['name']}): {img_url} -> {filename}")
                if download_file(img_url, target):
                    downloaded_products += 1

    # 2. Profiles avatar images
    profiles_file = "database_backup/json/profiles.json"
    downloaded_avatars = 0
    if os.path.exists(profiles_file):
        with open(profiles_file, 'r', encoding='utf-8') as f:
            profiles = json.load(f)

        for prof in profiles:
            avatar_url = prof.get('avatar_url')
            if avatar_url and avatar_url.startswith('http'):
                filename = os.path.basename(urlparse(avatar_url).path)
                if not filename:
                    filename = f"avatar_{prof['id']}.jpg"
                target = os.path.join(avatars_dir, filename)
                print(f"[*] Downloading avatar ({prof['full_name']}): {avatar_url} -> {filename}")
                if download_file(avatar_url, target):
                    downloaded_avatars += 1

    print("\n=========================================")
    print(f"[SUCCESS] Downloaded {downloaded_products} product images to '{products_dir}'")
    print(f"[SUCCESS] Downloaded {downloaded_avatars} avatar images to '{avatars_dir}'")
    print("=========================================\n")

if __name__ == "__main__":
    main()
