import React from 'react';
import { Store, CheckCircle } from 'lucide-react';
import { Vendor } from '../../types';
import { MiniStatCard } from '../common/MiniStatCard';
import { TableSkeleton } from '../common/Skeletons';
import { PaginationFooter } from '../common/PaginationFooter';

export interface VendorsTabProps {
  vendors: Vendor[];
  filters?: {
    page: number;
    limit?: number;
    status?: string;
  };
  setPage?: (page: number) => void;
  onStatusChange?: (id: string, status: string) => void;
  onView: (id: string) => void;
}

export function VendorsTab({
  vendors,
  onStatusChange: _onStatusChange,
  onView,
  filters,
  setPage
}: VendorsTabProps) {
  if (!vendors.length && filters?.page === 1) {
    return <TableSkeleton headers={['Shop Name', 'Owner', 'Status', 'Products', 'Actions']} />;
  }

  const total = vendors.length;
  const approved = vendors.filter(v => v.vendorApprovalStatus === 'approved').length;

  return (
    <div className="animate-fade-in">
      <div style={{ display: 'flex', gap: '24px', marginBottom: '24px' }}>
        <MiniStatCard title="Total Vendors" value={total} icon={<Store />} color="ink" />
        <MiniStatCard title="Approved" value={approved} icon={<CheckCircle />} color="success" />
      </div>

      <div className="card">
        <div className="table-container" style={{ margin: 0, padding: 0, border: 'none', boxShadow: 'none' }}>
          <table className="data-table" style={{ margin: 0 }}>
            <thead>
              <tr>
                <th>Shop Name</th>
                <th>Owner</th>
                <th>Status</th>
                <th>Products</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {vendors.map(v => (
                <tr key={v._id}>
                  <td style={{ fontWeight: 500 }}>{v.shopName || 'N/A'}</td>
                  <td style={{ color: 'var(--color-muted)' }}>{v.fullName}</td>
                  <td>
                    <span
                      className={`status-badge ${
                        v.vendorApprovalStatus === 'approved'
                          ? 'success'
                          : v.vendorApprovalStatus === 'suspended'
                          ? 'danger'
                          : 'warning'
                      }`}
                    >
                      {v.vendorApprovalStatus}
                    </span>
                  </td>
                  <td>{v.productCount || 0}</td>
                  <td>
                    <div style={{ display: 'flex', gap: '8px' }}>
                      <button
                        onClick={() => onView(v._id)}
                        className="btn"
                        style={{
                          padding: '6px 12px',
                          fontSize: '13px',
                          backgroundColor: 'var(--color-cream)',
                          color: 'var(--color-ink)'
                        }}
                      >
                        View Detail
                      </button>
                    </div>
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

export default VendorsTab;
