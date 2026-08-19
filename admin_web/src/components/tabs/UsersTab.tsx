import React from 'react';
import { Users, CheckCircle, Power } from 'lucide-react';
import { User } from '../../types';
import { MiniStatCard } from '../common/MiniStatCard';
import { TableSkeleton } from '../common/Skeletons';
import { PaginationFooter } from '../common/PaginationFooter';

export interface UsersTabProps {
  users: User[];
  filters?: {
    page: number;
    limit?: number;
    role?: string;
  };
  setPage?: (page: number) => void;
  onToggle: (id: string, active: boolean) => void;
}

export function UsersTab({ users, filters, setPage, onToggle }: UsersTabProps) {
  if (!users.length && filters?.page === 1) {
    return <TableSkeleton headers={['User', 'Email', 'Role', 'Status', 'Actions']} />;
  }

  const total = users.length;
  const active = users.filter(u => u.isActive).length;

  return (
    <div className="animate-fade-in">
      <div style={{ display: 'flex', gap: '24px', marginBottom: '24px' }}>
        <MiniStatCard title="Total Users" value={total} icon={<Users />} color="ink" />
        <MiniStatCard title="Active Users" value={active} icon={<CheckCircle />} color="success" />
      </div>

      <div className="card">
        <div className="table-container" style={{ margin: 0, padding: 0, border: 'none', boxShadow: 'none' }}>
          <table className="data-table" style={{ margin: 0 }}>
            <thead>
              <tr>
                <th>User</th>
                <th>Email</th>
                <th>Role</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {users.map(u => (
                <tr key={u._id}>
                  <td style={{ fontWeight: 500 }}>{u.fullName}</td>
                  <td style={{ color: 'var(--color-muted)' }}>{u.email}</td>
                  <td>
                    <span className="status-badge info">{u.role}</span>
                  </td>
                  <td>
                    <span className={`status-badge ${u.isActive ? 'success' : 'danger'}`}>
                      {u.isActive ? 'Active' : 'Disabled'}
                    </span>
                  </td>
                  <td>
                    <button
                      onClick={() => onToggle(u._id, !u.isActive)}
                      className="btn"
                      style={{
                        padding: '6px 12px',
                        fontSize: '13px',
                        backgroundColor: u.isActive
                          ? 'rgba(211,47,47,0.1)'
                          : 'rgba(46,125,50,0.1)',
                        color: u.isActive ? 'var(--color-danger)' : 'var(--color-success)'
                      }}
                    >
                      <Power size={14} /> {u.isActive ? 'Disable' : 'Enable'}
                    </button>
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

export default UsersTab;
