from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import date, datetime
from ..database import get_db
from .. import models, schemas
from ..auth import get_current_user
from ..models import CompanySubscription

router = APIRouter(prefix="/subscription", tags=["subscription"])

# ===================== SUBSCRIPTION PLANS =====================

@router.get("/plans", response_model=List[schemas.SubscriptionPlanResponse])
def get_subscription_plans(db: Session = Depends(get_db)):
    """Get all active subscription plans"""
    plans = db.query(models.SubscriptionPlan).filter(models.SubscriptionPlan.is_active == True).all()
    return plans


@router.get("/plans/{plan_id}", response_model=schemas.SubscriptionPlanResponse)
def get_subscription_plan(plan_id: int, db: Session = Depends(get_db)):
    """Get a specific subscription plan by ID"""
    plan = db.query(models.SubscriptionPlan).filter(models.SubscriptionPlan.id == plan_id).first()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")
    return plan


@router.post("/plans", response_model=schemas.SubscriptionPlanResponse)
def create_subscription_plan(plan: schemas.SubscriptionPlanCreate, db: Session = Depends(get_db)):
    """Create a new subscription plan (Admin only)"""
    # Check if plan name already exists
    existing_plan = db.query(models.SubscriptionPlan).filter(models.SubscriptionPlan.name == plan.name).first()
    if existing_plan:
        raise HTTPException(status_code=400, detail="Plan name already exists")
    
    db_plan = models.SubscriptionPlan(**plan.dict())
    db.add(db_plan)
    db.commit()
    db.refresh(db_plan)
    return db_plan


# ===================== COMPANY SUBSCRIPTIONS =====================

@router.post("/subscribe", response_model=schemas.CompanySubscriptionResponse)
def subscribe_company(
    subscription: schemas.CompanySubscriptionCreate,
    db: Session = Depends(get_db)
):
    """Subscribe a company to a plan"""
    # Verify plan exists
    plan = db.query(models.SubscriptionPlan).filter(models.SubscriptionPlan.id == subscription.plan_id).first()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")
    
    # Check if company already has an active subscription
    existing_sub = db.query(models.CompanySubscription).filter(
        models.CompanySubscription.company_id == subscription.company_id,
        models.CompanySubscription.status == "active"
    ).first()
    
    if existing_sub:
        raise HTTPException(status_code=400, detail="Company already has an active subscription")
    
    # Create subscription
    db_subscription = models.CompanySubscription(**subscription.dict())
    db.add(db_subscription)
    db.commit()
    db.refresh(db_subscription)
    
    # Update company with subscription
    company = db.query(models.Company).filter(models.Company.id == subscription.company_id).first()
    if company:
        company.subscription_id = db_subscription.id
        db.commit()
    
    return db_subscription


@router.get("/company/{company_id}", response_model=schemas.CompanySubscriptionResponse)
def get_company_subscription(company_id: int, db: Session = Depends(get_db)):
    """Get company's current subscription"""
    subscription = db.query(models.CompanySubscription).filter(
        models.CompanySubscription.company_id == company_id,
        models.CompanySubscription.status == "active"
    ).first()
    
    if not subscription:
        raise HTTPException(status_code=404, detail="No active subscription found")
    
    return subscription


@router.put("/company/{company_id}/cancel")
def cancel_subscription(company_id: int, db: Session = Depends(get_db)):
    """Cancel company's subscription"""
    subscription = db.query(models.CompanySubscription).filter(
        models.CompanySubscription.company_id == company_id,
        models.CompanySubscription.status == "active"
    ).first()
    
    if not subscription:
        raise HTTPException(status_code=404, detail="No active subscription found")
    
    subscription.status = "cancelled"
    subscription.auto_renew = False
    db.commit()
    
    return {"message": "Subscription cancelled successfully"}


# ===================== BILLING =====================

@router.post("/billing", response_model=schemas.BillingHistoryResponse)
def create_billing_record(billing: schemas.BillingHistoryCreate, db: Session = Depends(get_db)):
    """Create a billing record"""
    db_billing = models.BillingHistory(**billing.dict())
    db.add(db_billing)
    db.commit()
    db.refresh(db_billing)
    return db_billing


@router.get("/billing/{company_id}", response_model=List[schemas.BillingHistoryResponse])
def get_company_billing_history(company_id: int, db: Session = Depends(get_db)):
    """Get company's billing history"""
    billing_records = db.query(models.BillingHistory).filter(
        models.BillingHistory.company_id == company_id
    ).order_by(models.BillingHistory.billing_date.desc()).all()
    
    return billing_records


