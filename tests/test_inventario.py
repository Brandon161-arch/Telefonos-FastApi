def test_list_phones(client):
    resp = client.get("/api/v1/phones")
    assert resp.status_code == 200
    data = resp.json()
    assert "total" in data
    assert "data" in data
    assert data["total"] >= 0


def test_get_phone_detail(client):
    resp = client.get("/api/v1/phones?limit=1")
    phone = resp.json()["data"][0]
    resp = client.get(f"/api/v1/phones/{phone['slug']}")
    assert resp.status_code == 200
    assert resp.json()["slug"] == phone["slug"]


def test_list_brands(client):
    resp = client.get("/api/v1/brands")
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_filters(client):
    resp = client.get("/api/v1/phones?is_5g=true&ram_gb=12")
    assert resp.status_code == 200
    for phone in resp.json()["data"]:
        assert phone["is_5g"] is True
        assert phone["ram_gb"] == 12


def test_reviews_list_empty(client):
    resp = client.get("/api/v1/phones?limit=1")
    phone_id = resp.json()["data"][0]["id"]
    resp = client.get(f"/api/v1/phones/{phone_id}/reviews")
    assert resp.status_code == 200
    assert "rating" in resp.json()


def test_create_phone_requires_admin(client):
    resp = client.post("/api/v1/phones", json={"name": "x", "slug": "x", "price": 100, "stock": 1, "ram_gb": 8, "storage_gb": 128, "color": "x", "image_url": "http://x", "brand_id": 1})
    assert resp.status_code in (401, 403)
