import React from 'react';
import { Store, CheckCircle, XCircle, Package, ListOrdered, TrendingUp } from 'lucide-react';
import { VendorDetailData } from '../../types';
import { StatCard } from '../common/StatCard';
import { ProductsTab } from '../tabs/ProductsTab';
import { OrdersTab } from '../tabs/OrdersTab';

export interface VendorDetailProps {
  data: VendorDetailData | any;
  onStatusChange: (id: string, status: string) => void;
}

export function VendorDetail({ data, onStatusChange }: VendorDetailProps) {
  if (!data || !data.vendor) return null;
  const { vendor, stats, products, recentOrders } = data;

  return (
    <div className="animate-fade-in">
      <div className="card" style={{ display: 'flex', alignItems: 'center', gap: '20px', marginBottom: '24px' }}>
        <div
          style={{
            width: '64px',
            height: '64px',
            backgroundColor: 'var(--color-coral)',
            borderRadius: '16px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center'
          }}
        >
          <Store color="white" size={32} />
        </div>
        <div style={{ flex: 1 }}>
          <h2 style={{ marginBottom: '4px' }}>{vendor.shopName || vendor.fullName}</h2>
          <p style={{ color: 'var(--color-muted)' }}>
            {vendor.email} • {vendor.phone}
          </p>
        </div>
        <div style={{ display: 'flex', gap: '12px' }}>
          {vendor.vendorApprovalStatus !== 'approved' && (
            <button
              onClick={() => onStatusChange(vendor._id, 'approved')}
              className="btn"
              style={{ backgroundColor: 'var(--color-success)' }}
            >
              <CheckCircle size={16} /> Approve
            </button>
          )}
          {vendor.vendorApprovalStatus !== 'suspended' && (
            <button
              onClick={() => onStatusChange(vendor._id, 'suspended')}
              className="btn"
              style={{ backgroundColor: 'var(--color-danger)' }}
            >
              <XCircle size={16} /> Suspend
            </button>
          )}
        </div>
      </div>

      <div className="dashboard-grid" style={{ marginTop: 0 }}>
        <StatCard title="Products" value={stats?.totalProducts || 0} icon={<Package />} color="ink" />
        <StatCard title="Orders" value={stats?.totalOrders || 0} icon={<ListOrdered />} color="warning" />
        <StatCard title="Delivered" value={stats?.deliveredOrders || 0} icon={<CheckCircle />} color="success" />
        <StatCard title="Revenue" value={`Rs. ${stats?.totalRevenue || 0}`} icon={<TrendingUp />} color="coral" />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px' }}>
        <div className="card">
          <h3 style={{ marginBottom: '16px' }}>Shop Products</h3>
          <ProductsTab products={products || []} onDelete={() => {}} onView={() => {}} />
        </div>
        <div className="card">
          <h3 style={{ marginBottom: '16px' }}>Recent Orders</h3>
          <OrdersTab orders={recentOrders || []} />
        </div>
      </div>
    </div>
  );
}

export default VendorDetail;
