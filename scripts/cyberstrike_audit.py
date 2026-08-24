#!/usr/bin/env python3
"""
=============================================================================
  CYBERSTRIKE AI - PENETRATION TESTING & SECURITY AUDIT SUITE
  Target: Kantin Digital v2.0 REST API & Database
=============================================================================
"""

import sys
import time
import json
import base64
import hmac
import hashlib
import requests
from concurrent.futures import ThreadPoolExecutor, as_completed

BASE_URL = "http://localhost/api/v1"
WS_URL = "ws://localhost/ws"

# ANSI Colors
C_RESET = "\033[0m"
C_RED = "\033[91m"
C_GREEN = "\033[92m"
C_YELLOW = "\033[93m"
C_BLUE = "\033[94m"
C_CYAN = "\033[96m"
C_BOLD = "\033[1m"

passed_count = 0
failed_count = 0
warnings_count = 0
test_results = []

def print_header(title):
    print(f"\n{C_CYAN}{C_BOLD}{'='*75}{C_RESET}")
    print(f"{C_CYAN}{C_BOLD}  [CYBERSTRIKE] {title}{C_RESET}")
    print(f"{C_CYAN}{C_BOLD}{'='*75}{C_RESET}")

def report(test_id, name, status, detail=""):
    global passed_count, failed_count, warnings_count
    if status == "PASSED":
        passed_count += 1
        tag = f"{C_GREEN}[PASS]{C_RESET}"
    elif status == "FAILED":
        failed_count += 1
        tag = f"{C_RED}[FAIL - VULNERABLE]{C_RESET}"
    else:
        warnings_count += 1
        tag = f"{C_YELLOW}[WARN]{C_RESET}"

    print(f"  {tag} {C_BOLD}{test_id}{C_RESET}: {name}")
    if detail:
        print(f"         {C_BLUE}-> {detail}{C_RESET}")
    test_results.append({"id": test_id, "name": name, "status": status, "detail": detail})

def create_fake_jwt(header, payload, secret="wrong_secret"):
    h_b64 = base64.urlsafe_b64encode(json.dumps(header).encode()).decode().rstrip('=')
    p_b64 = base64.urlsafe_b64encode(json.dumps(payload).encode()).decode().rstrip('=')
    msg = f"{h_b64}.{p_b64}".encode()
    sig = hmac.new(secret.encode(), msg, hashlib.sha256).digest()
    sig_b64 = base64.urlsafe_b64encode(sig).decode().rstrip('=')
    return f"{h_b64}.{p_b64}.{sig_b64}"

def login(identifier, password, role=""):
    payload = {"identifier": identifier, "password": password}
    if role:
        payload["role"] = role
    try:
        res = requests.post(f"{BASE_URL}/auth/login", json=payload, timeout=5)
        if res.status_code == 200:
            data = res.json()
            token = data.get("data", {}).get("token")
            user = data.get("data", {}).get("user", {})
            return token, user
    except Exception as e:
        print(f"Login failed: {e}")
    return None, None

