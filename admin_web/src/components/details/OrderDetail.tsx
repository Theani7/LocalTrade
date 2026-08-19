import React from 'react';
import { Order, User, Vendor } from '../../types';

export interface OrderDetailProps {
  data: Order | any;
}

export function OrderDetail({ data }: OrderDetailProps) {
  if (!data) return null;
  const o = data;

  const customerName =
    typeof o.customerId === 'object' && o.customerId?.fullName
      ? o.customerId.fullName
      : 'Unknown';

  const vendor = typeof o.vendorId === 'object' && o.vendorId ? (o.vendorId as User | Vendor) : null;
  const vendorName = vendor?.shopName || vendor?.fullName || 'Unknown';

  const orderIdShort = o._id ? o._id.substring(o._id.length - 6).toUpperCase() : '';

  return (
    <div className="animate-fade-in card" style={{ maxWidth: '800px' }}>
      <h2 style={{ marginBottom: '16px' }}>Order #{orderIdShort}</h2>
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: '1fr 1fr',
          gap: '24px',
          marginBottom: '24px'
        }}
      >
        <div>
          <p style={{ color: 'var(--color-muted)', fontSize: '14px' }}>Customer</p>
          <p style={{ fontWeight: '500' }}>{customerName}</p>
        </div>
        <div>
          <p style={{ color: 'var(--color-muted)', fontSize: '14px' }}>Vendor</p>
          <p style={{ fontWeight: '500' }}>{vendorName}</p>
        </div>
        <div>
          <p style={{ color: 'var(--color-muted)', fontSize: '14px' }}>Status</p>
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
        </div>
        <div>
          <p style={{ color: 'var(--color-muted)', fontSize: '14px' }}>Total Amount</p>
          <p style={{ fontWeight: '600', fontSize: '18px', color: 'var(--color-coral)' }}>
            Rs. {o.totalAmount}
          </p>
        </div>
      </div>
      <div
        style={{
          backgroundColor: 'var(--color-cream)',
          padding: '16px',
          borderRadius: '12px',
          marginBottom: '24px'
        }}
      >
        <h4 style={{ marginBottom: '8px' }}>Shipping Address</h4>
        <p style={{ color: 'var(--color-ink)', fontSize: '14px', lineHeight: '1.5' }}>
          {o.shippingAddress?.fullName}
          <br />
          {o.shippingAddress?.street}
          {o.shippingAddress?.landmark ? `, ${o.shippingAddress.landmark}` : ''}
          <br />
          {o.shippingAddress?.city}
          {o.shippingAddress?.state ? `, ${o.shippingAddress.state}` : ''}{' '}
          {o.shippingAddress?.zipCode || ''}
          <br />
          {o.shippingAddress?.phone || ''}
        </p>
      </div>
      <h4 style={{ marginBottom: '12px' }}>Order Items ({o.products?.length || 0})</h4>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
        {o.products?.map((item: any, idx: number) => {
          const prodIdStr = item.product?._id || item.product?.toString() || '';
          const prodIdDisplay = prodIdStr ? prodIdStr.substring(prodIdStr.length - 6) : `Item ${idx + 1}`;
          return (
            <div
              key={idx}
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                padding: '12px',
                border: '1px solid rgba(43,38,32,0.05)',
                borderRadius: '8px'
              }}
            >
              <span>Item ID: {prodIdDisplay}</span>
              <span>
                {item.quantity} {item.priceUnit || 'item'} x Rs. {item.price}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
}

export default OrderDetail;
