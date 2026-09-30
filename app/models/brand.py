from sqlalchemy import Column, Integer, String, Text
from sqlalchemy.orm import relationship
from app.core.database import Base

class Brand(Base):
    __tablename__ = "brands"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False, index=True)
    slug = Column(String(100), unique=True, nullable=False, index=True)
    logo_url = Column(String(255), nullable=True)
    description = Column(Text, nullable=True)

    phones = relationship("Phone", back_populates="brand", cascade="all, delete-orphan")
