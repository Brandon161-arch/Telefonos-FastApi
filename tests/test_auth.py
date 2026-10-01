import sqlite3


def test_register_and_login_requires_verification(client):
    # Registrar
    resp = client.post("/api/v1/auth/register", json={
        "full_name": "Test User", "email": "test@test.com", "password": "clave12345"
    })
    assert resp.status_code == 201

    # Login sin verificar -> 403
    resp = client.post("/api/v1/auth/login", json={"email": "test@test.com", "password": "clave12345"})
    assert resp.status_code == 403

    # Verificar con el token de la BD
    con = sqlite3.connect("test.db")
    token = con.execute("SELECT verification_token FROM users WHERE email='test@test.com'").fetchone()[0]
    con.close()
    resp = client.get(f"/api/v1/auth/verify-email?token={token}")
    assert resp.status_code == 200

    # Login verificado -> 200
    resp = client.post("/api/v1/auth/login", json={"email": "test@test.com", "password": "clave12345"})
    assert resp.status_code == 200
    assert "access_token" in resp.json()


def test_register_duplicate(client):
    client.post("/api/v1/auth/register", json={
        "full_name": "A", "email": "dup@test.com", "password": "clave12345"
    })
    resp = client.post("/api/v1/auth/register", json={
        "full_name": "B", "email": "dup@test.com", "password": "clave12345"
    })
    assert resp.status_code == 400


def test_me_requires_auth(client):
    resp = client.get("/api/v1/auth/me")
    assert resp.status_code == 401


def test_admin_login(client):
    resp = client.post("/api/v1/auth/login", json={"email": "admin@electrophone.com", "password": "admin123456"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["user"]["is_admin"] is True
    assert data["user"]["is_verified"] is True


def test_update_me(client, admin_token):
    headers = {"Authorization": f"Bearer {admin_token}"}
    resp = client.put("/api/v1/auth/me", json={"full_name": "Admin Editado"}, headers=headers)
    assert resp.status_code == 200
    assert resp.json()["full_name"] == "Admin Editado"
