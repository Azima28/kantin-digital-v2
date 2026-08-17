import subprocess
import json

def run_sql(query):
    cmd = [r"C:\laragon\bin\postgresql\pgsql\bin\psql.exe", "-U", "postgres", "-p", "5432", "-d", "kantin_digital", "-c", query]
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print("[ERROR SQL]", res.stderr)
    return res.stdout

def main():
    print("[*] Updating product image URLs...")
    run_sql("UPDATE public.products SET image_url = 'http://127.0.0.1:8000/uploads/products/product_1782788131058.jpeg' WHERE LOWER(name) LIKE '%nasi%' OR LOWER(name) LIKE '%nasgor%';")
    run_sql("UPDATE public.products SET image_url = 'http://127.0.0.1:8000/uploads/products/product_1784618774969.jpg' WHERE LOWER(name) LIKE '%jeruk%' OR LOWER(name) LIKE '%teh%';")
    run_sql("UPDATE public.products SET image_url = 'http://127.0.0.1:8000/uploads/products/product_1782113627202.png' WHERE LOWER(name) LIKE '%aqua%';")
    run_sql("UPDATE public.products SET image_url = 'http://127.0.0.1:8000/uploads/products/product_1782113603899.png' WHERE LOWER(name) LIKE '%cemil%';")
    run_sql("UPDATE public.products SET image_url = 'http://127.0.0.1:8000/uploads/products/product_1782113671563.png' WHERE LOWER(name) LIKE '%dimsum%' OR LOWER(name) LIKE '%hot%';")
    run_sql("UPDATE public.products SET image_url = 'http://127.0.0.1:8000/uploads/products/product_1782121331830.png' WHERE LOWER(name) LIKE '%tanggo%';")
    run_sql("UPDATE public.products SET image_url = 'http://127.0.0.1:8000/uploads/products/product_1782113568181.png' WHERE LOWER(name) LIKE '%aaa%';")

    print("[*] Fetching all orders...")
    out = run_sql("SELECT json_agg(o) FROM (SELECT id, total_amount, status FROM public.orders) o;")

    # Parse json from psql
    lines = out.strip().split('\n')
    json_str = ""
    for line in lines:
        if line.strip().startswith('[') or json_str:
            json_str += line.strip()

    if not json_str:
        print("[WARN] No orders json parsed, trying direct query...")

    # Clean existing order items
    run_sql("DELETE FROM public.order_items;")

    # Seed order items for all orders
    sql_seed = """
    INSERT INTO public.order_items (order_id, product_name, quantity, price)
    SELECT id, 'nasgor goreng pedes', 1, 12000 FROM public.orders WHERE total_amount = 12000;

    INSERT INTO public.order_items (order_id, product_name, quantity, price)
    SELECT id, 'nasgor goreng pedes', 2, 12000 FROM public.orders WHERE total_amount = 24000;

    INSERT INTO public.order_items (order_id, product_name, quantity, price)
    SELECT id, 'aaa', 1, 1111 FROM public.orders WHERE total_amount = 1111;

    INSERT INTO public.order_items (order_id, product_name, quantity, price)
    SELECT id, 'cemil', 1, 10231 FROM public.orders WHERE total_amount = 10231;

    INSERT INTO public.order_items (order_id, product_name, quantity, price)
    SELECT id, 'aqua', 1, 3000 FROM public.orders WHERE total_amount = 3000;

    INSERT INTO public.order_items (order_id, product_name, quantity, price)
    SELECT id, 'aaa', 1, 1111 FROM public.orders WHERE total_amount = 3111;

    INSERT INTO public.order_items (order_id, product_name, quantity, price)
    SELECT id, 'aqua', 1, 2000 FROM public.orders WHERE total_amount = 3111;

    INSERT INTO public.order_items (order_id, product_name, quantity, price)
    SELECT id, 'Dimsum Goreng Hot', 1, 5000 FROM public.orders WHERE total_amount = 5555;

    INSERT INTO public.order_items (order_id, product_name, quantity, price)
    SELECT id, 'nasgor goreng pedes', 20, 12000 FROM public.orders WHERE total_amount = 285000;

    INSERT INTO public.order_items (order_id, product_name, quantity, price)
    SELECT id, 'nasgor goreng pedes', 9, 12000 FROM public.orders WHERE total_amount = 111100;
    """
    run_sql(sql_seed)

    # Check count
    cnt = run_sql("SELECT count(*) FROM public.order_items;")
    print("[SUCCESS] Order items count:", cnt.strip())

if __name__ == "__main__":
    main()
