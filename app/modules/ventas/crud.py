import uuid
from typing import List, Optional
from sqlalchemy.orm import Session
from app.modules.ventas.models import Order, OrderItem
from app.modules.inventario.models import Phone
from app.modules.ventas.schemas import OrderCreate, OrderStatusUpdate
from app.modules.login.emails import send_order_confirmation_email

def generate_order_number() -> str:
    return f"ORD-{uuid.uuid4().hex[:8].upper()}"

def get_order(db: Session, order_id: int) -> Optional[Order]:
    return db.query(Order).filter(Order.id == order_id).first()

def get_order_by_number(db: Session, order_number: str) -> Optional[Order]:
    return db.query(Order).filter(Order.order_number == order_number).first()

def get_orders(db: Session, skip: int = 0, limit: int = 100, user_id: Optional[int] = None) -> List[Order]:
    query = db.query(Order)
    if user_id:
        query = query.filter(Order.user_id == user_id)
    return query.order_by(Order.created_at.desc()).offset(skip).limit(limit).all()

def create_order(db: Session, order_in: OrderCreate, user_id: Optional[int] = None) -> Order:
    # 1. Calculate items subtotal and verify stock
    subtotal = 0.0
    items_to_create = []

    for item_in in order_in.items:
        phone = db.query(Phone).filter(Phone.id == item_in.phone_id).with_for_update().first()
        if not phone:
            raise ValueError(f"El teléfono con ID {item_in.phone_id} no existe")
        if phone.stock < item_in.quantity:
            raise ValueError(f"Stock insuficiente para '{phone.name}'. Disponibles: {phone.stock}")

        item_price = phone.discount_price if phone.discount_price and phone.discount_price > 0 else phone.price
        item_subtotal = item_price * item_in.quantity
        subtotal += item_subtotal

        # Deduct stock
        phone.stock -= item_in.quantity

        order_item = OrderItem(
            phone_id=phone.id,
            phone_name=phone.name,
            phone_color=phone.color,
            phone_storage=f"{phone.storage_gb} GB",
            unit_price=item_price,
            quantity=item_in.quantity,
            subtotal=item_subtotal
        )
        items_to_create.append(order_item)

    shipping_cost = 0.0 if subtotal > 1200000 else 20000.0 # Envío gratis para compras mayores a $1.200.000 COP
    tax = round((subtotal + shipping_cost) * 0.19, 2)  # IVA 19% Colombia
    total = subtotal + shipping_cost + tax

    # 2. Create order record
    db_order = Order(
        order_number=generate_order_number(),
        user_id=user_id,
        customer_name=order_in.customer_name,
        customer_email=order_in.customer_email,
        customer_phone=order_in.customer_phone,
        shipping_address=order_in.shipping_address,
        city=order_in.city,
        postal_code=order_in.postal_code,
        subtotal=subtotal,
        shipping_cost=shipping_cost,
        tax=tax,
        discount_amount=0.0,
        total=total,
        payment_method=order_in.payment_method,
        payment_status="completed",
        status="processing"
    )
    db.add(db_order)
    db.flush() # Flush to get db_order.id

    for item in items_to_create:
        item.order_id = db_order.id
        db.add(item)

    db.commit()
    db.refresh(db_order)

    # Enviar correo de confirmación de compra (no bloquea la orden si falla)
    try:
        send_order_confirmation_email(
            to_email=db_order.customer_email,
            customer_name=db_order.customer_name,
            order={
                "order_number": db_order.order_number,
                "total": db_order.total,
                "payment_method": db_order.payment_method,
                "shipping_address": db_order.shipping_address,
                "city": db_order.city,
                "items": [
                    {"phone_name": i.phone_name, "quantity": i.quantity, "subtotal": i.subtotal}
                    for i in db_order.items
                ],
            },
        )
    except Exception as exc:
        print(f"[WARN] No se pudo enviar el correo de confirmación: {exc}")

    return db_order

def update_order_status(db: Session, order: Order, status_update: OrderStatusUpdate) -> Order:
    order.status = status_update.status
    if status_update.payment_status:
        order.payment_status = status_update.payment_status
    db.commit()
    db.refresh(order)
    return order