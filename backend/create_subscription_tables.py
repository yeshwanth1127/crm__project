#!/usr/bin/env python3
"""
Database migration script to create subscription-related tables
"""

import sqlite3
import os
from datetime import datetime

def create_subscription_tables():
    """Create all subscription-related tables"""
    
    # Get the database path - create tables in backend directory where app expects them
    db_path = os.path.join(os.path.dirname(__file__), 'app', 'crm_db.sqlite3')
    
    # Connect to the database
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        print("🔧 Creating subscription tables...")
        
        # Create subscription_plans table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS subscription_plans (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE,
                type TEXT NOT NULL,
                price_monthly REAL,
                price_yearly REAL,
                price_one_time REAL,
                user_limit INTEGER NOT NULL,
                additional_user_price REAL,
                description TEXT,
                features TEXT NOT NULL,
                is_active BOOLEAN DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        print("✅ Created subscription_plans table")
        
        # Create company_subscriptions table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS company_subscriptions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                company_id INTEGER NOT NULL,
                plan_id INTEGER NOT NULL,
                status TEXT NOT NULL DEFAULT 'active',
                start_date DATE NOT NULL,
                end_date DATE,
                current_users INTEGER DEFAULT 0,
                max_users INTEGER NOT NULL,
                billing_cycle TEXT,
                next_billing_date DATE,
                auto_renew BOOLEAN DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (company_id) REFERENCES companies (id),
                FOREIGN KEY (plan_id) REFERENCES subscription_plans (id)
            )
        ''')
        print("✅ Created company_subscriptions table")
        
        # Create billing_history table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS billing_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                company_id INTEGER NOT NULL,
                subscription_id INTEGER NOT NULL,
                amount REAL NOT NULL,
                currency TEXT DEFAULT 'INR',
                billing_date DATE NOT NULL,
                status TEXT NOT NULL,
                payment_method TEXT,
                transaction_id TEXT,
                invoice_url TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (company_id) REFERENCES companies (id),
                FOREIGN KEY (subscription_id) REFERENCES company_subscriptions (id)
            )
        ''')
        print("✅ Created billing_history table")
        
        # Create plan_features table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS plan_features (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                feature_key TEXT NOT NULL UNIQUE,
                feature_name TEXT NOT NULL,
                description TEXT,
                category TEXT NOT NULL,
                is_core BOOLEAN DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        print("✅ Created plan_features table")
        
        # Add subscription_id column to companies table if it doesn't exist
        try:
            cursor.execute('ALTER TABLE companies ADD COLUMN subscription_id INTEGER REFERENCES company_subscriptions(id)')
            print("✅ Added subscription_id column to companies table")
        except sqlite3.OperationalError:
            print("ℹ️  subscription_id column already exists in companies table")
        
        # Commit changes
        conn.commit()
        print("✅ All subscription tables created successfully!")
        
        # Initialize default plans
        initialize_default_plans(cursor)
        
        # Initialize default features
        initialize_default_features(cursor)
        
        conn.commit()
        print("✅ Default plans and features initialized!")
        
    except Exception as e:
        print(f"❌ Error creating tables: {e}")
        conn.rollback()
        raise
    finally:
        conn.close()

