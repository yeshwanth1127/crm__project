import os
from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
from .routes import sales_crm, subscription, onboarding, login, register
from . import auth

# Load environment variables
load_dotenv()

# Create FastAPI app
app = FastAPI(title="CRM API", version="1.0.0")

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:55692",  # Flutter web dev server
        "http://localhost:49301",  # Current Flutter dev server port
        "https://orbitco.in",
        "https://www.orbitco.in",
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["*"],
    max_age=3600,
)

# Global CORS handler to ensure headers are always present
@app.middleware("http")
async def add_cors_headers(request: Request, call_next):
    response = await call_next(request)
    
    # Get the origin from the request
    origin = request.headers.get("origin")
    
    # Check if origin is in allowed list
    allowed_origins = [
        "http://localhost:3000",
        "http://localhost:55692",
        "http://localhost:49301",
        "https://orbitco.in",
        "https://www.orbitco.in",
    ]
    
    if origin in allowed_origins:
        response.headers["Access-Control-Allow-Origin"] = origin
    else:
        response.headers["Access-Control-Allow-Origin"] = "*"
    
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, PATCH, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "*"
    response.headers["Access-Control-Expose-Headers"] = "*"
    response.headers["Access-Control-Allow-Credentials"] = "true"
    
    return response

# Include routers
app.include_router(login.router, tags=["Authentication"])
app.include_router(register.router, tags=["Authentication"])
app.include_router(sales_crm.router, prefix="/sales", tags=["Sales CRM"])
app.include_router(subscription.router, prefix="/subscription", tags=["Subscription"])
app.include_router(onboarding.router, prefix="/onboarding", tags=["Onboarding"])

@app.get("/")
async def root():
    return {"message": "CRM API is running"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
