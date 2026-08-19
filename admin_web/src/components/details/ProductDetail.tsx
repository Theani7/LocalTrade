import React from 'react';
import { Package, Star, MapPin, Trash2 } from 'lucide-react';
import { ProductDetailData, Product, User, Vendor } from '../../types';

export interface ProductDetailProps {
  data: ProductDetailData | { product: Product } | any;
  onDelete: (id: string) => void;
}

export function ProductDetail({ data, onDelete }: ProductDetailProps) {
  if (!data || !data.product) return null;
  const p: Product = data.product;
  const rating = p.ratingsAverage || 0;
  const ratingCount = p.ratingsQuantity || 0;

  const vendor = typeof p.vendorId === 'object' && p.vendorId ? (p.vendorId as User | Vendor) : null;
  const vendorInitial = vendor?.shopName
    ? vendor.shopName[0].toUpperCase()
    : vendor?.fullName
    ? vendor.fullName[0].toUpperCase()
    : 'V';

  return (
    <div
      className="animate-fade-in"
      style={{ display: 'flex', flexDirection: 'column', gap: '24px', maxWidth: '900px' }}
    >
      {/* Top Banner / Images */}
      <div className="card" style={{ padding: '24px' }}>
        <div style={{ display: 'flex', gap: '32px' }}>
          <div style={{ width: '280px', display: 'flex', flexDirection: 'column', gap: '12px' }}>
            <div
              style={{
                width: '280px',
                height: '280px',
                borderRadius: '16px',
                backgroundColor: 'var(--color-cream)',
                overflow: 'hidden'
              }}
            >
              {p.images && p.images.length > 0 ? (
                <img
                  src={p.images[0]}
                  alt={p.title}
                  style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                />
              ) : (
                <Package
                  size={64}
                  color="var(--color-muted)"
                  style={{ margin: '108px' }}
                />
              )}
            </div>
            {p.images && p.images.length > 1 && (
              <div style={{ display: 'flex', gap: '8px', overflowX: 'auto' }}>
                {p.images.slice(1).map((img, i) => (
                  <img
                    key={i}
                    src={img}
                    alt={`${p.title} preview ${i + 1}`}
                    style={{ width: '60px', height: '60px', borderRadius: '8px', objectFit: 'cover' }}
                  />
                ))}
              </div>
            )}
          </div>

          <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
            <div
              style={{
                display: 'inline-block',
                padding: '4px 12px',
                backgroundColor: 'rgba(43,38,32,0.05)',
                borderRadius: '100px',
                fontSize: '12px',
                fontWeight: '500',
                color: 'var(--color-muted)',
                alignSelf: 'flex-start',
                marginBottom: '12px'
              }}
            >
              {p.category || 'Uncategorized'}
            </div>

            <h2 style={{ fontSize: '32px', marginBottom: '12px', lineHeight: '1.2' }}>{p.title}</h2>

            <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '24px' }}>
              <p style={{ color: 'var(--color-coral)', fontSize: '28px', fontWeight: '600' }}>
                Rs. {p.price}{' '}
                <span style={{ fontSize: '15px', color: 'var(--color-muted)' }}>
                  / {p.priceUnit || 'item'}
                </span>
              </p>
              {p.originalPrice && (
                <p
                  style={{
                    fontSize: '16px',
                    color: 'var(--color-muted)',
                    textDecoration: 'line-through'
                  }}
                >
                  Rs. {p.originalPrice}
                </p>
              )}
            </div>

            <div
              style={{
                display: 'flex',
                gap: '32px',
                marginBottom: '24px',
                paddingBottom: '24px',
                borderBottom: '1px solid rgba(43,38,32,0.05)'
              }}
            >
              <div>
                <p style={{ color: 'var(--color-muted)', fontSize: '13px', marginBottom: '4px' }}>
                  Stock
                </p>
                <span
                  className={`status-badge ${p.stockQuantity > 0 ? 'success' : 'danger'}`}
                  style={{ padding: '4px 10px' }}
                >
                  {p.stockQuantity} units
                </span>
              </div>
              <div>
                <p style={{ color: 'var(--color-muted)', fontSize: '13px', marginBottom: '4px' }}>
                  Status
                </p>
                <span
                  className={`status-badge ${p.productStatus === 'Available' ? 'success' : 'warning'}`}
                  style={{ padding: '4px 10px' }}
                >
                  {p.productStatus || 'Unknown'}
                </span>
              </div>
              <div>
                <p style={{ color: 'var(--color-muted)', fontSize: '13px', marginBottom: '4px' }}>
                  Rating
                </p>
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '4px',
                    fontSize: '15px',
                    fontWeight: '500'
                  }}
                >
                  <Star size={16} color="var(--color-warning)" fill="var(--color-warning)" />{' '}
                  {rating.toFixed(1)}{' '}
                  <span style={{ color: 'var(--color-muted)', fontSize: '13px', fontWeight: '400' }}>
                    ({ratingCount})
                  </span>
                </div>
              </div>
            </div>

            <h4 style={{ marginBottom: '8px', fontSize: '16px' }}>Description</h4>
            <p style={{ color: 'var(--color-muted)', lineHeight: '1.6', marginBottom: '24px' }}>
              {p.description || 'No description provided.'}
            </p>

            {p.location && (
              <div
                style={{
                  display: 'flex',
                  gap: '8px',
                  color: 'var(--color-muted)',
                  marginBottom: '24px'
                }}
              >
                <MapPin size={18} />{' '}
                <span style={{ fontSize: '14px', lineHeight: '1.5' }}>
                  {typeof p.location === 'object'
                    ? `${p.location.street || ''}, ${p.location.city || ''}`
                    : p.location}
                </span>
              </div>
            )}

            <div style={{ marginTop: 'auto', display: 'flex', justifyContent: 'flex-end' }}>
              <button
                onClick={() => onDelete(p._id)}
                className="btn"
                style={{
                  backgroundColor: 'white',
                  color: 'var(--color-danger)',
                  border: '1px solid rgba(211,47,47,0.3)'
                }}
              >
                <Trash2 size={16} /> Delete Product
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Vendor Info Card */}
      {p.vendorId && (
        <div className="card" style={{ padding: '24px' }}>
          <h3 style={{ marginBottom: '16px', fontSize: '18px' }}>Vendor Information</h3>
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '16px',
              backgroundColor: 'var(--color-cream)',
              padding: '16px',
              borderRadius: '12px'
            }}
          >
            <div
              style={{
                width: '48px',
                height: '48px',
                borderRadius: '50%',
                backgroundColor: 'var(--color-coral)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: 'white',
                fontSize: '20px',
                fontWeight: '600'
              }}
            >
              {vendorInitial}
            </div>
            <div>
              <p style={{ fontWeight: '600', fontSize: '16px', marginBottom: '4px' }}>
                {vendor?.shopName || p.vendorName || 'Unknown Vendor'}
              </p>
              <p style={{ color: 'var(--color-muted)', fontSize: '14px' }}>
                {vendor?.fullName || ''} {vendor?.email ? `• ${vendor.email}` : ''}
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default ProductDetail;
