from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)

def test_root():
    response = client.get("/")

    assert response.status_code == 200
    assert response.json() == {
        "status": "ok",
        "service": "secure-api"
    }

def test_health():
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}

def test_security_headers():
    response = client.get("/")

    assert response.status_code == 200
    assert response.headers["x-content-type-options"] == "nosniff"
    assert response.headers["cross-origin-resource-policy"] == "same-origin"

def test_security_headers_on_404():
    response = client.get("/does-not-exist")

    assert response.status_code == 404
    assert response.headers["x-content-type-options"] == "nosniff"
    assert response.headers["cross-origin-resource-policy"] == "same-origin"