import uvicorn

if __name__ == "__main__":
    print("\n" + "="*60)
    print("🚀 Iniciando ElectroPhone - Tienda de Celulares en FastAPI")
    print("🌐 Tienda Web:        http://127.0.0.1:8000")
    print("⚡ Documentación API: http://127.0.0.1:8000/docs")
    print("📦 Rastreo de Envíos: http://127.0.0.1:8000/track")
    print("⚙️ Panel Admin:       http://127.0.0.1:8000/admin")
    print("="*60 + "\n")
    
    uvicorn.run("app.main:app", host="127.0.0.1", port=8000, reload=True)
