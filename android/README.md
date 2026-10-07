# 📱 ElectroPhone APK — Build Android con Chaquopy

Esta carpeta convierte el proyecto FastAPI en una app Android **100% local**:
sin internet, sin servidor externo. La app arranca Uvicorn + FastAPI dentro del
propio teléfono (`127.0.0.1:8000`) y lo muestra en un WebView.

> **El proyecto original no se toca.** Todo vive en `android/`; el código de
> `app/` (backend + templates + estáticos) se copia automáticamente aquí en
> cada compilación. `main` queda intacto.

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
| Base de datos | SQLite en el **almacenamiento interno** (`files/telefonos.db`); se crea, migra (`migrate_sqlite_schema`) y siembra en el **primer arranque** |
| WebView | Espera a que el puerto 8000 responda y carga la tienda; JavaScript + `localStorage` habilitados |
| Tráfico local | `network_security_config.xml` permite `http://127.0.0.1` (Android 9+ bloquea cleartext por defecto) |

## 2. Estructura de esta carpeta

```text
android/
├── build.gradle              # Versiones: AGP 8.7.3 + Chaquopy 17.0.0
├── settings.gradle           # Repositorios (google, mavenCentral)
├── gradle.properties         # Memoria JVM y flags de AGP
├── local.properties          # Ruta del SDK de Android (tu máquina)
├── .gitignore
├── README.md                 # Este archivo
└── app/
    ├── build.gradle          # Plugin Chaquopy, Python 3.12, pip, copia de ../app
    ├── requirements.txt      # Dependencias pip para Android
    └── src/main/
        ├── AndroidManifest.xml
        ├── java/com/electrophone/store/
        │   └── MainActivity.java      # WebView + arranque del servidor
        ├── python/
        │   └── bootstrap.py           # serve_forever() → uvicorn.run(...)
        └── res/
            ├── layout/activity_main.xml
            ├── values/strings.xml
            ├── drawable/ic_launcher.xml
            └── xml/network_security_config.xml
```

## 3. Prerrequisitos (Windows)

| Herramienta | Versión | ¿Lo tienes? |
|---|---|---|
| Python | **3.12** (debe coincidir con `version = "3.12"` en `app/build.gradle`) | ✅ 3.12.10 instalado |
| Android SDK | con `platforms;android-34` y `platform-tools` (adb) | ✅ `%LOCALAPPDATA%\Android\Sdk` |
| Android Studio | opcional (solo para depurar) | ✅ instalado |
| **JDK** | **17** (o 21). *No sirve* el Java 8 del PATH ni el JBR 25 de Android Studio: Gradle 8.9 no los soporta | ❌ instalar (paso 4.1) |
| **Gradle** | **8.9** | ❌ descargar (paso 4.2) |

### 4.1 Instalar JDK 17 (solo la primera vez)

```powershell
winget install EclipseAdoptium.Temurin.17.JDK

# Cerrar y abrir la terminal. Luego apuntar JAVA_HOME:
$env:JAVA_HOME = (Get-ChildItem "C:\Program Files\Eclipse Adoptium" -Directory |
    Where-Object { $_.Name -like "jdk-17*" } | Select-Object -Last 1).FullName
java -version   # Debe decir "17.x"
```

### 4.2 Descargar Gradle 8.9 (solo la primera vez)

```powershell
$zip = "$env:TEMP\gradle-8.9-bin.zip"
Invoke-WebRequest https://services.gradle.org/distributions/gradle-8.9-bin.zip -OutFile $zip
Expand-Archive $zip "$env:TEMP\gradle89" -Force
$gradle = "$env:TEMP\gradle89\gradle-8.9\bin\gradle.bat"
& $gradle -version   # Debe decir "Gradle 8.9"
```

## 5. Compilar el APK de debug

```powershell
# 1. Entorno (repetir en cada terminal nueva)
$env:JAVA_HOME = (Get-ChildItem "C:\Program Files\Eclipse Adoptium" -Directory |
    Where-Object { $_.Name -like "jdk-17*" } | Select-Object -Last 1).FullName
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$gradle = "$env:TEMP\gradle89\gradle-8.9\bin\gradle.bat"

# 2. Entrar a la carpeta android/
cd "C:\Users\duart\OneDrive\Desktop\mis proyectos\Telefonos FastApi\android"

# 3. Generar el wrapper de Gradle (solo la primera vez)
& $gradle wrapper --gradle-version 8.9

# 4. Compilar (la primera vez tarda 5-15 min: descarga Maven + wheels pip)
.\gradlew.bat assembleDebug
```

