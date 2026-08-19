import React, { ReactNode, ReactElement } from 'react';

export interface StatCardProps {
  title: string;
  value: string | number;
  icon: ReactNode;
  color?: 'coral' | 'success' | 'warning' | 'ink' | 'danger' | string;
}

export function StatCard({ title, value, icon, color = 'coral' }: StatCardProps) {
  const bgColors: Record<string, string> = {
    coral: 'linear-gradient(135deg, rgba(255,111,82,0.1) 0%, rgba(255,111,82,0.02) 100%)',
    success: 'linear-gradient(135deg, rgba(46,125,50,0.1) 0%, rgba(46,125,50,0.02) 100%)',
    warning: 'linear-gradient(135deg, rgba(249,168,38,0.1) 0%, rgba(249,168,38,0.02) 100%)',
    ink: 'linear-gradient(135deg, rgba(43,38,32,0.1) 0%, rgba(43,38,32,0.02) 100%)',
    danger: 'linear-gradient(135deg, rgba(211,47,47,0.1) 0%, rgba(211,47,47,0.02) 100%)',
  };
  const borderColors: Record<string, string> = {
    coral: '#FF6F5230',
    success: '#2E7D3230',
    warning: '#F9A82630',
    ink: '#2B262030',
    danger: '#D32F2F30'
  };
  const iconColors: Record<string, string> = {
    coral: '#FF6F52',
    success: '#2E7D32',
    warning: '#F9A826',
    ink: '#2B2620',
    danger: '#D32F2F'
  };

  return (
    <div
      className="card hover-expand"
      style={{
        background: bgColors[color] || bgColors.coral,
        border: `1px solid ${borderColors[color] || borderColors.coral}`,
        display: 'flex',
        flexDirection: 'column',
        gap: '20px',
        position: 'relative',
        overflow: 'hidden',
        padding: '28px'
      }}
    >
      <div
        style={{
          position: 'absolute',
          right: '-15%',
          top: '-15%',
          opacity: 0.04,
          transform: 'scale(3.5)'
        }}
      >
        {icon}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: '16px', position: 'relative', zIndex: 1 }}>
        <div
          style={{
            width: '48px',
            height: '48px',
            borderRadius: '14px',
            backgroundColor: 'white',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: iconColors[color] || iconColors.coral,
            boxShadow: '0 8px 16px rgba(0,0,0,0.06)'
          }}
        >
          {React.isValidElement(icon) ? React.cloneElement(icon as ReactElement<{ size?: number }>, { size: 24 }) : icon}
        </div>
        <span
          style={{
            fontSize: '15px',
            color: 'var(--color-muted)',
            fontWeight: 600,
            textTransform: 'uppercase',
            letterSpacing: '0.5px'
          }}
        >
          {title}
        </span>
      </div>
      <div style={{ position: 'relative', zIndex: 1 }}>
        <h3
          style={{
            fontSize: '38px',
            margin: 0,
            fontWeight: '800',
            color: 'var(--color-ink)',
            letterSpacing: '-1px'
          }}
        >
          {value}
        </h3>
      </div>
    </div>
  );
}

export default StatCard;