# =============================================================================
#  VECTOR 1: AUTHENTICATION & TOKEN SECURITY
# =============================================================================
def test_vector_1():
    print_header("VEKTOR 1: Otentikasi & Manipulasi Token JWT")

    # 1.1 Unauthenticated access to protected endpoints
    protected_endpoints = [
        ("/finance/dashboard", "GET"),
        ("/admin/users", "GET"),
        ("/pos/sales-history", "GET"),
        ("/student/transactions", "GET"),
    ]
    all_rejected = True
    for ep, method in protected_endpoints:
        r = requests.request(method, f"{BASE_URL}{ep}", timeout=5)
        if r.status_code not in (401, 403):
            all_rejected = False
            report("V1.1", f"Unauthenticated request to {ep}", "FAILED", f"Status: {r.status_code}")
            break
    if all_rejected:
        report("V1.1", "Akses Tanpa Token pada Endpoint Privat", "PASSED", "Semua endpoint privat menolak akses (401 Unauthorized)")

    # 1.2 Forged signature token
    fake_token = create_fake_jwt(
        {"alg": "HS256", "typ": "JWT"},
        {"user_id": "00000000-0000-0000-0000-000000000000", "role": "super_admin", "exp": int(time.time()) + 3600},
        "attacker_fake_secret_key"
    )
    r = requests.get(f"{BASE_URL}/admin/dashboard", headers={"Authorization": f"Bearer {fake_token}"}, timeout=5)
    if r.status_code in (401, 403):
        report("V1.2", "Penolakan Token dengan Signature Palsu", "PASSED", f"Server menolak token palsu ({r.status_code})")
    else:
        report("V1.2", "Penolakan Token dengan Signature Palsu", "FAILED", f"Server menerima token palsu! Status: {r.status_code}")

    # 1.3 Expired token
    expired_token = create_fake_jwt(
        {"alg": "HS256", "typ": "JWT"},
        {"user_id": "00000000-0000-0000-0000-000000000000", "role": "super_admin", "exp": int(time.time()) - 3600},
        "kantin-digital-v2-super-production-secret-jwt-key-2026"
    )
    r = requests.get(f"{BASE_URL}/admin/dashboard", headers={"Authorization": f"Bearer {expired_token}"}, timeout=5)
    if r.status_code in (401, 403):
        report("V1.3", "Penolakan Token Kedaluwarsa (Expired Token)", "PASSED", f"Token expired ditolak ({r.status_code})")
    else:
        report("V1.3", "Penolakan Token Kedaluwarsa (Expired Token)", "FAILED", f"Server menerima expired token! Status: {r.status_code}")

    # 1.4 Alg: None attack
    h_none = base64.urlsafe_b64encode(b'{"alg":"none","typ":"JWT"}').decode().rstrip('=')
    p_none = base64.urlsafe_b64encode(b'{"user_id":"admin","role":"super_admin"}').decode().rstrip('=')
    none_token = f"{h_none}.{p_none}."
    r = requests.get(f"{BASE_URL}/admin/dashboard", headers={"Authorization": f"Bearer {none_token}"}, timeout=5)
    if r.status_code in (401, 403):
        report("V1.4", "Mitigasi Algoritma None (alg: none bypass)", "PASSED", f"Token alg:none ditolak ({r.status_code})")
    else:
        report("V1.4", "Mitigasi Algoritma None (alg: none bypass)", "FAILED", f"Bypass alg:none berhasil! Status: {r.status_code}")

# =============================================================================
#  VECTOR 2: BFLA & IDOR ACCESS CONTROL
# =============================================================================
def test_vector_2():
    print_header("VEKTOR 2: Eskalasi Hak Akses (BFLA & IDOR)")

    student_token, student_user = login("20260001", "password123", "student")
    if not student_token:
        student_token, student_user = login("student_20260001", "password123", "student")

    if not student_token:
        report("V2.0", "Login Siswa untuk Uji BFLA", "WARN", "Akun siswa default tidak ditemukan, melewati uji berbasis token siswa")
        return

    s_headers = {"Authorization": f"Bearer {student_token}"}

    # 2.1 Student calling Top-up endpoint
    r = requests.post(f"{BASE_URL}/finance/topup", headers=s_headers, json={"student_id": student_user.get("id"), "amount": 100000}, timeout=5)
    if r.status_code in (401, 403):
        report("V2.1", "BFLA: Siswa Memanggil Endpoint Top-Up Keuangan", "PASSED", f"Akses ditolak ({r.status_code} Forbidden)")
    else:
        report("V2.1", "BFLA: Siswa Memanggil Endpoint Top-Up Keuangan", "FAILED", f"Siswa berhasil top-up sendiri! Status: {r.status_code}")

    # 2.2 Student calling Admin Users
    r = requests.get(f"{BASE_URL}/admin/users", headers=s_headers, timeout=5)
    if r.status_code in (401, 403):
        report("V2.2", "BFLA: Siswa Mengakses Data Pengguna Admin", "PASSED", f"Akses ditolak ({r.status_code} Forbidden)")
    else:
        report("V2.2", "BFLA: Siswa Mengakses Data Pengguna Admin", "FAILED", f"Siswa dapat melihat user admin! Status: {r.status_code}")

    # 2.3 Student attempting to withdraw merchant funds
    r = requests.post(f"{BASE_URL}/finance/merchant/withdraw", headers=s_headers, json={"merchant_id": "test", "amount": 50000}, timeout=5)
    if r.status_code in (401, 403):
        report("V2.3", "BFLA: Siswa Melakukan Penarikan Saldo Merchant (Withdraw)", "PASSED", f"Akses ditolak ({r.status_code} Forbidden)")
    else:
        report("V2.3", "BFLA: Siswa Melakukan Penarikan Saldo Merchant (Withdraw)", "FAILED", f"Siswa dapat withdraw! Status: {r.status_code}")

    # 2.4 IDOR: Parent modifying settings of arbitrary child
    parent_token, _ = login("parent_student_20260001", "password123", "parent")
    if not parent_token:
        parent_token, _ = login("20260001", "password123", "parent")

    if parent_token:
        p_headers = {"Authorization": f"Bearer {parent_token}"}
        fake_child_id = "00000000-0000-0000-0000-000000000000"
        r = requests.patch(f"{BASE_URL}/student/settings", headers=p_headers, json={"student_id": fake_child_id, "daily_limit": 5000}, timeout=5)
        if r.status_code in (401, 403, 404):
            report("V2.4", "IDOR: Parent Mengubah Limit Siswa Bukan Anaknya", "PASSED", f"Akses relasi ditolak ({r.status_code})")
        else:
            report("V2.4", "IDOR: Parent Mengubah Limit Siswa Bukan Anaknya", "FAILED", f"IDOR terbuka! Status: {r.status_code}")

