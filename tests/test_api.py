import os

os.environ.setdefault("DATABASE_URL", "postgresql://test:test@localhost:5432/test")

import psycopg  # noqa: E402
import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

import main  # noqa: E402


def test_health_and_version():
    client = TestClient(main.app)
    assert client.get("/health").json() == {"status": "ok"}
    assert client.get("/").json()["version"] == main.settings.app_version


def test_validation():
    client = TestClient(main.app)
    assert client.post("/messages", json={"author": "", "text": "x"}).status_code == 422


def test_readiness_failure(monkeypatch):
    def fail():
        raise psycopg.OperationalError("unavailable")
    monkeypatch.setattr(main, "connect", fail)
    assert TestClient(main.app).get("/ready").status_code == 503


@pytest.mark.skipif(not os.getenv("INTEGRATION"), reason="Requires PostgreSQL")
def test_message_persists():
    with TestClient(main.app) as client:
        assert client.post("/messages", json={"author": "CI", "text": "persist"}).status_code == 200
    with TestClient(main.app) as client:
        assert {"author": "CI", "text": "persist"} in client.get("/messages").json()
        assert client.get("/ready").status_code == 200
