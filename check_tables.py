import sqlite3
import os

def check_tables():
    db_path = "./backend/app/crm_db.sqlite3"
    
    if not os.path.exists(db_path):
        print(f"❌ Database file not found: {db_path}")
        return
    
    print(f"📁 Using database: {db_path}")
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Get all table names
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = cursor.fetchall()
        
        print(f"\n📋 Tables in database:")
        for table in tables:
            print(f"  - {table[0]}")
        
        # Check each table structure
        for table in tables:
            table_name = table[0]
            print(f"\n🔍 Table: {table_name}")
            
            cursor.execute(f"PRAGMA table_info({table_name})")
            columns = cursor.fetchall()
            
            for col in columns:
                print(f"  - {col[1]} ({col[2]})")
            
            # Show sample data
            try:
                cursor.execute(f"SELECT * FROM {table_name} LIMIT 3")
                rows = cursor.fetchall()
                print(f"  Sample data: {len(rows)} rows")
                for i, row in enumerate(rows):
                    print(f"    Row {i+1}: {row}")
            except Exception as e:
                print(f"    Error reading data: {e}")
        
        conn.close()
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    check_tables()
