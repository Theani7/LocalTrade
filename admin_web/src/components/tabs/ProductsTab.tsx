import React from 'react';
import { Package, CheckCircle } from 'lucide-react';
import { Product } from '../../types';
import { MiniStatCard } from '../common/MiniStatCard';
import { TableSkeleton } from '../common/Skeletons';
import { PaginationFooter } from '../common/PaginationFooter';

export interface ProductsTabProps {
  products: Product[];
  stats?: {
    totalProducts?: number;
    availableProducts?: number;
    [key: string]: any;
  } | null;
  filters?: {
    page: number;
    limit?: number;
  };
  setPage?: (page: number) => void;
  onDelete?: (id: string) => void;
  onView?: (id: string) => void;
}

export function ProductsTab({
  products,
  stats,
  onDelete: _onDelete,
  onView,
  filters,
  setPage
}: ProductsTabProps) {
  if (!products.length && filters?.page === 1) {
    return <TableSkeleton headers={['Product Name', 'Category', 'Price', 'Stock', 'Actions']} />;
  }

  const total = stats?.totalProducts ?? products.length;
  const inStock = stats?.availableProducts ?? products.filter(p => p.stockQuantity > 0).length;

  return (
    <div className="animate-fade-in">
      <div style={{ display: 'flex', gap: '24px', marginBottom: '24px' }}>
        <MiniStatCard title="Total Products" value={total} icon={<Package />} color="ink" />
        <MiniStatCard title="In Stock" value={inStock} icon={<CheckCircle />} color="success" />
      </div>

      <div className="card">
        <div className="table-container" style={{ margin: 0, padding: 0, border: 'none', boxShadow: 'none' }}>
          <table className="data-table" style={{ margin: 0 }}>
            <thead>
              <tr>
                <th>Product Name</th>
                <th>Category</th>
                <th>Price</th>
                <th>Stock</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {products.map(p => (
                <tr key={p._id}>
                  <td style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    {p.images && p.images.length > 0 ? (
                      <img
                        src={p.images[0]}
                        alt={p.title}
                        style={{ width: '40px', height: '40px', borderRadius: '8px', objectFit: 'cover' }}
                      />
                    ) : (
                      <div
                        style={{
                          width: '40px',
                          height: '40px',
                          backgroundColor: 'var(--color-cream)',
                          borderRadius: '8px',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center'
                        }}
                      >
                        <Package size={20} color="var(--color-muted)" />
                      </div>
                    )}
                    <span style={{ fontWeight: 500 }}>{p.title}</span>
                  </td>
                  <td style={{ color: 'var(--color-muted)' }}>{p.category}</td>
                  <td>Rs. {p.price}</td>
                  <td>
                    <span className={`status-badge ${p.stockQuantity > 0 ? 'success' : 'danger'}`}>
                      {p.stockQuantity}
                    </span>
                  </td>
                  <td>
                    {onView && (
                      <button
                        onClick={() => onView(p._id)}
                        className="btn"
                        style={{
                          padding: '6px 12px',
                          fontSize: '13px',
                          backgroundColor: 'var(--color-cream)',
                          color: 'var(--color-ink)'
                        }}
                      >
                        View
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {filters && setPage && (
          <PaginationFooter page={filters.page} setPage={setPage} />
        )}
      </div>
    </div>
  );
}

export default ProductsTab;
