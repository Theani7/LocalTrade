import React, { ReactNode } from 'react';

export interface MiniStatCardProps {
  title: string;
  value: string | number;
  icon: ReactNode;
  color?: 'coral' | 'success' | 'warning' | 'ink' | 'danger' | string;
}

export function MiniStatCard({ title, value, icon, color = 'ink' }: MiniStatCardProps) {
  const iconColors: Record<string, string> = {
    coral: '#FF6F52',
    success: '#2E7D32',
    warning: '#F9A826',
    ink: '#2B2620',
    danger: '#D32F2F'
  };
  const bgColors: Record<string, string> = {
    coral: '#FF6F5215',
    success: '#2E7D3215',
    warning: '#F9A82615',
    ink: '#2B262015',
    danger: '#D32F2F15'
  };

  return (
    <div className="card" style={{ display: 'flex', alignItems: 'center', gap: '16px', padding: '20px' }}>
      <div
        style={{
          width: '44px',
          height: '44px',
          borderRadius: '12px',
          backgroundColor: bgColors[color] || bgColors.ink,
          color: iconColors[color] || iconColors.ink,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center'
        }}
      >
        {icon}
      </div>
      <div>
        <p style={{ color: 'var(--color-muted)', fontSize: '13px', fontWeight: '500', marginBottom: '2px' }}>
          {title}
        </p>
        <h4 style={{ fontSize: '20px', fontWeight: '600' }}>{value}</h4>
      </div>
    </div>
  );
}

export default MiniStatCard;
