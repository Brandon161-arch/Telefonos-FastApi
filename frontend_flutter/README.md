# ElectroPhone Flutter frontend

Cliente Flutter de la tienda ElectroPhone. El frontend Jinja/JS actual sigue disponible mientras esta migración se desarrolla y verifica.

## Requisitos

- Flutter SDK (incluye Dart), con web habilitado para builds de navegador.
- FastAPI corriendo localmente, normalmente en `http://127.0.0.1:8000`.

## Arranque

Desde esta carpeta:

```sh
flutter create .          # solo la primera vez, genera platform/ (web, android, ios)
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Para un emulador Android usa `http://10.0.2.2:8000/api/v1` en vez de `127.0.0.1`.
Para despliegue, define `API_BASE_URL` con la URL de la API FastAPI desplegada.

## Cobertura de la migración

Pantallas implementadas en `lib/screens/`:

| Pantalla | Ruta | Estado |
|---|---|---|
| Catálogo (búsqueda, marca, orden, scroll infinito) | `/` | ✅ |
| Detalle de producto + reseñas | `/phone/:slug` | ✅ |
| Carrito + checkout | `/cart` | ✅ |
| Iniciar sesión / registro | `/login` | ✅ |
| Verificación de correo | `/verify-email` | ✅ |
| Mi cuenta + mis pedidos | `/account` | ✅ |
| Rastrear pedido | `/track` | ✅ |
| Panel admin (órdenes + cambio de estado) | `/admin` | ✅ |

## Notas de verificación pendiente

- El equipo donde se genera el código no tiene Flutter/Dart instalado, por lo que **no se ejecutó `flutter analyze` ni `flutter build`**.
- Pasos para validar: `flutter pub get`, `flutter analyze`, `flutter build web` y `flutter run`.
