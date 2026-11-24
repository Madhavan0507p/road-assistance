import mysql.connector

conn = mysql.connector.connect(host='localhost', user='root', password='', database='road_assistance_db')
cur = conn.cursor(dictionary=True)

cur.execute("SELECT * FROM mechanics WHERE mechanic_code = 'MEC042' OR workshop_name LIKE '%Godwin%'")
rows = cur.fetchall()
print(f"Found {len(rows)} rows for Godwin Garage / MEC042:")
for r in rows:
    for k, v in r.items():
        if any(term in k.lower() for term in ['proof', 'doc', 'aadhaar', 'license', 'cert', 'image', 'photo', 'file', 'id']):
            print(f"  {k}: {v}")

print("\n--- All columns in mechanics table ---")
cur.execute("DESCRIBE mechanics")
for col in cur.fetchall():
    if any(term in col['Field'].lower() for term in ['proof', 'doc', 'aadhaar', 'license', 'cert', 'image', 'photo', 'file', 'id', 'path']):
        print(f"  {col['Field']} ({col['Type']})")

cur.close()
conn.close()
