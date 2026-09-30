from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.modules.inventario.schemas import (
    BrandResponse, BrandCreate, BrandUpdate,
    PhoneResponse, PhoneCreate, PhoneUpdate
)
from app.modules.inventario.crud import (
    get_brands, get_brand, get_brand_by_slug, create_brand, update_brand, delete_brand,
    get_phones, get_phone, get_phone_by_slug, create_phone, update_phone, delete_phone
)
from app.modules.login.router import get_current_admin

router = APIRouter()

# ==================== BRANDS ====================

brands_router = APIRouter(prefix="/brands", tags=["Marcas"])

@brands_router.get("", response_model=List[BrandResponse])
def read_brands(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Listar todas las marcas de celulares"""
    return get_brands(db, skip=skip, limit=limit)

@brands_router.get("/{brand_id}", response_model=BrandResponse)
def read_brand(brand_id: int, db: Session = Depends(get_db)):
    """Obtener detalle de una marca por ID"""
    brand = get_brand(db, brand_id=brand_id)
    if not brand:
        raise HTTPException(status_code=404, detail="Marca no encontrada")
    return brand

@brands_router.post("", response_model=BrandResponse, status_code=status.HTTP_201_CREATED)
def create_new_brand(
    brand_in: BrandCreate,
    db: Session = Depends(get_db),
    current_admin=Depends(get_current_admin)
):
    """Crear nueva marca (Solo Administradores)"""
    existing = get_brand_by_slug(db, slug=brand_in.slug)
    if existing:
        raise HTTPException(status_code=400, detail="Ya existe una marca con este identificador (slug)")
    return create_brand(db, brand_in=brand_in)

@brands_router.put("/{brand_id}", response_model=BrandResponse)
def update_existing_brand(
    brand_id: int,
    brand_in: BrandUpdate,
    db: Session = Depends(get_db),
    current_admin=Depends(get_current_admin)
):
    """Actualizar marca (Solo Administradores)"""
    brand = get_brand(db, brand_id=brand_id)
    if not brand:
        raise HTTPException(status_code=404, detail="Marca no encontrada")
    return update_brand(db, db_brand=brand, brand_in=brand_in)

@brands_router.delete("/{brand_id}")
def delete_existing_brand(
    brand_id: int,
    db: Session = Depends(get_db),
    current_admin=Depends(get_current_admin)
):
    """Eliminar marca (Solo Administradores)"""
    success = delete_brand(db, brand_id=brand_id)
    if not success:
        raise HTTPException(status_code=404, detail="Marca no encontrada")
    return {"message": "Marca eliminada correctamente"}

# ==================== PHONES ====================

phones_router = APIRouter(prefix="/phones", tags=["Celulares"])

@phones_router.get("", response_model=dict)
def list_phones(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    brand_id: Optional[int] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    ram_gb: Optional[int] = None,
    storage_gb: Optional[int] = None,
    is_5g: Optional[bool] = None,
    is_featured: Optional[bool] = None,
    search: Optional[str] = None,
    sort_by: Optional[str] = "created_at",
    db: Session = Depends(get_db)
):
    """Listar teléfonos celulares con filtros avanzados, búsqueda y paginación"""
    items, total = get_phones(
        db=db,
        skip=skip,
        limit=limit,
        brand_id=brand_id,
        min_price=min_price,
        max_price=max_price,
        ram_gb=ram_gb,
        storage_gb=storage_gb,
        is_5g=is_5g,
        is_featured=is_featured,
        search=search,
        sort_by=sort_by
    )

    # Format items to Pydantic responses
    items_data = [PhoneResponse.model_validate(p) for p in items]

    return {
        "total": total,
        "skip": skip,
        "limit": limit,
        "data": items_data
    }

@phones_router.get("/featured", response_model=List[PhoneResponse])
def get_featured_phones(db: Session = Depends(get_db)):
    """Obtener celulares destacados para el escaparate principal"""
    items, _ = get_phones(db=db, limit=8, is_featured=True)
    return items

@phones_router.get("/{phone_id_or_slug}", response_model=PhoneResponse)
def get_single_phone(phone_id_or_slug: str, db: Session = Depends(get_db)):
    """Obtener detalle de un teléfono por su ID o por su slug SEO friendly"""
    if phone_id_or_slug.isdigit():
        phone = get_phone(db, phone_id=int(phone_id_or_slug))
    else:
        phone = get_phone_by_slug(db, slug=phone_id_or_slug)

    if not phone:
        raise HTTPException(status_code=404, detail="Teléfono no encontrado")
    return phone

@phones_router.post("", response_model=PhoneResponse, status_code=status.HTTP_201_CREATED)
def create_new_phone(
    phone_in: PhoneCreate,
    db: Session = Depends(get_db),
    current_admin=Depends(get_current_admin)
):
    """Crear nuevo teléfono celular (Solo Administradores)"""
    existing = get_phone_by_slug(db, slug=phone_in.slug)
    if existing:
        raise HTTPException(status_code=400, detail="Ya existe un teléfono con este slug identificador")
    return create_phone(db, phone_in=phone_in)

@phones_router.put("/{phone_id}", response_model=PhoneResponse)
def update_existing_phone(
    phone_id: int,
    phone_in: PhoneUpdate,
    db: Session = Depends(get_db),
    current_admin=Depends(get_current_admin)
):
    """Actualizar especificaciones, precio o stock de teléfono (Solo Administradores)"""
    phone = get_phone(db, phone_id=phone_id)
    if not phone:
        raise HTTPException(status_code=404, detail="Teléfono no encontrado")
    return update_phone(db, db_phone=phone, phone_in=phone_in)

@phones_router.delete("/{phone_id}")
def delete_existing_phone(
    phone_id: int,
    db: Session = Depends(get_db),
    current_admin=Depends(get_current_admin)
):
    """Eliminar teléfono celular del catálogo (Solo Administradores)"""
    success = delete_phone(db, phone_id=phone_id)
    if not success:
        raise HTTPException(status_code=404, detail="Teléfono no encontrado")
    return {"message": "Teléfono eliminado del catálogo exitosamente"}

router.include_router(brands_router)
router.include_router(phones_router)