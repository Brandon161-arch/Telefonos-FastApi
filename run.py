import uvicorn

if __name__ == "__main__":
    print("\n" + "=" * 60)
    print("ElectroPhone Store - Backend FastAPI")
    print("Swagger:     http://127.0.0.1:8000/docs")
    print("ReDoc:       http://127.0.0.1:8000/redoc")
    print("Health:      http://127.0.0.1:8000/health")
    print("Frontend:    http://localhost:5173")
    print("=" * 60 + "\n")

    uvicorn.run("app.main:app", host="127.0.0.1", port=8000, reload=True)
