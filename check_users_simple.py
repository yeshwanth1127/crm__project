import sqlite3

def check_users():
    try:
        conn = sqlite3.connect("./backend/app/crm_db.sqlite3")
        cursor = conn.cursor()
        
        # Check users table
        cursor.execute("SELECT id, full_name, email, company_id FROM users")
        users = cursor.fetchall()
        
        print(f"Total users: {len(users)}")
        for user in users:
            print(f"User ID: {user[0]}, Name: {user[1]}, Email: {user[2]}, Company ID: {user[3]}")
        
        # Check company_subscriptions
        cursor.execute("SELECT company_id, current_users, max_users FROM company_subscriptions")
        subs = cursor.fetchall()
        
        print(f"\nSubscriptions:")
        for sub in subs:
            print(f"Company ID: {sub[0]}, Current Users: {sub[1]}, Max Users: {sub[2]}")
        
        conn.close()
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_users()