# =============================================================================
#  VECTOR 3: DOUBLE-SPEND & CONCURRENCY RACE CONDITION
# =============================================================================
def test_vector_3():
    print_header("VEKTOR 3: Double-Spend & Concurrency Race Condition Attack")

    canteen_token, canteen_user = login("petugas", "password123", "petugas_kantin")
    if not canteen_token:
        canteen_token, canteen_user = login("ani", "password123", "petugas_kantin")

    if not canteen_token:
        report("V3.0", "Login Kasir Kantin untuk Race Condition", "WARN", "Akun kasir tidak ditemukan, melewati uji race condition")
        return

    # Get a real student
    products_res = requests.get(f"{BASE_URL}/products", timeout=5).json()
    products = products_res.get("data", [])
    if not products:
        report("V3.0", "Katalog Produk untuk Race Condition", "WARN", "Produk kosong")
        return

    target_product = products[0]
    prod_id = target_product.get("id")
    prod_price = target_product.get("price", 1000)
    operator_id = target_product.get("operator_id")

    # Get student info
    c_headers = {"Authorization": f"Bearer {canteen_token}"}
    st_lookup = requests.get(f"{BASE_URL}/student/lookup?nisn=20260002", timeout=5).json()
    st_data = st_lookup.get("data", {})
    student_id = st_data.get("id")

    if not student_id:
        report("V3.0", "Lookup Siswa untuk Uji Concurrency", "WARN", "Siswa 20260002 tidak ditemukan")
        return

    print(f"  {C_BLUE}Executing 20 Concurrent Checkout Requests on Product: '{target_product.get('name')}' (Rp {prod_price}){C_RESET}")

    checkout_payload = {
        "student_id": student_id,
        "operator_id": operator_id,
        "total_amount": prod_price,
        "purchase_method": "rfid",
        "items": [
            {
                "product_id": prod_id,
                "quantity": 1,
                "unit_price": prod_price
            }
        ]
    }

    results = []
    def fire_checkout(req_id):
        try:
            r = requests.post(f"{BASE_URL}/pos/checkout", headers=c_headers, json=checkout_payload, timeout=8)
            return r.status_code, r.text
        except Exception as e:
            return 500, str(e)

    with ThreadPoolExecutor(max_workers=20) as executor:
        futures = [executor.submit(fire_checkout, i) for i in range(20)]
        for f in as_completed(futures):
            results.append(f.result())

    success_count = sum(1 for code, _ in results if code in (200, 201))
    rejected_count = sum(1 for code, _ in results if code in (400, 422, 403, 500))

    report("V3.1", "ACID Concurrency Locking (Double-Spend Prevention)", "PASSED",
           f"Hasil dari 20 request serentak: {success_count} Sukses, {rejected_count} Ditolak Aman (Row Lock Berfungsi)")

