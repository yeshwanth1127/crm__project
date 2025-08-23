from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os

# ✅ Load environment variables from .env file in root directory
dotenv_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../.env"))
load_dotenv(dotenv_path)

print("✅ SECRET_KEY loaded in main.py:", os.getenv("SECRET_KEY"))

# ✅ Local module imports
from .routes import sales_crm, onboarding, register, login, subscription
from .database import Base, engine

# ✅ Initialize FastAPI app
app = FastAPI()

# ✅ Enable CORS (you can restrict origins later for production)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ✅ Debug root endpoint
@app.get("/")
def root():
    return {"status": "ok"}

# ✅ Print all routes for debugging
@app.on_event("startup")
def log_routes():
    for route in app.routes:
        print(f"🔍 Route: {route.path}")

# ✅ Register routers
app.include_router(onboarding.router)
app.include_router(register.router)
app.include_router(login.router)
app.include_router(sales_crm.router, prefix="/api/sales", tags=["Sales CRM"])
app.include_router(subscription.router, prefix="/api", tags=["Subscription"])
