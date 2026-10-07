"""Arranca el servidor FastAPI dentro de la app Android.

MainActivity llama a ``serve_forever()`` desde un hilo secundario; el WebView
se conecta a http://127.0.0.1:8000 en cuanto el puerto responde.

Todo ocurre en el telefono: no hay servidor externo ni acceso a internet.
"""

import os

HOST = "127.0.0.1"
PORT = 8000


def serve_forever():
    # En Android, HOME apunta al almacenamiento interno de la app
    # (/data/data/<paquete>/files). Ahi se guarda la base de datos para que
    # sobreviva a cierres y reinicios del telefono.
    home = os.environ.get("HOME", os.getcwd())
    db_path = os.path.join(home, "telefonos.db")

    # Se define ANTES de importar app.main: app/core/config.py lee la variable
    # al momento de la importacion (load_dotenv no pisa variables ya existentes).
    # Con la barra inicial el resultado es sqlite:////data/... (URL absoluta).
    os.environ["DATABASE_URL"] = "sqlite:///" + db_path

    import uvicorn

    # Sin reload ni workers: multiprocessing no existe en Android.
    # uvicorn funciona sin extras [standard] usando h11 (Python puro).
    uvicorn.run(
        "app.main:app",
        host=HOST,
        port=PORT,
        log_level="info",
        access_log=False,
    )
