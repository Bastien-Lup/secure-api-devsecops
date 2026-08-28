from fastapi import FastAPI

app = FastAPI()


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

@app.get("/calculate")
def calculate(expression: str):
    return {
        "result": eval(expression)
    }