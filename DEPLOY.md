# Despliegue de una sola imagen React + FastAPI

El `Dockerfile` de la raíz usa una etapa Node para compilar React y una etapa Python para ejecutar FastAPI y servir esos archivos. La imagen final contiene **ambas partes en un solo contenedor** y escucha en el puerto `8000`.

## Coolify con Dockerfile (recomendado)

1. Crea un recurso **Application** conectado a `Brandon161-arch/Telefonos-FastApi`, rama `main`.
2. Selecciona el build pack **Dockerfile**, Dockerfile `/Dockerfile` y base directory `/`.
3. En **Ports Exposes**, configura `8000`.
4. Asigna el dominio al puerto interno `8000`.
5. Añade las variables obligatorias y despliega.
6. En **Persistent Storage**, monta un volumen en `/app/data` para conservar SQLite.

## Variables obligatorias

```env
SECRET_KEY=<clave-aleatoria-larga>
FIRST_ADMIN_EMAIL=<correo-administrador>
FIRST_ADMIN_PASSWORD=<contraseña-segura>
FRONTEND_URL=https://app.tudominio.com
CORS_ORIGINS=https://app.tudominio.com
PORT=8000
```

El Dockerfile activa `SERVE_FRONTEND=true`. React usa una URL relativa para la API, por lo que no requiere `VITE_API_URL`.

Variables opcionales para correo:

```env
SMTP_HOST=<servidor-smtp>
SMTP_PORT=587
SMTP_USER=<usuario-smtp>
SMTP_PASSWORD=<contraseña-de-aplicacion>
SMTP_FROM_EMAIL=<correo-remitente>
SMTP_FROM_NAME=ElectroPhone Store
VERIFICATION_TOKEN_EXPIRE_HOURS=24
```

## Docker Compose

También se puede desplegar como recurso **Docker Compose**: `docker-compose.yml` construye el mismo Dockerfile y ejecuta un servicio `app`. Asigna el dominio al servicio `app`, puerto `8000`; conserva el volumen `backend_data`.

## Comprobaciones

- Tienda React: `https://app.tudominio.com/`
- Salud: `https://app.tudominio.com/health`
- Swagger: `https://app.tudominio.com/docs`

SQLite usa `sqlite:///./data/telefonos.db`, guardado en `/app/data`. Si se despliega el Dockerfile como Application, configura almacenamiento persistente en esa ruta. El checkout todavía no integra una pasarela de pagos.