# ===================== FEATURES =====================

@router.get("/features", response_model=List[schemas.PlanFeatureResponse])
def get_all_features(db: Session = Depends(get_db)):
    """Get all available features"""
    features = db.query(models.PlanFeature).all()
    return features


@router.get("/company/{company_id}/features")
def get_company_features(
    company_id: int, 
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get features available to a company based on their subscription"""
    # Verify the user belongs to the requested company
    if current_user.company_id != company_id:
        raise HTTPException(status_code=403, detail="Access denied to this company's data")
    
    # Get company's subscription
    subscription = db.query(models.CompanySubscription).filter(
        models.CompanySubscription.company_id == company_id,
        models.CompanySubscription.status == "active"
    ).first()
    
    # Count actual users in the database for this company
    actual_user_count = db.query(models.User).filter(models.User.company_id == company_id).count()
    
    if not subscription:
        # Return core features only
        core_features = db.query(models.PlanFeature).filter(models.PlanFeature.is_core == True).all()
        return {
            "features": [feature.feature_key for feature in core_features],
            "subscription_status": "no_subscription",
            "plan_name": "Launch Plan",
            "user_limit": 3,
            "current_users": actual_user_count
        }
    
    # Get plan features
    plan = db.query(models.SubscriptionPlan).filter(models.SubscriptionPlan.id == subscription.plan_id).first()
    
    # Parse features from JSON string
    import json
    try:
        plan_features = json.loads(plan.features) if plan.features else []
    except (json.JSONDecodeError, TypeError):
        plan_features = []
    
    return {
        "features": plan_features,
        "subscription_status": subscription.status,
        "plan_name": plan.name,
        "user_limit": subscription.max_users,
        "current_users": actual_user_count
    }


# ===================== UTILITY ENDPOINTS =====================

@router.post("/update-user-count/{company_id}")
def update_user_count(company_id: int, db: Session = Depends(get_db)):
    try:
        # Get actual user count from User table
        actual_user_count = db.query(models.User).filter(models.User.company_id == company_id).count()
        
        # Update CompanySubscription table
        subscription = db.query(CompanySubscription).filter(CompanySubscription.company_id == company_id).first()
        if subscription:
            subscription.current_users = actual_user_count
            db.commit()
        
        return {"message": "User count updated", "current_users": actual_user_count}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to update user count: {str(e)}")

@router.post("/initialize-plans")
def initialize_default_plans(db: Session = Depends(get_db)):
    """Initialize default subscription plans (Admin only)"""
    
    # Check if plans already exist
    existing_plans = db.query(models.SubscriptionPlan).count()
    if existing_plans > 0:
        return {"message": "Plans already initialized"}
    
    # Default subscription plans
    subscription_plans = [
        {
            "name": "Launch",
            "type": "subscription",
            "price_monthly": 499.0,
            "price_yearly": 4999.0,
            "user_limit": 3,
            "additional_user_price": 199.0,
            "description": "Perfect for small businesses starting with CRM",
            "features": [
                "contact_management", "lead_management", "task_tracking", 
                "basic_dashboard", "limited_custom_fields", "mobile_access", 
                "email_support", "ssl_security", "vps_hosting", "user_management"
            ]
        },
        {
            "name": "Accelerate",
            "type": "subscription",
            "price_monthly": 1999.0,
            "price_yearly": 22000.0,
            "user_limit": 12,
            "additional_user_price": 199.0,
            "description": "Advanced CRM for growing teams",
            "features": [
                "contact_management", "lead_management", "task_tracking", 
                "basic_dashboard", "limited_custom_fields", "mobile_access", 
                "email_support", "ssl_security", "vps_hosting",
                "lead_pipeline", "visual_sales_pipeline", "email_sms_notifications",
                "custom_dashboards", "customer_segments", "custom_fields",
                "support_tickets", "role_based_access", "customer_notes",
                "email_sms_integration", "team_chat", "auto_backups",
                "user_management"
            ]
        },
        {
            "name": "Scale",
            "type": "subscription",
            "price_monthly": 3999.0,
            "price_yearly": 45000.0,
            "user_limit": 30,
            "additional_user_price": 149.0,
            "description": "Enterprise-grade CRM solution",
            "features": [
                "contact_management", "lead_management", "task_tracking", 
                "basic_dashboard", "limited_custom_fields", "mobile_access", 
                "email_support", "ssl_security", "vps_hosting",
                "lead_pipeline", "visual_sales_pipeline", "email_sms_notifications",
                "custom_dashboards", "customer_segments", "custom_fields",
                "support_tickets", "role_based_access", "customer_notes",
                "email_sms_integration", "team_chat", "auto_backups",
                "campaign_management", "custom_lead_stages", "bulk_messaging",
                "advanced_analytics", "file_uploads", "conversation_logs",
                "role_management", "user_management", "activity_timeline",
                "notification_center", "custom_domain"
            ]
        }
    ]
    
    # Self-hosted plans
    self_hosted_plans = [
        {
            "name": "Essentials",
            "type": "self_hosted",
            "price_one_time": 9999.0,
            "user_limit": 3,
            "description": "Core CRM features for self-hosted deployment",
            "features": [
                "contact_management", "lead_management", "task_tracking",
                "follow_up_reminders", "activity_logs", "admin_salesman_roles",
                "custom_branding", "data_ownership"
            ]
        },
        {
            "name": "Pro Deploy",
            "type": "self_hosted",
            "price_one_time": 22999.0,
            "user_limit": 25,
            "description": "Professional CRM with advanced features",
            "features": [
                "contact_management", "lead_management", "task_tracking",
                "follow_up_reminders", "activity_logs", "admin_salesman_roles",
                "custom_branding", "data_ownership", "role_based_access",
                "support_module", "custom_fields", "file_uploads",
                "enhanced_analytics", "sms_email_notifications", "training_videos"
            ]
        },
        {
            "name": "Enterprise",
            "type": "self_hosted",
            "price_one_time": 33999.0,
            "user_limit": 50,
            "description": "Enterprise-grade CRM with full customization",
            "features": [
                "contact_management", "lead_management", "task_tracking",
                "follow_up_reminders", "activity_logs", "admin_salesman_roles",
                "custom_branding", "data_ownership", "role_based_access",
                "support_module", "custom_fields", "file_uploads",
                "enhanced_analytics", "sms_email_notifications", "training_videos",
                "white_labeling", "rest_api", "campaign_management",
                "crm_reports", "role_audit", "data_segmentation",
                "custom_workflows", "lifetime_license", "dedicated_manager"
            ]
        }
    ]
    
    # Add all plans
    all_plans = subscription_plans + self_hosted_plans
    
    for plan_data in all_plans:
        db_plan = models.SubscriptionPlan(**plan_data)
        db.add(db_plan)
    
    db.commit()
    
    return {"message": f"Initialized {len(all_plans)} subscription plans"}


@router.post("/initialize-features")
def initialize_default_features(db: Session = Depends(get_db)):
    """Initialize default plan features (Admin only)"""
    
    # Check if features already exist
    existing_features = db.query(models.PlanFeature).count()
    if existing_features > 0:
        return {"message": "Features already initialized"}
    
    # Default features
    features = [
        # Core features (available in all plans)
        {"feature_key": "contact_management", "feature_name": "Contact Management", "category": "sales", "is_core": True},
        {"feature_key": "lead_management", "feature_name": "Lead Management", "category": "sales", "is_core": True},
        {"feature_key": "task_tracking", "feature_name": "Task Tracking", "category": "general", "is_core": True},
        {"feature_key": "basic_dashboard", "feature_name": "Basic Dashboard", "category": "general", "is_core": True},
        
        # Advanced features
        {"feature_key": "lead_pipeline", "feature_name": "Lead Pipeline", "category": "sales"},
        {"feature_key": "visual_sales_pipeline", "feature_name": "Visual Sales Pipeline", "category": "sales"},
        {"feature_key": "support_tickets", "feature_name": "Support Tickets", "category": "support"},
        {"feature_key": "campaign_management", "feature_name": "Campaign Management", "category": "marketing"},
        {"feature_key": "advanced_analytics", "feature_name": "Advanced Analytics", "category": "general"},
        {"feature_key": "custom_workflows", "feature_name": "Custom Workflows", "category": "general"},
        {"feature_key": "white_labeling", "feature_name": "White Labeling", "category": "general"},
        {"feature_key": "rest_api", "feature_name": "REST API Access", "category": "general"},
    ]
    
    for feature_data in features:
        db_feature = models.PlanFeature(**feature_data)
        db.add(db_feature)
    
    db.commit()
    
    return {"message": f"Initialized {len(features)} features"}
