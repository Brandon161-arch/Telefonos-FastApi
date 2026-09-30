from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.brand import Brand
from app.schemas.brand import BrandCreate, BrandUpdate

def get_brand(db: Session, brand_id: int) -> Optional[Brand]:
    return db.query(Brand).filter(Brand.id == brand_id).first()

def get_brand_by_slug(db: Session, slug: str) -> Optional[Brand]:
    return db.query(Brand).filter(Brand.slug == slug).first()

def get_brands(db: Session, skip: int = 0, limit: int = 100) -> List[Brand]:
    return db.query(Brand).offset(skip).limit(limit).all()

def create_brand(db: Session, brand_in: BrandCreate) -> Brand:
    db_brand = Brand(**brand_in.model_dump())
    db.add(db_brand)
    db.commit()
    db.refresh(db_brand)
    return db_brand

def update_brand(db: Session, db_brand: Brand, brand_in: BrandUpdate) -> Brand:
    update_data = brand_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_brand, field, value)
    db.commit()
    db.refresh(db_brand)
    return db_brand

def delete_brand(db: Session, brand_id: int) -> bool:
    brand = db.query(Brand).filter(Brand.id == brand_id).first()
    if brand:
        db.delete(brand)
        db.commit()
        return True
    return False
