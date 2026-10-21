# Ejecución y despliegue con React + FastAPI

## Desarrollo local

La tienda web React y la API FastAPI son dos procesos separados:

1. En la raíz, instala Python, configura `.env` y arranca `python run.py` (API `127.0.0.1:8000`).
2. En `frontend/`, ejecuta `npm ci` y `npm run dev` (React `localhost:5173`).

Vite reenvía las rutas `/api` al backend. Para los enlaces de verificación usa `FRONTEND_URL=http://localhost:5173`.

## Docker Compose

El recurso Docker Compose construye dos servicios: FastAPI y React estático servido por Nginx. Nginx reenvía `/api/` al servicio interno `backend`; React comparte origen con la API. En Coolify asigna el dominio al servicio `frontend` y al puerto interno `80`. El backend debe quedar interno en `8000` salvo que quieras publicar `/docs`.

En **Environment Variables** del recurso Compose, configura estas variables obligatorias:

```env
SECRET_KEY=<clave-aleatoria-larga>
FIRST_ADMIN_EMAIL=<correo-administrador>
FIRST_ADMIN_PASSWORD=<contraseña-segura>
FRONTEND_URL=https://app.tudominio.com
CORS_ORIGINS=https://app.tudominio.com
```

Para activar correo de verificación y confirmaciones, añade también:

```env
SMTP_HOST=<servidor-smtp>
SMTP_PORT=587
SMTP_USER=<usuario-smtp>
SMTP_PASSWORD=<contraseña-de-aplicacion>
SMTP_FROM_EMAIL=<correo-remitente>
SMTP_FROM_NAME=ElectroPhone Store
VERIFICATION_TOKEN_EXPIRE_HOURS=24
```

`DATABASE_URL` no se configura en Coolify: Compose usa SQLite y el volumen persistente `backend_data`. No configures `VITE_API_URL`: React usa el proxy `/api` de Nginx. `docker-compose.yml` solo expone los puertos dentro de la red de Compose; las publicaciones para probar en tu PC están en `docker-compose.local.yml`.

Para generar `SECRET_KEY` en tu equipo puedes ejecutar `python -c "import secrets; print(secrets.token_urlsafe(48))"`. No uses las credenciales de ejemplo en producción.

## Despliegue como aplicación Railpack (solo API)

Si Coolify está configurado como recurso **Application/Railpack** en vez de Docker Compose, define el tipo de sitio como **Web Application**, **Ports Exposes = `8000`**, la variable `PORT=8000` y el dominio con puerto interno `8000`. El comando de inicio debe ser `uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}`. Esta modalidad publica FastAPI y no compila ni sirve el frontend React; para la tienda React usa un recurso **Docker Compose** con `docker-compose.yml` y asigna el dominio al servicio `frontend`, puerto `80`.

Si despliegas solamente el `Dockerfile` como una aplicación Coolify y configuras `DATABASE_URL=sqlite:///./data/telefonos.db`, monta un volumen persistente en `/app/data`; el directorio se crea en la imagen, pero sin ese volumen la base se pierde al reemplazar el contenedor.

## Alcance actual

- El checkout aún no integra un proveedor de pagos; los pedidos quedan con pago pendiente.
- Para correo de verificación y confirmaciones, configura SMTP.
- Flutter y Android siguen en el repositorio como clientes heredados; el despliegue web documentado usa React.
