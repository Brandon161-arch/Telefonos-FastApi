from typing import Optional, List
from sqlalchemy.orm import Session
from app.models.user import User
from app.schemas.user import UserCreate
from app.core.security import get_password_hash, verify_password

def get_user(db: Session, user_id: int) -> Optional[User]:
    return db.query(User).filter(User.id == user_id).first()

def get_user_by_email(db: Session, email: str) -> Optional[User]:
    return db.query(User).filter(User.email == email.lower()).first()

def create_user(db: Session, user_in: UserCreate, is_admin: bool = False) -> User:
    db_user = User(
        full_name=user_in.full_name,
        email=user_in.email.lower(),
        hashed_password=get_password_hash(user_in.password),
        phone_number=user_in.phone_number,
        address=user_in.address,
        is_admin=is_admin
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def authenticate_user(db: Session, email: str, password: str) -> Optional[User]:
    user = get_user_by_email(db, email)
    if not user:
        return None
    if not verify_password(password, user.hashed_password):
        return None
    return user
