import sqlite3
import os

def check_users():
    # Try to find the database file
    db_paths = [
        "./crm_db.sqlite3",
        "./backend/app/crm_db.sqlite3",
        "/root/CrmServer/crm_project/backend/app/crm_db.sqlite3"
    ]
    
    db_path = None
    for path in db_paths:
        if os.path.exists(path):
            db_path = path
            break
    
    if not db_path:
        print("❌ Database file not found!")
        return
    
    print(f"📁 Using database: {db_path}")
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Check if User table exists
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='User'")
        if not cursor.fetchone():
            print("❌ User table not found!")
            return
        
        # Check User table structure
        cursor.execute("PRAGMA table_info(User)")
        columns = cursor.fetchall()
        print(f"\n📋 User table columns:")
        for col in columns:
            print(f"  - {col[1]} ({col[2]})")
        
        # Check all users
        cursor.execute("SELECT * FROM User")
        users = cursor.fetchall()
        print(f"\n👥 Total users in database: {len(users)}")
        
        if users:
            print(f"\n📊 Users data:")
            for user in users:
                print(f"  User ID: {user[0]}, Company ID: {user[5] if len(user) > 5 else 'N/A'}")
        
        # Check Company table
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='Company'")
        if cursor.fetchone():
            cursor.execute("SELECT * FROM Company")
            companies = cursor.fetchall()
            print(f"\n🏢 Companies in database: {len(companies)}")
            for company in companies:
                print(f"  Company ID: {company[0]}, Name: {company[1]}")
        
        # Check CompanySubscription table
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='CompanySubscription'")
        if cursor.fetchone():
            cursor.execute("SELECT * FROM CompanySubscription")
            subscriptions = cursor.fetchall()
            print(f"\n💳 Subscriptions in database: {len(subscriptions)}")
            for sub in subscriptions:
                print(f"  Company ID: {sub[1]}, Status: {sub[2]}, Current Users: {sub[4] if len(sub) > 4 else 'N/A'}")
        
        conn.close()
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    check_users()
