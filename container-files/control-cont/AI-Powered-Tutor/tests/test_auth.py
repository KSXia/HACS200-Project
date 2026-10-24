def test_ask_requires_token(client):
    resp = client.post("/ask", json={"question": "what is 2+2?"})
    assert resp.status_code == 401


def test_health_is_public(client):
    assert client.get("/health").status_code == 200
