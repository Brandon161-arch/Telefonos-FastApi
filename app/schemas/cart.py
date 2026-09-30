from typing import List, Optional
from pydantic import BaseModel

class CartItemPayload(BaseModel):
    phone_id: int
    quantity: int

class CartCheckoutValidation(BaseModel):
    items: List[CartItemPayload]
