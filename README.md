# 📱 ElectroPhone - Tienda Web Virtual de Celulares con FastAPI

Base completa, moderna y lista para producción de una tienda virtual especializada en venta de teléfonos celulares y smartphones, construida con **FastAPI**, **SQLAlchemy**, **Pydantic v2** y un frontend reactivo con diseño *Glassmorphism*.

---

## 🌟 Características Principales

### 🛒 Frontend & Experiencia de Usuario
- **Catálogo Interactivo**: Filtrado reactivo en tiempo real por **marca** (Apple, Samsung, Xiaomi, Motorola, etc.), **precio máximo con slider**, **memoria RAM** (6GB, 8GB, 12GB, 16GB), **almacenamiento** (128GB, 256GB, 512GB) y conectividad **5G**.
- **Búsqueda Instantánea**: Búsqueda por modelo, procesador, color o descripción con debouncing.
- **Carrito de Compras Persistente**: Drawer lateral de compras con almacenamiento en `localStorage`, cálculo automático de subtotal, envío gratis en pedidos mayores a $300 y actualización de unidades.
- **Modal de Especificaciones Rápidas**: Visualización de ficha técnica completa (procesador, pantalla OLED, batería mAh, cámaras MP, etc.).
- **Checkout y Generación de Órdenes**: Formulario de compra completo con simulación de pago, validación de stock y generación de código de orden único (`ORD-XXXXXXXX`).
- **Rastreador de Pedidos**: Página dedicada `/track` para consultar el estado en vivo de cualquier orden de compra.

### ⚡ Backend & Arquitectura (FastAPI + SQLAlchemy)
- **Base de Datos SQLite / PostgreSQL**: Integración con SQLAlchemy ORM con inicialización y *seeding* automático del catálogo en el primer arranque.
- **Autenticación y Seguridad JWT**: Hashing seguro de contraseñas con `bcrypt` y tokens JWT para administradores y clientes.
- **Endpoints RESTful Documentados**: Documentación interactiva Swagger UI en `/docs` y ReDoc en `/redoc`.
- **Panel de Administración**: Métricas en tiempo real de facturación, total de órdenes, alertas de stock bajo y formulario para añadir nuevos smartphones al catálogo.

---

## 📁 Estructura del Proyecto

```text
Telefonos-FastApi/
├── app/
│   ├── api/
│   │   ├── v1/
│   │   │   ├── admin.py       # Métricas de ventas y control de inventario
│   │   │   ├── auth.py        # Registro, Login y JWT
│   │   │   ├── brands.py      # CRUD de marcas de celulares
│   │   │   ├── orders.py      # Checkout y rastreo de pedidos
│   │   │   └── phones.py      # Catálogo, filtros avanzados y búsqueda
│   │   └── router.py          # Router maestro de la API
│   ├── core/
│   │   ├── config.py          # Configuración del proyecto y variables
│   │   ├── database.py        # Sesiones de SQLAlchemy y conexión
│   │   ├── security.py        # Hashing de passwords y generación de tokens JWT
│   │   └── seed.py            # Catálogo inicial de smartphones y admin por defecto
│   ├── crud/                  # Capa de acceso a datos (queries & transacciones)
│   ├── models/                # Modelos de base de datos (Phone, Brand, Order, User, Review)
│   ├── schemas/               # Validaciones de entrada/salida con Pydantic
│   ├── static/
│   │   ├── css/style.css      # Estilos modernos Dark Glassmorphism
│   │   └── js/app.js          # Lógica interactiva del cliente (carrito, filtros)
│   ├── templates/             # Vistas Jinja2 (base, storefront, track, admin)
│   └── main.py                # Inicialización de FastAPI, montaje estático y lifespans
├── requirements.txt           # Dependencias de Python
├── run.py                     # Script de arranque rápido
└── README.md
```

---

## 🚀 Cómo Ejecutar el Proyecto

### 1. Instalar dependencias
```bash
pip install -r requirements.txt
```

### 2. Iniciar el servidor
```bash
python run.py
```
*O usando uvicorn directamente:*
```bash
uvicorn app.main:app --reload
```

### 3. Abrir en tu navegador
- 🌐 **Tienda Virtual**: [http://127.0.0.1:8000](http://127.0.0.1:8000)
- 📦 **Rastrear Pedido**: [http://127.0.0.1:8000/track](http://127.0.0.1:8000/track)
- ⚙️ **Panel de Administración**: [http://127.0.0.1:8000/admin](http://127.0.0.1:8000/admin)
- ⚡ **Documentación Swagger API**: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)

---

## 🔑 Credenciales por Defecto (Admin)

Al iniciar la aplicación por primera vez, se genera automáticamente el usuario administrador y el catálogo inicial de celulares (iPhone 15 Pro Max, Galaxy S24 Ultra, Xiaomi 14 Ultra, Pixel 8 Pro, OnePlus 12, etc.):

- **Email**: `admin@electrophone.com`
- **Contraseña**: `admin123456`
