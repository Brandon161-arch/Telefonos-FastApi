# 📱 ElectroPhone APK — Build Android con Chaquopy

Esta carpeta convierte el proyecto FastAPI en una app Android **100% local**:
sin internet, sin servidor externo. La app arranca Uvicorn + FastAPI dentro del
propio teléfono (`127.0.0.1:8000`) y lo muestra en un WebView.

> **El proyecto original no se toca.** Todo vive en `android/`; el código de
> `app/` (backend + templates + estáticos) se copia automáticamente aquí en
> cada compilación. El proyecto raíz queda intacto.

**APK ya generado:** [`android/dist/ElectroPhone-debug.apk`](dist/ElectroPhone-debug.apk) (~48 MB).

---

## 1. Cómo funciona

```
┌─────────────────────────── Celular Android ────────────────────────────┐
│  MainActivity (Java)                                                   │
│  ┌───────────────────────┐        ┌──────────────────────────────────┐ │
│  │      WebView          │ ─────► │ Uvicorn (hilo Python)            │ │
│  │  http://127.0.0.1:8000│  HTTP  │  └─ FastAPI + Jinja2 + SQLAlchemy │ │
│  └───────────────────────┘        │      └─ SQLite: files/telefonos.db│ │
│         (localStorage del carrito)└──────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────┘
```

| Pieza | Detalle |
|---|---|
| Python embebido | **Chaquopy 17.0** (plugin Gradle) empaqueta Python 3.12 + las dependencias pip dentro del APK |
| Código backend | `../app` se copia a `android/app/src/main/python/app` en cada build (tarea `afterEvaluate`) |
| Templates y estáticos | Van dentro de `app/`; Chaquopy los extrae al filesystem al arrancar Python, así que Jinja2 y `StaticFiles` funcionan igual |
| Base de datos | SQLite en el **almacenamiento interno** (`files/telefonos.db`); se crea y siembra en el **primer arranque** |
| WebView | Espera a que el puerto 8000 responda y carga la tienda; JavaScript + `localStorage` habilitados |
| Tráfico local | `network_security_config.xml` permite `http://127.0.0.1` (Android 9+ bloquea cleartext por defecto) |

## 2. Estructura de esta carpeta

```text
android/
├── build.gradle              # Versiones (AGP 8.7.3 + Chaquopy 17.0.0) y buildDir fuera de OneDrive
├── settings.gradle           # Repositorios (google, mavenCentral)
├── gradle.properties         # Memoria JVM y flags de AGP
├── local.properties          # Ruta del SDK de Android (tu máquina)
├── gradlew / gradlew.bat     # Gradle Wrapper 8.9 (no hace falta instalar Gradle)
├── dist/                     # APK generado (se copia aquí tras cada build)
└── app/
    ├── build.gradle          # Plugin Chaquopy, Python 3.12, pip, copia de ../app
    ├── requirements.txt      # Dependencias pip para Android
    ├── wheels/               # Ruedas locales que no existen para Android en PyPI
    │   ├── pydantic_core-2.46.3-cp312-cp312-android_24_arm64_v8a.whl
    │   └── pydantic_core-2.46.3-cp312-cp312-android_24_x86_64.whl
    └── src/main/
        ├── AndroidManifest.xml
        ├── java/com/electrophone/store/MainActivity.java   # WebView + arranque del servidor
        ├── python/bootstrap.py                             # serve_forever() → uvicorn.run(...)
        └── res/ (layout, values, drawable, xml)
```

> **Nota (OneDrive):** la carpeta `build/` se redirige a
> `%USERPROFILE%\.gradle-builds\telefonos-fastapi` (ver `build.gradle` raíz).
> OneDrive convierte los archivos nuevos en *placeholders* (reparse points) y
> Gradle no puede borrarlos (`AccessDeniedException`). El código fuente sí
> permanece en el proyecto; solo los artefactos de compilación salen de OneDrive.

