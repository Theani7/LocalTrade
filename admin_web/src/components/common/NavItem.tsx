import React, { ReactNode } from 'react';

export interface NavItemProps {
  icon: ReactNode;
  label: string;
  active?: boolean;
  onClick: () => void;
}

export function NavItem({ icon, label, active = false, onClick }: NavItemProps) {
  return (
    <button
      onClick={onClick}
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: '12px',
        padding: '12px 16px',
        borderRadius: '10px',
        width: '100%',
        border: 'none',
        cursor: 'pointer',
        color: active ? 'white' : 'var(--color-ink)',
        backgroundColor: active ? 'var(--color-ink)' : 'transparent',
        fontWeight: '500',
        fontSize: '15px',
        fontFamily: 'inherit',
        transition: 'all 0.2s',
        textAlign: 'left'
      }}
    >
      <span style={{ color: active ? 'var(--color-coral)' : 'var(--color-muted)' }}>
        {icon}
      </span>
      {label}
    </button>
  );
}

export default NavItem;
