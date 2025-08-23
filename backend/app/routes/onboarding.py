import json
from fastapi import APIRouter, status, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import date
from .. import schemas, models
from ..database import get_db

router = APIRouter(
    prefix="/api/onboarding",
    tags=["Onboarding"]
)

@router.post("/", status_code=status.HTTP_201_CREATED)
def save_onboarding(
    data: schemas.OnboardingSchema,
    db: Session = Depends(get_db)
):
    # Create company
    company = models.Company(
        company_name=data.company_name,
        company_size=data.company_size,
        industry="Default Industry",
        location="Default Location",
        crm_type=data.crm_type.lower().replace(" ", "_")
    )

    db.add(company)
    db.commit()
    db.refresh(company)
    
    # If a plan is selected, create subscription
    if hasattr(data, 'selected_plan_id') and data.selected_plan_id:
        try:
            # Get the selected plan
            plan = db.query(models.SubscriptionPlan).filter(
                models.SubscriptionPlan.id == data.selected_plan_id
            ).first()
            
            if not plan:
                raise HTTPException(status_code=400, detail="Selected plan not found")
            
            # Create subscription
            subscription = models.CompanySubscription(
                company_id=company.id,
                plan_id=plan.id,
                start_date=date.today(),
                max_users=plan.user_limit,
                current_users=0,
                billing_cycle="monthly" if plan.type == "subscription" else "one_time",
                next_billing_date=date.today() if plan.type == "subscription" else None,
                auto_renew=plan.type == "subscription"
            )
            
            db.add(subscription)
            db.commit()
            db.refresh(subscription)
            
            # Update company with subscription
            company.subscription_id = subscription.id
            db.commit()
            
        except Exception as e:
            # If subscription creation fails, still return company but log error
            print(f"Error creating subscription: {e}")
    
    return {
        "message": "Company created successfully",
        "company_id": company.id,
        "crm_type": company.crm_type,
        "subscription_created": hasattr(data, 'selected_plan_id') and data.selected_plan_id is not None
    }


@router.get("/plans")
def get_available_plans(db: Session = Depends(get_db)):
    """Get available subscription plans for onboarding"""
    plans = db.query(models.SubscriptionPlan).filter(
        models.SubscriptionPlan.is_active == True
    ).all()
    
    return {
        "plans": [
            {
                "id": plan.id,
                "name": plan.name,
                "type": plan.type,
                "price_monthly": plan.price_monthly,
                "price_yearly": plan.price_yearly,
                "price_one_time": plan.price_one_time,
                "user_limit": plan.user_limit,
                "additional_user_price": plan.additional_user_price,
                "description": plan.description,
                "features": json.loads(plan.features) if plan.features else []
            }
            for plan in plans
        ]
    }

