from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base

class Review(Base):
    __tablename__ = "reviews"

    id = Column(Integer, primary_key=True, index=True)
    phone_id = Column(Integer, ForeignKey("phones.id", ondelete="CASCADE"), nullable=False)
    user_name = Column(String(100), nullable=False)
    rating = Column(Integer, nullable=False) # 1 to 5
    comment = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    phone = relationship("Phone", back_populates="reviews")
