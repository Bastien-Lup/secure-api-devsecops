from fastapi import FastAPI, Request

app = FastAPI()

@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)

    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Cross-Origin-Resource-Policy"] = "same-origin"

    return response

@app.get("/")
def read_root():
    return {
        "status": "ok",
        "service": "secure-api"
    }

@app.get("/health")
def read_health():
    return {
        "status": "healthy"
    }