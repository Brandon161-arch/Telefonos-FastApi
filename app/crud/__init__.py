from app.crud.brand import get_brand, get_brand_by_slug, get_brands, create_brand, update_brand, delete_brand
from app.crud.phone import get_phone, get_phone_by_slug, get_phones, create_phone, update_phone, delete_phone, update_stock
from app.crud.user import get_user, get_user_by_email, create_user, authenticate_user
from app.crud.order import get_order, get_order_by_number, get_orders, create_order, update_order_status

__all__ = [
    "get_brand", "get_brand_by_slug", "get_brands", "create_brand", "update_brand", "delete_brand",
    "get_phone", "get_phone_by_slug", "get_phones", "create_phone", "update_phone", "delete_phone", "update_stock",
    "get_user", "get_user_by_email", "create_user", "authenticate_user",
    "get_order", "get_order_by_number", "get_orders", "create_order", "update_order_status"
]