def initialize_default_plans(cursor):
    """Initialize default subscription plans"""
    
    # Check if plans already exist
    cursor.execute('SELECT COUNT(*) FROM subscription_plans')
    if cursor.fetchone()[0] > 0:
        print("ℹ️  Plans already exist, skipping initialization")
        return
    
    # Default subscription plans
    subscription_plans = [
        {
            'name': 'Launch',
            'type': 'subscription',
            'price_monthly': 499.0,
            'price_yearly': 4999.0,
            'user_limit': 3,
            'additional_user_price': 199.0,
            'description': 'Perfect for small businesses starting with CRM',
            'features': '["contact_management", "lead_management", "task_tracking", "basic_dashboard", "limited_custom_fields", "mobile_access", "email_support", "ssl_security", "vps_hosting"]'
        },
        {
            'name': 'Accelerate',
            'type': 'subscription',
            'price_monthly': 1999.0,
            'price_yearly': 22000.0,
            'user_limit': 12,
            'additional_user_price': 199.0,
            'description': 'Advanced CRM for growing teams',
            'features': '["contact_management", "lead_management", "task_tracking", "basic_dashboard", "limited_custom_fields", "mobile_access", "email_support", "ssl_security", "vps_hosting", "lead_pipeline", "visual_sales_pipeline", "email_sms_notifications", "custom_dashboards", "customer_segments", "custom_fields", "support_tickets", "role_based_access", "customer_notes", "email_sms_integration", "team_chat", "auto_backups"]'
        },
        {
            'name': 'Scale',
            'type': 'subscription',
            'price_monthly': 3999.0,
            'price_yearly': 45000.0,
            'user_limit': 30,
            'additional_user_price': 149.0,
            'description': 'Enterprise-grade CRM solution',
            'features': '["contact_management", "lead_management", "task_tracking", "basic_dashboard", "limited_custom_fields", "mobile_access", "email_support", "ssl_security", "vps_hosting", "lead_pipeline", "visual_sales_pipeline", "email_sms_notifications", "custom_dashboards", "customer_segments", "custom_fields", "support_tickets", "role_based_access", "customer_notes", "email_sms_integration", "team_chat", "auto_backups", "campaign_management", "custom_lead_stages", "bulk_messaging", "advanced_analytics", "file_uploads", "conversation_logs", "role_management", "user_management", "activity_timeline", "notification_center", "custom_domain"]'
        }
    ]
    
    # Self-hosted plans
    self_hosted_plans = [
        {
            'name': 'Essentials',
            'type': 'self_hosted',
            'price_one_time': 9999.0,
            'user_limit': 3,
            'description': 'Core CRM features for self-hosted deployment',
            'features': '["contact_management", "lead_management", "task_tracking", "follow_up_reminders", "activity_logs", "admin_salesman_roles", "custom_branding", "data_ownership"]'
        },
        {
            'name': 'Pro Deploy',
            'type': 'self_hosted',
            'price_one_time': 22999.0,
            'user_limit': 25,
            'description': 'Professional CRM with advanced features',
            'features': '["contact_management", "lead_management", "task_tracking", "follow_up_reminders", "activity_logs", "admin_salesman_roles", "custom_branding", "data_ownership", "role_based_access", "support_module", "custom_fields", "file_uploads", "enhanced_analytics", "sms_email_notifications", "training_videos"]'
        },
        {
            'name': 'Enterprise',
            'type': 'self_hosted',
            'price_one_time': 33999.0,
            'user_limit': 50,
            'description': 'Enterprise-grade CRM with full customization',
            'features': '["contact_management", "lead_management", "task_tracking", "follow_up_reminders", "activity_logs", "admin_salesman_roles", "custom_branding", "data_ownership", "role_based_access", "support_module", "custom_fields", "file_uploads", "enhanced_analytics", "sms_email_notifications", "training_videos", "white_labeling", "rest_api", "campaign_management", "crm_reports", "role_audit", "data_segmentation", "custom_workflows", "lifetime_license", "dedicated_manager"]'
        }
    ]
    
    # Add all plans
    all_plans = subscription_plans + self_hosted_plans
    
    for plan_data in all_plans:
        cursor.execute('''
            INSERT INTO subscription_plans 
            (name, type, price_monthly, price_yearly, price_one_time, user_limit, additional_user_price, description, features)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            plan_data['name'],
            plan_data['type'],
            plan_data.get('price_monthly'),
            plan_data.get('price_yearly'),
            plan_data.get('price_one_time'),
            plan_data['user_limit'],
            plan_data.get('additional_user_price'),
            plan_data['description'],
            plan_data['features']
        ))
    
    print(f"✅ Initialized {len(all_plans)} subscription plans")

def initialize_default_features(cursor):
    """Initialize default plan features"""
    
    # Check if features already exist
    cursor.execute('SELECT COUNT(*) FROM plan_features')
    if cursor.fetchone()[0] > 0:
        print("ℹ️  Features already exist, skipping initialization")
        return
    
    # Default features
    features = [
        ('contact_management', 'Contact Management', 'Core contact and lead management features', 'sales', True),
        ('lead_management', 'Lead Management', 'Lead tracking and pipeline management', 'sales', True),
        ('task_tracking', 'Task Tracking', 'Basic task and follow-up management', 'general', True),
        ('basic_dashboard', 'Basic Dashboard', 'Simple analytics and overview dashboard', 'general', True),
        ('lead_pipeline', 'Lead Pipeline', 'Advanced lead pipeline management', 'sales', False),
        ('visual_sales_pipeline', 'Visual Sales Pipeline', 'Visual representation of sales stages', 'sales', False),
        ('support_tickets', 'Support Tickets', 'Customer support ticket system', 'support', False),
        ('campaign_management', 'Campaign Management', 'Marketing campaign management', 'marketing', False),
        ('advanced_analytics', 'Advanced Analytics', 'Comprehensive analytics and reporting', 'general', False),
        ('custom_workflows', 'Custom Workflows', 'Customizable business workflows', 'general', False),
        ('white_labeling', 'White Labeling', 'Custom branding and white-label options', 'general', False),
        ('rest_api', 'REST API Access', 'API access for integrations', 'general', False),
    ]
    
    for feature in features:
        cursor.execute('''
            INSERT INTO plan_features (feature_key, feature_name, description, category, is_core)
            VALUES (?, ?, ?, ?, ?)
        ''', feature)
    
    print(f"✅ Initialized {len(features)} features")

if __name__ == "__main__":
    create_subscription_tables()
    print("🎉 Database migration completed successfully!")
