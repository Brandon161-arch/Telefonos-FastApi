import React, { useState, useEffect, useCallback } from 'react';
import { useSearchParams } from 'react-router-dom';
import apiClient from '../api/client';
import PhoneCard from '../components/PhoneCard';
import QuickSpecModal from '../components/QuickSpecModal';
import { formatCOP } from '../utils/formatters';
import { useAuth } from '../context/AuthContext';
import { useToast } from '../context/ToastContext';
import {
  SlidersHorizontal,
  RotateCcw,
  Sparkles,
  Search,
  Check,
  ChevronLeft,
  ChevronRight,
  TrendingUp,
  ShieldCheck,
  Zap
} from 'lucide-react';

export default function HomePage({ globalSearch }) {
  const [searchParams, setSearchParams] = useSearchParams();
  const { isAuthenticated } = useAuth();
  const { showToast } = useToast();

  const [brands, setBrands] = useState([]);
  const [phones, setPhones] = useState([]);
  const [totalCount, setTotalCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Estados de filtros
  const [selectedBrand, setSelectedBrand] = useState(searchParams.get('brand') || '');
  const [maxPrice, setMaxPrice] = useState(Number(searchParams.get('max_price')) || 7000000);
  const [selectedRam, setSelectedRam] = useState(Number(searchParams.get('ram')) || '');
  const [selectedStorage, setSelectedStorage] = useState(Number(searchParams.get('storage')) || '');
  const [is5GOnly, setIs5GOnly] = useState(searchParams.get('is_5g') === 'true');
  const [sortBy, setSortBy] = useState(searchParams.get('sort_by') || 'created_at');
  const [currentPage, setCurrentPage] = useState(1);
  const pageSize = 12;

  // Favoritos del usuario
  const [favoriteIds, setFavoriteIds] = useState(new Set());

  // Modal rápido de specs
  const [quickSpecPhone, setQuickSpecPhone] = useState(null);

  // Cargar marcas iniciales
  useEffect(() => {
    async function loadBrands() {
      try {
        const response = await apiClient.get('/brands');
        setBrands(response.data);
      } catch (err) {
        console.error('Error al cargar marcas:', err);
      }
    }
    loadBrands();
  }, []);

  // Cargar favoritos del usuario si está logueado
  useEffect(() => {
    if (isAuthenticated) {
      apiClient.get('/favorites')
        .then((res) => {
          setFavoriteIds(new Set(res.data.map((p) => p.id)));
        })
        .catch(() => {});
    } else {
      setFavoriteIds(new Set());
    }
  }, [isAuthenticated]);

  // Cargar catálogo de celulares con filtros
  const fetchPhones = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const params = {
        skip: (currentPage - 1) * pageSize,
        limit: pageSize,
        sort_by: sortBy,
      };

      if (selectedBrand) {
        // Encontrar brand_id si se seleccionó slug
        const b = brands.find((br) => br.slug === selectedBrand || br.id === Number(selectedBrand));
        if (b) params.brand_id = b.id;
      }
      if (maxPrice && maxPrice < 7000000) {
        params.max_price = maxPrice;
      }
      if (selectedRam) {
        params.ram_gb = selectedRam;
      }
      if (selectedStorage) {
        params.storage_gb = selectedStorage;
      }
      if (is5GOnly) {
        params.is_5g = true;
      }
      if (globalSearch && globalSearch.trim()) {
        params.search = globalSearch.trim();
      }

      const response = await apiClient.get('/phones', { params });
      setPhones(response.data.data || []);
      setTotalCount(response.data.total || 0);
    } catch (err) {
      console.error('Error al obtener celulares:', err);
      setError('No pudimos conectar con el servidor de la tienda. Verifica que el backend esté en ejecución.');
    } finally {
      setLoading(false);
    }
  }, [brands, currentPage, globalSearch, is5GOnly, maxPrice, selectedBrand, selectedRam, selectedStorage, sortBy]);

  useEffect(() => {
    fetchPhones();
  }, [fetchPhones]);

  // Toggle de favoritos
  const handleToggleFavorite = async (phoneId) => {
    if (!isAuthenticated) {
      showToast('Inicia sesión para guardar favoritos', 'info');
      return;
    }
    const isFav = favoriteIds.has(phoneId);
    try {
      if (isFav) {
        await apiClient.delete(`/favorites/${phoneId}`);
        setFavoriteIds((prev) => {
          const next = new Set(prev);
          next.delete(phoneId);
          return next;
        });
        showToast('Eliminado de favoritos', 'info');
      } else {
        await apiClient.post(`/favorites/${phoneId}`);
        setFavoriteIds((prev) => new Set(prev).add(phoneId));
        showToast('¡Guardado en tus favoritos!', 'success');
      }
    } catch (err) {
      showToast('Error al actualizar favoritos', 'error');
    }
  };

  const handleResetFilters = () => {
    setSelectedBrand('');
    setMaxPrice(7000000);
    setSelectedRam('');
    setSelectedStorage('');
    setIs5GOnly(false);
    setSortBy('created_at');
    setCurrentPage(1);
    setSearchParams({});
  };

  const totalPages = Math.ceil(totalCount / pageSize);

  return (
    <div className="catalog-page-container">
      {/* Hero Banner */}
      <section className="hero-banner glass">
        <div className="hero-content">
          <div className="hero-badge">
            <Sparkles size={16} color="#818cf8" />
            <span>Los smartphones más potentes del 2026</span>
          </div>
          <h1 className="hero-title">
            Encuentra tu próximo celular con <span className="gradient-text">Garantía Oficial</span>
          </h1>
          <p className="hero-subtitle">
            Equipos 100% nuevos, libres y homologados para todos los operadores en Colombia. Envío gratis en órdenes superiores a <strong>$ 1.200.000 COP</strong>.
          </p>

          <div className="hero-quick-badges">
            <div className="hero-stat-badge">
              <Zap size={16} color="#06b6d4" />
              <span>Conectividad 5G Alta Velocidad</span>
            </div>
            <div className="hero-stat-badge">
              <ShieldCheck size={16} color="#10b981" />
              <span>Garantía de 12 Meses</span>
            </div>
            <div className="hero-stat-badge">
              <TrendingUp size={16} color="#f59e0b" />
              <span>Precios con IVA 19% Incluido</span>
            </div>
          </div>
        </div>
      </section>

      {/* Layout Principal: Filtros + Catálogo */}
      <div className="catalog-layout">
        {/* Barra Lateral de Filtros */}
        <aside className="filters-sidebar glass">
          <div className="filters-header">
            <div className="filters-title">
              <SlidersHorizontal size={18} color="#818cf8" />
              <h3>Filtros</h3>
            </div>
            <button className="btn-reset-filters" onClick={handleResetFilters} title="Limpiar todos los filtros">
              <RotateCcw size={14} />
              <span>Limpiar</span>
            </button>
          </div>

          {/* Filtro por Marca */}
          <div className="filter-group">
            <label className="filter-label">Marca</label>
            <div className="filter-chips-list">
              <button
                className={`filter-chip ${selectedBrand === '' ? 'active' : ''}`}
                onClick={() => { setSelectedBrand(''); setCurrentPage(1); }}
              >
                Todas
              </button>
              {brands.map((b) => (
                <button
                  key={b.id}
                  className={`filter-chip ${selectedBrand === b.slug ? 'active' : ''}`}
                  onClick={() => { setSelectedBrand(b.slug); setCurrentPage(1); }}
                >
                  {b.name}
                </button>
              ))}
            </div>
          </div>

          {/* Filtro por Rango de Precio en COP */}
          <div className="filter-group">
            <div className="slider-label-row">
              <label className="filter-label">Precio Máximo</label>
              <span className="slider-value-display">{formatCOP(maxPrice)}</span>
            </div>
            <input
              type="range"
              min="1000000"
              max="7000000"
              step="100000"
              value={maxPrice}
              onChange={(e) => { setMaxPrice(Number(e.target.value)); setCurrentPage(1); }}
              className="price-slider-input"
            />
            <div className="slider-ticks">
              <span>$ 1M</span>
              <span>$ 4M</span>
              <span>$ 7M COP</span>
            </div>
          </div>

          {/* Filtro por Memoria RAM */}
          <div className="filter-group">
            <label className="filter-label">Memoria RAM</label>
            <div className="filter-buttons-grid">
              {[6, 8, 12, 16].map((ram) => (
                <button
                  key={ram}
                  className={`filter-btn-option ${selectedRam === ram ? 'active' : ''}`}
                  onClick={() => {
                    setSelectedRam(selectedRam === ram ? '' : ram);
                    setCurrentPage(1);
                  }}
                >
                  {ram} GB
                </button>
              ))}
            </div>
          </div>

          {/* Filtro por Almacenamiento */}
          <div className="filter-group">
            <label className="filter-label">Almacenamiento</label>
            <div className="filter-buttons-grid">
              {[128, 256, 512, 1024].map((storage) => (
                <button
                  key={storage}
                  className={`filter-btn-option ${selectedStorage === storage ? 'active' : ''}`}
                  onClick={() => {
                    setSelectedStorage(selectedStorage === storage ? '' : storage);
                    setCurrentPage(1);
                  }}
                >
                  {storage === 1024 ? '1 TB' : `${storage} GB`}
                </button>
              ))}
            </div>
          </div>

          {/* Interruptor 5G */}
          <div className="filter-group">
            <label className="filter-checkbox-label">
              <input
                type="checkbox"
                checked={is5GOnly}
                onChange={(e) => { setIs5GOnly(e.target.checked); setCurrentPage(1); }}
              />
              <span className="custom-checkbox"></span>
              <span>Solo dispositivos con red 5G</span>
            </label>
          </div>
        </aside>

        {/* Sección de Productos */}
        <main className="catalog-products-main">
          {/* Barra de cabecera del catálogo: Conteo y Ordenamiento */}
          <div className="catalog-toolbar glass">
            <div className="catalog-count-info">
              {loading ? (
                <span>Buscando smartphones...</span>
              ) : (
                <span>Mostrando <strong>{phones.length}</strong> de <strong>{totalCount}</strong> resultados</span>
              )}
            </div>

            <div className="catalog-sort-select">
              <label htmlFor="sort-by">Ordenar por:</label>
              <select
                id="sort-by"
                value={sortBy}
                onChange={(e) => { setSortBy(e.target.value); setCurrentPage(1); }}
              >
                <option value="created_at">Más Recientes</option>
                <option value="price_asc">Precio: Menor a Mayor</option>
                <option value="price_desc">Precio: Mayor a Menor</option>
                <option value="rating">Mejor Calificados</option>
                <option value="name">Nombre: A - Z</option>
              </select>
            </div>
          </div>

          {/* Estados de Carga / Error / Vacío / Grid */}
          {error && (
            <div className="catalog-error-box glass">
              <p>{error}</p>
              <button className="btn-primary" onClick={fetchPhones}>Reintentar</button>
            </div>
          )}

          {loading ? (
            <div className="catalog-loading-grid">
              {[...Array(6)].map((_, i) => (
                <div key={i} className="product-skeleton-card glass">
                  <div className="skeleton-img"></div>
                  <div className="skeleton-line" style={{ width: '40%' }}></div>
                  <div className="skeleton-line" style={{ width: '80%' }}></div>
                  <div className="skeleton-line" style={{ width: '60%' }}></div>
                </div>
              ))}
            </div>
          ) : phones.length === 0 ? (
            <div className="catalog-empty-state glass">
              <Search size={48} color="#6b7280" />
              <h3>No se encontraron teléfonos con los filtros seleccionados</h3>
              <p>Prueba ajustando el rango de precio o seleccionando otra marca.</p>
              <button className="btn-secondary" onClick={handleResetFilters}>
                Restablecer Filtros
              </button>
            </div>
          ) : (
            <div className="products-grid">
              {phones.map((phone) => (
                <PhoneCard
                  key={phone.id}
                  phone={phone}
                  onOpenQuickSpec={(p) => setQuickSpecPhone(p)}
                  isFavorite={favoriteIds.has(phone.id)}
                  onToggleFavorite={handleToggleFavorite}
                />
              ))}
            </div>
          )}

          {/* Paginación */}
          {totalPages > 1 && (
            <div className="pagination-bar">
              <button
                className="btn-page-nav"
                disabled={currentPage <= 1}
                onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
              >
                <ChevronLeft size={16} /> Anterior
              </button>

              <span className="pagination-page-indicator">
                Página {currentPage} de {totalPages}
              </span>

              <button
                className="btn-page-nav"
                disabled={currentPage >= totalPages}
                onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
              >
                Siguiente <ChevronRight size={16} />
              </button>
            </div>
          )}
        </main>
      </div>

      {/* Modal de Especificaciones Rápidas */}
      {quickSpecPhone && (
        <QuickSpecModal
          phone={quickSpecPhone}
          onClose={() => setQuickSpecPhone(null)}
        />
      )}
    </div>
  );
}
