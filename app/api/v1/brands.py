from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.schemas.brand import BrandResponse, BrandCreate, BrandUpdate
from app.crud.brand import get_brands, get_brand, get_brand_by_slug, create_brand, update_brand, delete_brand
from app.api.v1.auth import get_current_admin

router = APIRouter(prefix="/brands", tags=["Marcas"])

@router.get("", response_model=List[BrandResponse])
def read_brands(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Listar todas las marcas de celulares"""
    return get_brands(db, skip=skip, limit=limit)

@router.get("/{brand_id}", response_model=BrandResponse)
def read_brand(brand_id: int, db: Session = Depends(get_db)):
    """Obtener detalle de una marca por ID"""
    brand = get_brand(db, brand_id=brand_id)
    if not brand:
        raise HTTPException(status_code=404, detail="Marca no encontrada")
    return brand

@router.post("", response_model=BrandResponse, status_code=status.HTTP_201_CREATED)
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

@router.put("/{brand_id}", response_model=BrandResponse)
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

@router.delete("/{brand_id}")
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
