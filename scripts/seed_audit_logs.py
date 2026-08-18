import json

def main():
    json_path = r'c:\Users\agust\Downloads\Kantin-Digital-v2.0\database_backup\json\audit_logs.json'
    out_path = r'c:\Users\agust\Downloads\Kantin-Digital-v2.0\database_backup\seed_audit_logs.sql'

    with open(json_path, 'r', encoding='utf-8') as f:
        logs = json.load(f)

    lines = []
    for l in logs:
        id_val = l.get('id')
        user_id = f"'{l.get('actor_id')}'" if l.get('actor_id') else 'NULL'
        action = l.get('action_type', 'GENERAL').replace("'", "''")
        entity_name = 'keuangan'
        entity_id = f"'{l.get('target_id')}'" if l.get('target_id') else 'NULL'
        old_data = json.dumps(l.get('old_value', {})).replace("'", "''")
        new_data = json.dumps(l.get('new_value', {})).replace("'", "''")
        ip = f"'{l.get('ip_address')}'" if l.get('ip_address') else 'NULL'
        created = f"'{l.get('created_at')}'" if l.get('created_at') else 'NOW()'

        lines.append(
            f"INSERT INTO public.audit_logs (id, user_id, action, entity_name, entity_id, old_data, new_data, ip_address, created_at) "
            f"VALUES ('{id_val}', {user_id}, '{action}', '{entity_name}', {entity_id}, '{old_data}'::jsonb, '{new_data}'::jsonb, {ip}, {created}) "
            f"ON CONFLICT (id) DO NOTHING;"
        )

    with open(out_path, 'w', encoding='utf-8') as out:
        out.write('\n'.join(lines))

    print(f"Generated {len(lines)} insert statements to {out_path}")

if __name__ == '__main__':
    main()
