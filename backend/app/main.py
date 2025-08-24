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

# ✅ Enable CORS with explicit configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:8080", 
        "http://localhost:55692",  # Flutter web dev server
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:55692",
        "https://orbitco.in",      # Production domain
        "https://www.orbitco.in",
        "*"  # Allow all origins for now (remove in production)
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allow_headers=[
        "Accept",
        "Accept-Language", 
        "Content-Language",
        "Content-Type",
        "Authorization",
        "X-Requested-With",
        "Origin",
        "Access-Control-Request-Method",
        "Access-Control-Request-Headers"
    ],
    expose_headers=["*"],
    max_age=86400,  # Cache preflight for 24 hours
)


# ✅ Debug root endpoint
@app.get("/")
def root():
    return {"status": "ok"}

# ✅ Test CORS endpoint
@app.get("/test-cors")
def test_cors():
    return {"message": "CORS test successful", "timestamp": "2024-01-01"}

# ✅ Test OPTIONS endpoint
@app.options("/test-cors")
def test_cors_options():
    return {"message": "CORS preflight successful"}

# ✅ Global CORS handler for all routes
@app.middleware("http")
async def add_cors_headers(request, call_next):
    print(f"🌐 CORS middleware: {request.method} {request.url}")
    print(f"📋 Request headers: {dict(request.headers)}")
    
    response = await call_next(request)
    
    # Add CORS headers
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, PATCH, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Accept, Accept-Language, Content-Language, Content-Type, Authorization, X-Requested-With, Origin, Access-Control-Request-Method, Access-Control-Request-Headers"
    response.headers["Access-Control-Expose-Headers"] = "*"
    
    print(f"📤 Response headers: {dict(response.headers)}")
    return response

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
