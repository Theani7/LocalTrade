import React from 'react';
import { Category } from '../../types';

export interface CategoryModalProps {
  category: Category;
  onChange: (category: Category) => void;
  onSave: (e: React.FormEvent) => void;
  onCancel: () => void;
}

export function CategoryModal({ category, onChange, onSave, onCancel }: CategoryModalProps) {
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
          width: '480px',
          maxWidth: '90%',
          padding: '32px',
          boxShadow: 'var(--shadow-lg)'
        }}
      >
        <h3 style={{ marginBottom: '24px', fontSize: '20px' }}>
          {category._id ? 'Edit Category' : 'Add Category'}
        </h3>
        <form onSubmit={onSave}>
          <div style={{ marginBottom: '16px' }}>
            <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500' }}>
              Category Name
            </label>
            <input
              type="text"
              value={category.name}
              onChange={e => onChange({ ...category, name: e.target.value })}
              className="input-field"
              required
              style={{ width: '100%' }}
            />
          </div>
          <div style={{ marginBottom: '16px', display: 'flex', gap: '16px' }}>
            <div style={{ flex: 1 }}>
              <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500' }}>
                Icon (Emoji)
              </label>
              <input
                type="text"
                value={category.icon}
                onChange={e => onChange({ ...category, icon: e.target.value })}
                className="input-field"
                required
                style={{ width: '100%', fontSize: '20px' }}
              />
            </div>
            <div style={{ flex: 1 }}>
              <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500' }}>
                Sort Order
              </label>
              <input
                type="number"
                value={category.sortOrder}
                onChange={e => onChange({ ...category, sortOrder: Number(e.target.value) })}
                className="input-field"
                required
                style={{ width: '100%' }}
              />
            </div>
          </div>
          <div style={{ marginBottom: '32px' }}>
            <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer' }}>
              <input
                type="checkbox"
                checked={category.isActive}
                onChange={e => onChange({ ...category, isActive: e.target.checked })}
                style={{ width: '18px', height: '18px', accentColor: 'var(--color-coral)' }}
              />
              <span style={{ fontWeight: '500' }}>Active Category</span>
            </label>
            <p style={{ color: 'var(--color-muted)', fontSize: '13px', marginTop: '4px', marginLeft: '26px' }}>
              Inactive categories will be hidden from the customer app.
            </p>
          </div>
          <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
            <button
              type="button"
              onClick={onCancel}
              className="btn"
              style={{
                backgroundColor: 'white',
                color: 'var(--color-ink)',
                border: '1px solid #e5e4e7'
              }}
            >
              Cancel
            </button>
            <button
              type="submit"
              className="btn"
              style={{ backgroundColor: 'var(--color-coral)' }}
            >
              {category._id ? 'Save Changes' : 'Create Category'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default CategoryModal;
