from typing import List, Optional, Tuple
from sqlalchemy.orm import Session
from sqlalchemy import or_, desc, asc
from app.models.phone import Phone
from app.schemas.phone import PhoneCreate, PhoneUpdate

def get_phone(db: Session, phone_id: int) -> Optional[Phone]:
    return db.query(Phone).filter(Phone.id == phone_id).first()

def get_phone_by_slug(db: Session, slug: str) -> Optional[Phone]:
    return db.query(Phone).filter(Phone.slug == slug).first()

def get_phones(
    db: Session,
    skip: int = 0,
    limit: int = 50,
    brand_id: Optional[int] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    ram_gb: Optional[int] = None,
    storage_gb: Optional[int] = None,
    is_5g: Optional[bool] = None,
    is_featured: Optional[bool] = None,
    search: Optional[str] = None,
    sort_by: Optional[str] = "created_at"
) -> Tuple[List[Phone], int]:
    query = db.query(Phone).filter(Phone.is_active == True)

    if brand_id:
        query = query.filter(Phone.brand_id == brand_id)
    if min_price is not None:
        query = query.filter(Phone.price >= min_price)
    if max_price is not None:
        query = query.filter(Phone.price <= max_price)
    if ram_gb:
        query = query.filter(Phone.ram_gb == ram_gb)
    if storage_gb:
        query = query.filter(Phone.storage_gb == storage_gb)
    if is_5g is not None:
        query = query.filter(Phone.is_5g == is_5g)
    if is_featured is not None:
        query = query.filter(Phone.is_featured == is_featured)
    if search:
        search_filter = f"%{search.strip()}%"
        query = query.filter(
            or_(
                Phone.name.ilike(search_filter),
                Phone.description.ilike(search_filter),
                Phone.processor.ilike(search_filter),
                Phone.color.ilike(search_filter)
            )
        )

    total_count = query.count()

    # Sorting
    if sort_by == "price_asc":
        query = query.order_by(asc(Phone.price))
    elif sort_by == "price_desc":
        query = query.order_by(desc(Phone.price))
    elif sort_by == "rating":
        query = query.order_by(desc(Phone.rating))
    elif sort_by == "name":
        query = query.order_by(asc(Phone.name))
    else: # default newest
        query = query.order_by(desc(Phone.created_at))

    items = query.offset(skip).limit(limit).all()
    return items, total_count

def create_phone(db: Session, phone_in: PhoneCreate) -> Phone:
    db_phone = Phone(**phone_in.model_dump())
    db.add(db_phone)
    db.commit()
    db.refresh(db_phone)
    return db_phone

def update_phone(db: Session, db_phone: Phone, phone_in: PhoneUpdate) -> Phone:
    update_data = phone_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_phone, field, value)
    db.commit()
    db.refresh(db_phone)
    return db_phone

def delete_phone(db: Session, phone_id: int) -> bool:
    phone = db.query(Phone).filter(Phone.id == phone_id).first()
    if phone:
        db.delete(phone)
        db.commit()
        return True
    return False

def update_stock(db: Session, phone_id: int, quantity_change: int) -> Optional[Phone]:
    phone = db.query(Phone).filter(Phone.id == phone_id).first()
    if phone:
        phone.stock += quantity_change
        if phone.stock < 0:
            phone.stock = 0
        db.commit()
        db.refresh(phone)
        return phone
    return None
