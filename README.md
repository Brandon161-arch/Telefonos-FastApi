# ElectroPhone — FastAPI + React

Tienda local de smartphones con API REST en FastAPI, SQLAlchemy y frontend React/Vite. React es la interfaz web principal; el frontend y la API se ejecutan por separado durante el desarrollo.

## Requisitos

- Python 3.12 o superior
- Node.js 20 o superior y npm

## Ejecutar en local

### 1. Preparar el backend (PowerShell)

Desde la raíz del repositorio:

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env
```

Si ya tienes un `.env`, no lo sobrescribas. La aplicación carga la configuración desde el `.env` de la raíz. SQLite crea `telefonos.db` en esa misma raíz al iniciar.

### 2. Arrancar FastAPI

En una primera terminal, desde la raíz:

```powershell
python run.py
```

La API queda en `http://127.0.0.1:8000`; documentación: `http://127.0.0.1:8000/docs`.

### 3. Arrancar React

En una segunda terminal:

```powershell
cd frontend
# Si npm no está en PATH pero Node está en la ubicación habitual:
$env:Path = "C:\Program Files\nodejs;$env:Path"
npm ci
npm run dev
```

Abre **http://localhost:5173**. Vite reenvía las solicitudes `/api` a FastAPI en el puerto 8000.

### Cuenta local

Si la base local es nueva, se crea un administrador para desarrollo con el correo y contraseña definidos por `FIRST_ADMIN_EMAIL` y `FIRST_ADMIN_PASSWORD` en `.env`. Los valores de ejemplo son únicamente para desarrollo; cámbialos antes de exponer el sistema.

Sin SMTP, el backend imprime en su terminal los enlaces de verificación. `FRONTEND_URL` debe apuntar a React para que esos enlaces abran la página correcta.

## Funciones incluidas

- Catálogo, filtros, búsqueda, detalle y reseñas.
- Registro, acceso JWT, verificación de correo y perfil.
- Carrito local, validación de cupones y creación/rastreo de pedidos.
- Panel de administración de métricas, inventario, órdenes y cupones.

**Pagos:** el checkout local es una demo. No existe integración con PSE, Nequi, tarjetas ni otro proveedor; los pedidos quedan con pago pendiente y no se realiza ningún cobro.

## Pruebas

Desde la raíz, con las dependencias del backend instaladas:

```powershell
python -m pytest -q
```

Compilar React:

```powershell
cd frontend
npm run build
```

## Docker Compose

Con Docker instalado y `.env` preparado:

```powershell
docker compose -f docker-compose.yml -f docker-compose.local.yml up --build
```

React queda en `http://localhost:5173` y FastAPI en `http://localhost:8000`. Nginx sirve React y reenvía `/api` al backend.

## Estructura relevante

```text
app/                 FastAPI, modelos, servicios y rutas
frontend/            React, Vite y cliente HTTP
frontend_flutter/    Cliente Flutter heredado
android/             Aplicación Android heredada
tests/               Pruebas del backend
```
