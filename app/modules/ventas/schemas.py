from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field

class OrderItemCreate(BaseModel):
    phone_id: int
    quantity: int = Field(default=1, gt=0)

class OrderItemResponse(BaseModel):
    id: int
    phone_id: Optional[int] = None
    phone_name: str
    phone_color: Optional[str] = None
    phone_storage: Optional[str] = None
    unit_price: float
    quantity: int
    subtotal: float

    model_config = ConfigDict(from_attributes=True)

class OrderCreate(BaseModel):
    customer_name: str
    customer_email: str
    customer_phone: str
    shipping_address: str
    city: str
    postal_code: Optional[str] = None
    payment_method: str = "credit_card"
    items: List[OrderItemCreate]

class OrderResponse(BaseModel):
    id: int
    order_number: str
    user_id: Optional[int] = None
    customer_name: str
    customer_email: str
    customer_phone: str
    shipping_address: str
    city: str
    postal_code: Optional[str] = None
    subtotal: float
    shipping_cost: float
    tax: float = 0.0
    discount_amount: float
    total: float
    payment_method: str
    payment_status: str
    status: str
    created_at: datetime
    items: List[OrderItemResponse] = []

    model_config = ConfigDict(from_attributes=True)

class OrderStatusUpdate(BaseModel):
    status: str
    payment_status: Optional[str] = None

class CartItemPayload(BaseModel):
    phone_id: int
    quantity: int

class CartCheckoutValidation(BaseModel):
    items: List[CartItemPayload]