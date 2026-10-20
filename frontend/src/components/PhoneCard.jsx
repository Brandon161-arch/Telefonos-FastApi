import React from 'react';
import { Link } from 'react-router-dom';
import { ShoppingCart, Eye, Star, Heart, Check, Cpu, HardDrive } from 'lucide-react';
import { formatCOP } from '../utils/formatters';
import { useCart } from '../context/CartContext';

export default function PhoneCard({ phone, onOpenQuickSpec, isFavorite, onToggleFavorite }) {
  const { addToCart } = useCart();

  const hasDiscount = phone.discount_price && phone.discount_price > 0 && phone.discount_price < phone.price;
  const discountPercent = hasDiscount
    ? Math.round(((phone.price - phone.discount_price) / phone.price) * 100)
    : 0;

  return (
    <div className="product-card glass">
      {/* Badges superiores */}
      <div className="product-card-badges">
        {hasDiscount && (
          <span className="badge badge-discount">-{discountPercent}%</span>
        )}
        {phone.is_5g && (
          <span className="badge badge-5g">5G</span>
        )}
      </div>

      {/* Botón de Favorito */}
      <button
        className={`btn-fav ${isFavorite ? 'active' : ''}`}
        onClick={(e) => {
          e.preventDefault();
          e.stopPropagation();
          if (onToggleFavorite) onToggleFavorite(phone.id);
        }}
        title={isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos'}
        aria-label="Favorito"
      >
        <Heart size={18} fill={isFavorite ? '#ef4444' : 'none'} color={isFavorite ? '#ef4444' : '#9ca3af'} />
      </button>

      {/* Imagen */}
      <Link to={`/phone/${phone.slug}`} className="product-card-img-wrap">
        <img
          src={phone.image_url}
          alt={phone.name}
          loading="lazy"
          className="product-card-img"
          onError={(e) => {
            e.target.src = 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=600&auto=format&fit=crop&q=80';
          }}
        />
      </Link>

      {/* Contenido */}
      <div className="product-card-body">
        <div className="product-brand-tag">
          {phone.brand?.name || 'Smartphone'}
        </div>

        <h3 className="product-title">
          <Link to={`/phone/${phone.slug}`}>{phone.name}</Link>
        </h3>

        {/* Ficha técnica mínima */}
        <div className="product-specs-chips">
          <span className="spec-chip">
            <Cpu size={12} style={{ display: 'inline', marginRight: '3px' }} />
            {phone.ram_gb} GB RAM
          </span>
          <span className="spec-chip">
            <HardDrive size={12} style={{ display: 'inline', marginRight: '3px' }} />
            {phone.storage_gb} GB
          </span>
          <span className="spec-chip color-chip">
            {phone.color}
          </span>
        </div>

        {/* Rating */}
        <div className="product-rating">
          <div className="stars">
            {[...Array(5)].map((_, i) => (
              <Star
                key={i}
                size={14}
                fill={i < Math.floor(phone.rating) ? '#f59e0b' : 'none'}
                color="#f59e0b"
              />
            ))}
          </div>
          <span className="rating-value">{phone.rating.toFixed(1)}</span>
          <span className="rating-count">({phone.rating_count})</span>
        </div>

        {/* Precios en COP */}
        <div className="product-price-wrap">
          {hasDiscount ? (
            <>
              <span className="price-current">{formatCOP(phone.discount_price)}</span>
              <span className="price-original">{formatCOP(phone.price)}</span>
            </>
          ) : (
            <span className="price-current">{formatCOP(phone.price)}</span>
          )}
        </div>

        {/* Stock status */}
        <div className="product-stock-status">
          {phone.stock > 0 ? (
            <span className="stock-available">
              <Check size={12} style={{ display: 'inline', marginRight: '4px' }} />
              {phone.stock <= 5 ? `¡Solo ${phone.stock} disponibles!` : 'Disponible para entrega inmediata'}
            </span>
          ) : (
            <span className="stock-out">Agotado</span>
          )}
        </div>

        {/* Acciones */}
        <div className="product-card-actions">
          <button
            className="btn-add-cart"
            onClick={() => addToCart(phone, 1)}
            disabled={phone.stock <= 0}
          >
            <ShoppingCart size={16} />
            {phone.stock > 0 ? 'Agregar' : 'Agotado'}
          </button>

          <button
            className="btn-quick-view"
            onClick={() => onOpenQuickSpec && onOpenQuickSpec(phone)}
            title="Especificaciones rápidas"
            aria-label="Ver ficha rápida"
          >
            <Eye size={16} />
          </button>
        </div>
      </div>
    </div>
  );
}
