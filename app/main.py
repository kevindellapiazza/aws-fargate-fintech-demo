from fastapi import FastAPI
import random

# Initialize FastAPI with metadata for Swagger UI
app = FastAPI(
    title="FinTech Credit Score API",
    description="A microservice for real-time credit risk assessment running on AWS Fargate.",
    version="1.0.0"
)

@app.get("/")
def read_root():
    """Root endpoint for basic connectivity check."""
    return {"status": "online", "service": "Fargate FinTech Core"}

@app.get("/health")
def health_check():
    """
    Health Check endpoint used by ECS/Load Balancer.
    Returns 200 OK if the service is alive.
    """
    return {"status": "healthy"}

@app.get("/credit-score/{user_id}")
def get_credit_score(user_id: str):
    """
    Simulates a complex business logic calculation for credit scoring.
    In a real scenario, this would query a Database or external Bureau API.
    """
    # Business Logic Simulation
    score = random.randint(300, 850)
    risk_level = "LOW" if score > 700 else "HIGH"
    
    return {
        "user_id": user_id,
        "credit_score": score,
        "risk_assessment": risk_level,
        "approved": score > 600
    }