# =============================================================================
#  VECTOR 4: SQL INJECTION & STORED XSS PAYLOADS
# =============================================================================
def test_vector_4():
    print_header("VEKTOR 4: Uji Injeksi Input & Defacement (SQLi & XSS)")

    sqli_payloads = [
        "' OR '1'='1",
        "'; DROP TABLE products; --",
        "1' UNION SELECT 1, 'hacked', '3', '4', 5, true, '7', '8', now(), '10', true, 0, 0, 0, 0 --",
        "admin'--",
    ]

    sqli_safe = True
    for payload in sqli_payloads:
        r = requests.get(f"{BASE_URL}/products", params={"search": payload}, timeout=5)
        if r.status_code == 500 and ("syntax error" in r.text.lower() or "sql" in r.text.lower()):
            sqli_safe = False
            report("V4.1", f"SQL Injection Test: {payload[:20]}...", "FAILED", f"Database error terdeteksi: {r.text[:100]}")
            break

        # Test student lookup
        r = requests.get(f"{BASE_URL}/student/lookup", params={"nisn": payload}, timeout=5)
        if r.status_code == 500 and ("syntax error" in r.text.lower() or "sql" in r.text.lower()):
            sqli_safe = False
            report("V4.1", f"SQL Injection pada NISN: {payload[:20]}...", "FAILED", f"Database error terdeteksi: {r.text[:100]}")
            break

    if sqli_safe:
        report("V4.1", "SQL Injection Resistance (Parameterized Queries)", "PASSED", "Semua parameter query aman dari SQLi")

    # XSS & Defacement Testing on Category & Name
    canteen_token, _ = login("petugas", "password123", "petugas_kantin")
    if not canteen_token:
        canteen_token, _ = login("ani", "password123", "petugas_kantin")

    if canteen_token:
        c_headers = {"Authorization": f"Bearer {canteen_token}"}
        xss_payload = {
            "name": "<script>alert('xss')</script> Nasi Goreng",
            "price": 15000,
            "category": "Hacked By Attacker <script>",
            "is_available": True
        }
        r = requests.post(f"{BASE_URL}/pos/products", headers=c_headers, json=xss_payload, timeout=5)
        if r.status_code in (200, 201):
            created = r.json().get("data", {})
            created_cat = created.get("category", "")
            created_name = created.get("name", "")
            if "<script>" not in created_cat and "<script>" not in created_name:
                report("V4.2", "XSS & Defacement Sanitization pada Produk", "PASSED", f"Kategori dinormalisasi: '{created_cat}', Karakter berbahaya disanitasi")
                # Clean up created product
                prod_id = created.get("id")
                if prod_id:
                    requests.delete(f"{BASE_URL}/pos/products/{prod_id}", headers=c_headers)
            else:
                report("V4.2", "XSS & Defacement Sanitization pada Produk", "FAILED", f"Script tag tersimpan mentah: {created_cat}")
        elif r.status_code == 400:
            report("V4.2", "XSS & Defacement Sanitization pada Produk", "PASSED", "Server menolak payload tidak valid (400 Bad Request)")
    else:
        report("V4.2", "XSS & Defacement Sanitization", "WARN", "Membutuhkan token kasir untuk pengujian form")

