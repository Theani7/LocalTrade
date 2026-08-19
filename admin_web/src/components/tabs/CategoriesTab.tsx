import React from 'react';
import { Plus, Edit } from 'lucide-react';
import { Category } from '../../types';
import { TableSkeleton } from '../common/Skeletons';

export interface CategoriesTabProps {
  categories: Category[];
  onAdd: () => void;
  onEdit: (c: Category) => void;
}

export function CategoriesTab({ categories, onAdd, onEdit }: CategoriesTabProps) {
  if (!categories.length) {
    return <TableSkeleton headers={['Icon', 'Category Name', 'Status', 'Actions']} />;
  }

  return (
    <div className="animate-fade-in">
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: '16px' }}>
        <button
          onClick={onAdd}
          className="btn"
          style={{ backgroundColor: 'var(--color-ink)', color: 'white' }}
        >
          <Plus size={16} /> Add Category
        </button>
      </div>
      <div
        className="card table-container"
        style={{ margin: 0, padding: 0, border: 'none', boxShadow: 'none' }}
      >
        <table className="data-table" style={{ margin: 0 }}>
          <thead>
            <tr>
              <th style={{ width: '80px' }}>Icon</th>
              <th>Category Name</th>
              <th>Status</th>
              <th style={{ textAlign: 'right' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {categories.map(c => (
              <tr key={c._id}>
                <td style={{ fontSize: '24px', textAlign: 'center' }}>{c.icon}</td>
                <td style={{ fontWeight: 500 }}>{c.name}</td>
                <td>
                  <span className={`status-badge ${c.isActive ? 'success' : 'danger'}`}>
                    {c.isActive ? 'Active' : 'Hidden'}
                  </span>
                </td>
                <td style={{ textAlign: 'right' }}>
                  <button
                    onClick={() => onEdit(c)}
                    className="btn"
                    style={{
                      padding: '6px 12px',
                      fontSize: '13px',
                      backgroundColor: 'var(--color-cream)',
                      color: 'var(--color-ink)'
                    }}
                  >
                    <Edit size={14} /> Edit
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default CategoriesTab;
