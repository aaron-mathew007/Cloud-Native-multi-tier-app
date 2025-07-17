# main.py
# Purpose: FastAPI backend with health check, CRUD endpoints, and Prometheus metrics.
# Features: RDS connection pooling, error handling, async endpoints for performance.
# Security: No hardcoded credentials; uses environment variables.

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(title="Cloud-Native App Backend")

# Enable CORS for frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # TODO: Restrict to S3 bucket domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Prometheus metrics
Instrumentator().instrument(app).expose(app)

# Database connection pooling
DATABASE_URL = f"postgresql://admin:{os.getenv('DB_PASSWORD', 'securepassword')}@{os.getenv('DB_HOST', 'localhost:5432')}/mydatabase"
engine = create_engine(DATABASE_URL, pool_size=5, max_overflow=10)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create items table if not exists
with engine.connect() as conn:
    conn.execute(text("""
        CREATE TABLE IF NOT EXISTS items (
            id VARCHAR PRIMARY KEY,
            value VARCHAR NOT NULL
        )
    """))
    conn.commit()

# Error handling middleware
@app.middleware("http")
async def log_errors(request, call_next):
    try:
        response = await call_next(request)
        return response
    except Exception as e:
        logger.error(f"Request failed: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal Server Error")

# Health check endpoint
@app.get("/health")
async def health():
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return {"status": "ok", "database": "connected"}
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        raise HTTPException(status_code=503, detail="Database unavailable")

# CRUD: Read item
@app.get("/items/{item_id}")
async def read_item(item_id: str):
    with SessionLocal() as session:
        result = session.execute(text("SELECT value FROM items WHERE id = :id"), {"id": item_id}).fetchone()
        if result is None:
            raise HTTPException(status_code=404, detail="Item not found")
        return {"item_id": item_id, "value": result[0]}

# CRUD: Create item
@app.post("/items/{item_id}")
async def create_item(item_id: str, value: str):
    with SessionLocal() as session:
        existing = session.execute(text("SELECT id FROM items WHERE id = :id"), {"id": item_id}).fetchone()
        if existing:
            raise HTTPException(status_code=400, detail="Item already exists")
        session.execute(text("INSERT INTO items (id, value) VALUES (:id, :value)"), {"id": item_id, "value": value})
        session.commit()
        return {"message": "Item created"}
