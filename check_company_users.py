import sqlite3
import os

def check_company_users():
    db_path = "./backend/app/crm_db.sqlite3"
    
    if not os.path.exists(db_path):
        print(f"❌ Database file not found: {db_path}")
        return
    
    print(f"📁 Using database: {db_path}")
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Check users table structure
        cursor.execute("PRAGMA table_info(users)")
        columns = cursor.fetchall()
        print(f"\n📋 Users table columns:")
        for col in columns:
            print(f"  - {col[1]} ({col[2]})")
        
        # Check all users for company_id=2
        cursor.execute("SELECT * FROM users WHERE company_id = 2")
        users = cursor.fetchall()
        print(f"\n👥 Users for company_id=2: {len(users)}")
        
        if users:
            print(f"\n📊 Users data for company_id=2:")
            for user in users:
                print(f"  User: {user}")
        else:
            print("  ❌ No users found for company_id=2")
        
        # Check all users in the users table
        cursor.execute("SELECT * FROM users")
        all_users = cursor.fetchall()
        print(f"\n👥 All users in database: {len(all_users)}")
        
        if all_users:
            print(f"\n📊 All users data:")
            for user in all_users:
                print(f"  User: {user}")
        
        # Check company_subscriptions for company_id=2
        cursor.execute("SELECT * FROM company_subscriptions WHERE company_id = 2")
        subscriptions = cursor.fetchall()
        print(f"\n💳 Subscriptions for company_id=2:")
        for sub in subscriptions:
            print(f"  Subscription: {sub}")
        
        conn.close()
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    check_company_users()
