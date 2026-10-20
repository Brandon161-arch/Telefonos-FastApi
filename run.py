import sys
import os
import uvicorn

# Agregar el directorio backend al sys.path
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
backend_dir = os.path.join(BASE_DIR, "backend")
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

if __name__ == "__main__":
    print("\n" + "=" * 60)
    print("🚀 ElectroPhone Store - Backend FastAPI v2.0")
    print("⚡ Documentación Swagger: http://127.0.0.1:8000/docs")
    print("📖 Documentación ReDoc:   http://127.0.0.1:8000/redoc")
    print("❤️ Endpoint de Salud:    http://127.0.0.1:8000/health")
    print("💻 Frontend React (Vite): http://localhost:5173")
    print("=" * 60 + "\n")

    uvicorn.run("app.main:app", host="127.0.0.1", port=8000, reload=True)