**APK resultante:**

```text
android\app\build\outputs\apk\debug\app-debug.apk
```

Cada recompilación incluye los cambios hechos en `app/` del proyecto original
(la copia es automática; no hace nada manual).

## 6. Instalarlo en el celular

1. En el celular: **Ajustes → Acerca del teléfono → Compilación (7 toques)** →
   **Ajustes → Sistema → Opciones para desarrolladores → Depuración USB = ON**.
2. Conectar el celular por USB y aceptar la ventana de depuración.

```powershell
adb devices                      # debe aparecer tu equipo (no "unauthorized")
adb install -r "app\build\outputs\apk\debug\app-debug.apk"
```

**Alternativa sin PC:** copiar el `.apk` al celular (USB, correo, etc.) y
abrirlo → aceptar "instalar de orígenes desconocidos".

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
| `Unsupported class file major version` / error raro de Gradle | `JAVA_HOME` apunta al Java 8 o al JBR 25. Usa el JDK 17 del paso 4.1 y verifica con `java -version` |
| `sdk location not found` | Falta `local.properties` o `ANDROID_HOME`. Ambos vienen configurados en esta carpeta |
| Error de pip: *"No matching distributions available"* | Un paquete no tiene wheel para Android/Python 3.12. Revisa el [FAQ de Chaquopy](https://chaquo.com/chaquopy/doc/current/faq.html#faq-pip) y fija una versión en `android/app/requirements.txt` (p. ej. `pydantic==2.9.2`) |
| `ModuleNotFoundError: No module named 'app'` | La copia del backend falló: reconstruye desde `android/` con `.\gradlew.bat assembleDebug` |
| WebView en blanco | Ver logs: `adb logcat -s python.stdout python.stderr ElectroPhone` (el primer arranque puede tardar) |
| Abrir el proyecto en Android Studio | Studio usa un Gradle JDK que apunta a su JBR (Java 25), incompatible con Gradle 8.9: `Settings → Build Tools → Gradle → Gradle JDK` → selecciona el **JDK 17** |
| Ver la app en el emulador | El ABI `x86_64` ya está incluido; solo crea un AVD con Play Store x86_64 |

## 9. Limitaciones conocidas

1. **Imágenes de productos y logos**: el seed usa URLs de Unsplash/Wikimedia.
   Sin internet se ven rotas (el resto de la tienda funciona). Solución futura:
   empaquetar imágenes locales en `app/static/`.
2. **Verificación de correo**: sin SMTP configurado, los correos se imprimen
   en Logcat (modo dev del propio `emails.py`). El admin ya nace verificado.
3. **`/docs` y `/redoc` (Swagger)**: cargan su JS desde CDN → no abren sin
   internet. En el WebView el enlace `target="_blank"` además no abre pestañas.
4. **Tamaño del APK ≈ 50–80 MB**: incluye intérprete de Python y dependencias
   nativas por cada ABI (`arm64-v8a` + `x86_64`). Para reducirlo, deja solo
   `arm64-v8a` en `app/build.gradle`.
5. **Primer arranque lento** (extracción + seed). Las siguientes arrancan más
   rápido.
6. **Sin pago real**: el checkout es simulado (no integra pasarelas) y no hay
   notificaciones push.
7. **Solo 64 bits**: `arm64-v8a` (celulares actuales) y `x86_64` (emulador).
   Celulares MUY antiguos (32 bits) no son soportados por Python 3.12.
8. **El servidor es de un solo dispositivo**: escucha en `localhost`; no sirve
   a otros teléfonos ni a la PC.
9. **`uvicorn[standard]` se sustituyó por `uvicorn` puro** en Android
   (`uvloop`/`httptools` no hacen falta en loopback). En PC puedes seguir
   usando el `requirements.txt` original.
10. **Release sin firmar**: solo se genera APK de debug (uso local).

## 10. Comandos rápidos (resumen)

```powershell
# Build completo desde cero
$env:JAVA_HOME = (Get-ChildItem "C:\Program Files\Eclipse Adoptium" -Directory |
    Where-Object { $_.Name -like "jdk-17*" } | Select-Object -Last 1).FullName
cd "C:\Users\duart\OneDrive\Desktop\mis proyectos\Telefonos FastApi\android"
.\gradlew.bat assembleDebug

# Instalar en el celular conectado
adb install -r "app\build\outputs\apk\debug\app-debug.apk"

# Ver los logs de Python/FastAPI en vivo
adb logcat -s python.stdout python.stderr ElectroPhone
```
