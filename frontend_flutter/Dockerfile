# ============ Etapa 1: Build del frontend Flutter ============
FROM ghcr.io/cirruslabs/flutter:stable AS build

# URL del backend en producción (se quema en el build)
# Se pasa con: docker build --build-arg API_BASE_URL=https://api.tudominio.com/api/v1
ARG API_BASE_URL=https://api.example.com/api/v1

WORKDIR /app

# Copiar pubspec y resolver dependencias (cache)
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copiar el resto y compilar a web
COPY . .
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# ============ Etapa 2: Servir con nginx ============
FROM nginx:alpine AS serve

# Config nginx para SPA (rutas de Flutter web)
COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
