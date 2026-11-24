import os

def find_file(filename, search_roots):
    found = []
    for root_dir in search_roots:
        if not os.path.exists(root_dir):
            continue
        for dirpath, dirnames, filenames in os.walk(root_dir):
            if filename in filenames:
                found.append(os.path.join(dirpath, filename))
    return found

filename = "aadhaar_1794892268547_85578ca5.jpg"
roots = [
    r"c:\Users\madhavan\Documents\NetBeansProjects\Road Assistance",
    r"C:\Users\madhavan\AppData\Local",
    r"C:\Users\madhavan\Downloads",
    r"C:\Users\madhavan\.gemini",
]

results = find_file(filename, roots)
print(f"Results for {filename}:")
for r in results:
    print(" ", r)

# Also search for "mechanic_documents" directory
print("\nSearching for 'mechanic_documents' folders:")
for root_dir in [r"c:\Users\madhavan\Documents\NetBeansProjects\Road Assistance", r"C:\Users\madhavan"]:
    if not os.path.exists(root_dir): continue
    for dirpath, dirnames, filenames in os.walk(root_dir):
        if "mechanic_documents" in dirnames:
            print("  Found directory:", os.path.join(dirpath, "mechanic_documents"))
