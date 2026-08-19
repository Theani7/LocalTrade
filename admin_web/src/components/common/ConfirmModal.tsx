import React from 'react';

export interface ConfirmModalProps {
  isOpen: boolean;
  title?: string;
  message?: string;
  confirmText?: string;
  confirmColor?: string;
  onConfirm: () => void;
  onCancel: () => void;
}

export function ConfirmModal({
  isOpen,
  title,
  message,
  onConfirm,
  onCancel,
  confirmText = 'Confirm',
  confirmColor = 'danger'
}: ConfirmModalProps) {
  if (!isOpen) return null;

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        backgroundColor: 'rgba(43,38,32,0.6)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 9999,
        backdropFilter: 'blur(4px)'
      }}
      className="animate-fade-in"
    >
      <div
        className="card"
        style={{
          width: '420px',
          maxWidth: '90%',
          padding: '32px',
          boxShadow: 'var(--shadow-lg)',
          border: '1px solid rgba(255,255,255,0.2)'
        }}
      >
        <h3 style={{ marginBottom: '12px', fontSize: '20px' }}>{title}</h3>
        <p style={{ color: 'var(--color-muted)', marginBottom: '32px', lineHeight: 1.5, fontSize: '15px' }}>
          {message}
        </p>
        <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
          <button
            onClick={onCancel}
            className="btn"
            style={{
              backgroundColor: 'white',
              color: 'var(--color-ink)',
              border: '1px solid #e5e4e7',
              padding: '10px 20px'
            }}
          >
            Cancel
          </button>
          <button
            onClick={onConfirm}
            className="btn"
            style={{
              backgroundColor: `var(--color-${confirmColor})`,
              padding: '10px 20px'
            }}
          >
            {confirmText}
          </button>
        </div>
      </div>
    </div>
  );
}

export default ConfirmModal;
