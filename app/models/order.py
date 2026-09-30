from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from app.core.database import Base

class Order(Base):
    __tablename__ = "orders"

    id = Column(Integer, primary_key=True, index=True)
    order_number = Column(String(50), unique=True, index=True, nullable=False)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    
    # Customer details (can be guest checkout or logged in user)
    customer_name = Column(String(150), nullable=False)
    customer_email = Column(String(255), nullable=False)
    customer_phone = Column(String(30), nullable=False)
    shipping_address = Column(String(300), nullable=False)
    city = Column(String(100), nullable=False)
    postal_code = Column(String(20), nullable=True)
    
    # Financials & Status
    subtotal = Column(Float, nullable=False)
    shipping_cost = Column(Float, default=0.0)
    discount_amount = Column(Float, default=0.0)
    total = Column(Float, nullable=False)
    
    payment_method = Column(String(50), default="credit_card") # 'credit_card', 'paypal', 'transfer', 'cash_on_delivery'
    payment_status = Column(String(50), default="completed")    # 'pending', 'completed', 'failed'
    status = Column(String(50), default="processing")           # 'pending', 'processing', 'shipped', 'delivered', 'cancelled'
    
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="orders")
    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")


class OrderItem(Base):
    __tablename__ = "order_items"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(Integer, ForeignKey("orders.id", ondelete="CASCADE"), nullable=False)
    phone_id = Column(Integer, ForeignKey("phones.id", ondelete="SET NULL"), nullable=True)
    
    # Snapshot data in case product changes later
    phone_name = Column(String(200), nullable=False)
    phone_color = Column(String(50), nullable=True)
    phone_storage = Column(String(50), nullable=True)
    unit_price = Column(Float, nullable=False)
    quantity = Column(Integer, default=1, nullable=False)
    subtotal = Column(Float, nullable=False)

    # Relationships
    order = relationship("Order", back_populates="items")
    phone = relationship("Phone", back_populates="order_items")