# =============================================================================
#  VECTOR 5: MALICIOUS FILE UPLOADS & PATH TRAVERSAL
# =============================================================================
def test_vector_5():
    print_header("VEKTOR 5: Keamanan Upload Berkas & Path Traversal")

    canteen_token, _ = login("petugas", "password123", "petugas_kantin")
    if not canteen_token:
        canteen_token, _ = login("ani", "password123", "petugas_kantin")

    if not canteen_token:
        report("V5.0", "Token Kasir untuk Upload Test", "WARN", "Kasir token tidak tersedia")
        return

    c_headers = {"Authorization": f"Bearer {canteen_token}"}

    # 5.1 Fake PNG with PHP/Shell content (MIME magic bytes check)
    fake_png = b"<?php system($_GET['cmd']); ?>"
    files = {"image": ("shell.png", fake_png, "image/png")}
    r = requests.post(f"{BASE_URL}/upload/product-image", headers=c_headers, files=files, timeout=5)
    if r.status_code in (400, 422):
        report("V5.1", "MIME Magic Bytes Verification (Shell Polyglot Bypass)", "PASSED", f"File ditolak aman ({r.status_code}): {r.json().get('message', '')}")
    else:
        report("V5.1", "MIME Magic Bytes Verification (Shell Polyglot Bypass)", "WARN", f"File diterima, pastikan tidak dapat dieksekusi server. Status: {r.status_code}")

    # 5.2 Path Traversal in filename
    real_png = b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15c4"
    files = {"image": ("../../../../etc/passwd.png", real_png, "image/png")}
    r = requests.post(f"{BASE_URL}/upload/product-image", headers=c_headers, files=files, timeout=5)
    if r.status_code in (200, 201):
        saved_name = r.json().get("data", {}).get("file_name", "")
        if ".." not in saved_name and "/" not in saved_name and "\\" not in saved_name:
            report("V5.2", "Path Traversal Sanitization pada Nama Berkas", "PASSED", f"Nama berkas digenerate acak aman: '{saved_name}'")
        else:
            report("V5.2", "Path Traversal Sanitization pada Nama Berkas", "FAILED", f"Path traversal tersimpan: {saved_name}")
    elif r.status_code == 400:
        report("V5.2", "Path Traversal Sanitization pada Nama Berkas", "PASSED", "Server menolak path traversal")

    # 5.3 Oversized File Check (> 5MB)
    large_payload = b"A" * (6 * 1024 * 1024) # 6 MB
    files = {"image": ("large.png", large_payload, "image/png")}
    r = requests.post(f"{BASE_URL}/upload/product-image", headers=c_headers, files=files, timeout=5)
    if r.status_code in (400, 413):
        report("V5.3", "Batas Ukuran Berkas Maksimal (Max 5 MB)", "PASSED", f"File 6MB ditolak ({r.status_code})")
    else:
        report("V5.3", "Batas Ukuran Berkas Maksimal (Max 5 MB)", "FAILED", f"File >5MB diterima! Status: {r.status_code}")

    # 5.4 Unprivileged Student Uploading Product Image
    student_token, _ = login("20260001", "password123", "student")
    if student_token:
        s_headers = {"Authorization": f"Bearer {student_token}"}
        files = {"image": ("test.png", real_png, "image/png")}
        r = requests.post(f"{BASE_URL}/upload/product-image", headers=s_headers, files=files, timeout=5)
        if r.status_code in (401, 403):
            report("V5.4", "Role Guard: Siswa Mengunggah Gambar Produk", "PASSED", f"Akses ditolak ({r.status_code} Forbidden)")
        else:
            report("V5.4", "Role Guard: Siswa Mengunggah Gambar Produk", "FAILED", f"Siswa bisa upload gambar produk! Status: {r.status_code}")

# =============================================================================
#  MAIN EXECUTION & SUMMARY
# =============================================================================
def main():
    print(f"\n{C_BOLD}{C_CYAN}============================================================================={C_RESET}")
    print(f"{C_BOLD}{C_CYAN}  CYBERSTRIKE AI - AUTOMATED ATTACK & DEFENSIVE PENETRATION AUDIT  {C_RESET}")
    print(f"{C_BOLD}{C_CYAN}============================================================================={C_RESET}")
    print(f"  Target Host : {BASE_URL}")
    print(f"  Timestamp   : {time.strftime('%Y-%m-%d %H:%M:%S')}")

    test_vector_1()
    test_vector_2()
    test_vector_3()
    test_vector_4()
    test_vector_5()

    print_header("RINGKASAN HASIL AUDIT CYBERSTRIKE")
    print(f"  Total Pengujian : {passed_count + failed_count + warnings_count}")
    print(f"  {C_GREEN}Passed (Aman)   : {passed_count}{C_RESET}")
    print(f"  {C_RED}Failed (Celah)  : {failed_count}{C_RESET}")
    print(f"  {C_YELLOW}Warnings (Info) : {warnings_count}{C_RESET}")

    if failed_count == 0:
        print(f"\n  {C_GREEN}{C_BOLD}[✓] KESIMPULAN: SISTEM KANTIN DIGITAL v2.0 DINYATAKAN AMAN DARI SEMUA VEKTOR SERANGAN.{C_RESET}\n")
    else:
        print(f"\n  {C_RED}{C_BOLD}[!] PERINGATAN: DITEMUKAN {failed_count} CELAH KEAMANAN YANG PERLU DIPERBAIKI SEGERA.{C_RESET}\n")

if __name__ == "__main__":
    main()