## 3. Dependencias que tuvieron que ajustarse

| Paquete | En PC | En Android | Motivo |
|---|---|---|---|
| `uvicorn` | `uvicorn[standard]` | `uvicorn` | `uvloop`/`httptools` son extensiones nativas innecesarias en loopback |
| `bcrypt` | `>=4.0.0` | `==3.2.2` | Es la única versión con rueda Android en el índice de Chaquopy (misma API usada) |
| `pydantic` | `>=2.6.0` | `==2.13.3` | Exige `pydantic-core==2.46.3`, la única con rueda Android disponible |
| `pydantic-core` | (transitiva) | `==2.46.3` | No existe en PyPI ni en el índice de Chaquopy para Android; se usan las ruedas precompiladas de [Eutalix/android-pydantic-core](https://github.com/Eutalix/android-pydantic-core) incluidas en `app/wheels/` (re-etiquetadas al tag `android_24_*` de Chaquopy) |

## 4. Prerrequisitos (Windows)

| Herramienta | Versión | Estado en esta máquina |
|---|---|---|
| **JDK** | **17** (no sirve Java 8 del PATH ni el JBR 25 de Android Studio) | ✅ `C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot` |
| **Python** | **3.12 desde python.org** (el de Microsoft Store NO sirve: Chaquopy lo ve como inexistente) | ✅ `%LOCALAPPDATA%\Programs\Python\Python312\python.exe` |
| Android SDK | con `platforms;android-34`, `build-tools;34.0.0` y `platform-tools` (adb) | ✅ `%LOCALAPPDATA%\Android\Sdk` |
| Gradle | 8.9 | ✅ incluido en el repo (`gradlew.bat`) |

Si faltara alguno:

```powershell
winget install EclipseAdoptium.Temurin.17.JDK
winget install Python.Python.3.12
```

Tras instalarlos, actualiza `buildPython(...)` en `app/build.gradle` con la ruta
real (`python -c "import sys; print(sys.executable)"`).

## 5. Compilar el APK de debug

```powershell
# 1. Entorno (repetir en cada terminal nueva)
$env:JAVA_HOME = (Get-ChildItem "C:\Program Files\Eclipse Adoptium" -Directory |
    Where-Object { $_.Name -like "jdk-17*" } | Select-Object -Last 1).FullName
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"

# 2. Compilar (desde esta carpeta)
cd "C:\Users\duart\OneDrive\Desktop\mis proyectos\Telefonos FastApi\android"
.\gradlew.bat assembleDebug
```

El APK queda en **dos sitios**:

```text
# Salida real de Gradle (fuera de OneDrive):
%USERPROFILE%\.gradle-builds\telefonos-fastapi\app\outputs\apk\debug\app-debug.apk

# Copia de conveniencia (cópiala tú tras compilar):
android\dist\ElectroPhone-debug.apk
```

Cada recompilación incluye los cambios hechos en `app/` del proyecto original
(la copia es automática; no hace falta nada manual).

## 6. Instalarlo en el celular

**Opción A — desde este PC por USB:**

1. En el celular: **Ajustes → Acerca del teléfono → Compilación (7 toques)** →
   **Ajustes → Sistema → Opciones para desarrolladores → Depuración USB = ON**.
2. Conectar por USB y aceptar la ventana de depuración.

```powershell
adb devices                      # debe aparecer tu equipo (no "unauthorized")
adb install -r "dist\ElectroPhone-debug.apk"
```

**Opción B — sin cable:** como el APK está en `dist/` dentro de OneDrive, puedes
abrirlo desde la **app OneDrive del celular** y descargarlo directamente, o
pasarlo por USB/correo y abrirlo (aceptar "instalar de orígenes desconocidos").

**APK de release:** no está firmado a propósito (uso local). Si algún día lo
necesitas: `.\gradlew.bat assembleRelease` + un keystore propio.

## 7. Primer arranque

- Extracción de Python y arranque de Uvicorn: **~3–10 s** (spinner).
- Se crea `files/telefonos.db`, se ejecutan las migraciones y el seed.
- Credenciales del administrador: **admin@electrophone.com** / **admin123456**.
- La base de datos persiste entre sesiones; se recrea solo si desinstalas la app.

## 8. Solución de problemas

| Síntoma | Causa / arreglo |
|---|---|
| `Couldn't find Python 3.12` | Chaquopy no autodetecta el Python de Microsoft Store. Instala el de python.org y ajusta `buildPython(...)` en `app/build.gradle` |
| `Unable to delete directory` / `AccessDeniedException` al compilar | OneDrive bloqueando `build/`. Ya se resuelve moviendo `buildDir` fuera de OneDrive (ver `build.gradle` raíz) |
| `Could not find a version ... pydantic-core` | Las ruedas de `app/wheels/` no se están viendo. Deben estar presentes y el bloque `pip { options("--find-links", ...) }` en `app/build.gradle` |
| `Unsupported class file major version` | `JAVA_HOME` apunta al Java 8 o al JBR 25. Usa el JDK 17 |
| `sdk location not found` | Falta `local.properties` o `ANDROID_HOME` |
| `ModuleNotFoundError: No module named 'app'` | La copia del backend falló: recompila desde `android/` |
| WebView en blanco | `adb logcat -s python.stdout python.stderr ElectroPhone` (el primer arranque tarda) |
| Abrir el proyecto en Android Studio | Studio usa su JBR (Java 25) incompatible con Gradle 8.9: `Settings → Build Tools → Gradle → Gradle JDK` → elige el **JDK 17** |
| Ver en emulador | El ABI `x86_64` ya está incluido; crea un AVD x86_64 |

## 9. Limitaciones conocidas

1. **Imágenes de productos y logos**: el seed usa URLs de Unsplash/Wikimedia.
   Sin internet se ven rotas (el resto de la tienda funciona).
2. **Verificación de correo**: sin SMTP, los correos se imprimen en Logcat.
   El admin ya nace verificado.
3. **`/docs` y `/redoc` (Swagger)**: cargan su JS desde CDN → no abren sin
   internet.
4. **Tamaño del APK ≈ 48 MB**: incluye intérprete de Python y dependencias
   nativas por cada ABI (`arm64-v8a` + `x86_64`). Para reducirlo, deja solo
   `arm64-v8a` en `app/build.gradle`.
5. **Primer arranque lento** (extracción + seed).
6. **Sin pago real**: el checkout es simulado.
7. **Solo 64 bits**: `arm64-v8a` (celulares actuales) y `x86_64` (emulador).
8. **El servidor es de un solo dispositivo**: escucha en `localhost`.
9. **`pydantic-core` usa ruedas de un tercero** (Eutalix). Si actualizas
   `pydantic`, su `pydantic-core` deberá tener rueda cp312 en `app/wheels/`.
10. **Release sin firmar**: solo se genera APK de debug (uso local).

## 10. Comandos rápidos

```powershell
# Build completo desde cero
$env:JAVA_HOME = (Get-ChildItem "C:\Program Files\Eclipse Adoptium" -Directory |
    Where-Object { $_.Name -like "jdk-17*" } | Select-Object -Last 1).FullName
cd "C:\Users\duart\OneDrive\Desktop\mis proyectos\Telefonos FastApi\android"
.\gradlew.bat assembleDebug

# Copiar el APK a dist/ para pasarlo al celular
Copy-Item "$env:USERPROFILE\.gradle-builds\telefonos-fastapi\app\outputs\apk\debug\app-debug.apk" "dist\ElectroPhone-debug.apk" -Force

# Instalar en el celular conectado
adb install -r "dist\ElectroPhone-debug.apk"

# Ver los logs de Python/FastAPI en vivo
adb logcat -s python.stdout python.stderr ElectroPhone
```
