import React from 'react';
import { ListOrdered, CheckCircle } from 'lucide-react';
import { Order } from '../../types';
import { MiniStatCard } from '../common/MiniStatCard';
import { TableSkeleton } from '../common/Skeletons';
import { PaginationFooter } from '../common/PaginationFooter';

export interface OrdersTabProps {
  orders: Order[];
  filters?: {
    page: number;
    limit?: number;
  };
  setPage?: (page: number) => void;
  onView?: (id: string) => void;
}

export function OrdersTab({ orders, onView, filters, setPage }: OrdersTabProps) {
  if (!orders.length && filters?.page === 1) {
    return <TableSkeleton headers={['Order ID', 'Customer', 'Total', 'Status', 'Date']} />;
  }

  const total = orders.length;
  const delivered = orders.filter(o => o.orderStatus === 'Delivered').length;

  return (
    <div className="animate-fade-in">
      <div style={{ display: 'flex', gap: '24px', marginBottom: '24px' }}>
        <MiniStatCard title="Total Orders" value={total} icon={<ListOrdered />} color="ink" />
        <MiniStatCard title="Delivered" value={delivered} icon={<CheckCircle />} color="success" />
      </div>

      <div className="card">
        <div className="table-container" style={{ margin: 0, padding: 0, border: 'none', boxShadow: 'none' }}>
          <table className="data-table" style={{ margin: 0 }}>
            <thead>
              <tr>
                <th>Order ID</th>
                <th>Customer</th>
                <th>Total</th>
                <th>Status</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              {orders.map(o => (
                <tr
                  key={o._id}
                  onClick={() => onView && onView(o._id)}
                  style={{ cursor: onView ? 'pointer' : 'default' }}
                >
                  <td style={{ fontWeight: 500 }}>
                    {o._id ? o._id.substring(o._id.length - 6).toUpperCase() : ''}
                  </td>
                  <td style={{ color: 'var(--color-muted)' }}>
                    {typeof o.customerId === 'object' && o.customerId?.fullName
                      ? o.customerId.fullName
                      : 'Unknown'}
                  </td>
                  <td style={{ fontWeight: 500 }}>Rs. {o.totalAmount}</td>
                  <td>
                    <span
                      className={`status-badge ${
                        o.orderStatus === 'Delivered'
                          ? 'success'
                          : o.orderStatus === 'Cancelled'
                          ? 'danger'
                          : 'warning'
                      }`}
                    >
                      {o.orderStatus}
                    </span>
                  </td>
                  <td style={{ color: 'var(--color-muted)' }}>
                    {o.createdAt ? new Date(o.createdAt).toLocaleDateString() : ''}
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

export default OrdersTab;
