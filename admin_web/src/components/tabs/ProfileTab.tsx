import React, { useState } from 'react';
import { User, API_URL } from '../../types';
import { AnalyticsSkeleton } from '../common/Skeletons';

export interface ProfileTabProps {
  profile: User | { user: User } | null;
  token: string | null;
}

export function ProfileTab({ profile, token }: ProfileTabProps) {
  const [showPasswordForm, setShowPasswordForm] = useState(false);
  const [pwData, setPwData] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: ''
  });
  const [pwStatus, setPwStatus] = useState({ type: '', msg: '' });

  const handlePasswordChange = async (e: React.FormEvent) => {
    e.preventDefault();
    setPwStatus({ type: 'loading', msg: 'Updating...' });
    try {
      const res = await fetch(`${API_URL}/auth/change-password`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify(pwData)
      });
      const data = await res.json();
      if (data.success || data.status === 'success') {
        setPwStatus({ type: 'success', msg: 'Password successfully updated!' });
        setPwData({ currentPassword: '', newPassword: '', confirmPassword: '' });
        setTimeout(() => {
          setShowPasswordForm(false);
          setPwStatus({ type: '', msg: '' });
        }, 2000);
      } else {
        setPwStatus({ type: 'error', msg: data.message || 'Update failed' });
      }
    } catch (err) {
      console.error(err);
      setPwStatus({ type: 'error', msg: 'Connection error' });
    }
  };

  if (!profile) return <AnalyticsSkeleton />;
  const u: User = (profile as { user: User }).user || (profile as User);

  return (
    <div className="card animate-fade-in" style={{ maxWidth: '600px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '20px', marginBottom: '32px' }}>
        <div
          style={{
            width: '80px',
            height: '80px',
            backgroundColor: 'var(--color-coral)',
            borderRadius: '50%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: 'white',
            fontSize: '32px',
            fontWeight: 'bold'
          }}
        >
          {u.fullName?.[0]?.toUpperCase() || 'A'}
        </div>
        <div>
          <h2 style={{ fontSize: '24px', marginBottom: '4px' }}>{u.fullName}</h2>
          <p style={{ color: 'var(--color-muted)' }}>{u.email}</p>
          <span className="status-badge info" style={{ marginTop: '8px' }}>
            {u.role?.toUpperCase()}
          </span>
        </div>
      </div>
      <div style={{ backgroundColor: 'var(--color-cream)', padding: '24px', borderRadius: '16px' }}>
        <h3 style={{ marginBottom: '16px', fontSize: '18px' }}>Account Settings</h3>
        {!showPasswordForm ? (
          <>
            <p style={{ color: 'var(--color-muted)', marginBottom: '16px', lineHeight: 1.5 }}>
              Update your security credentials below.
            </p>
            <button
              onClick={() => setShowPasswordForm(true)}
              className="btn"
              style={{ backgroundColor: 'var(--color-ink)', color: 'white' }}
            >
              Change Password
            </button>
          </>
        ) : (
          <form onSubmit={handlePasswordChange} className="animate-fade-in">
            <div style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500' }}>
                Current Password
              </label>
              <input
                type="password"
                value={pwData.currentPassword}
                onChange={e => setPwData({ ...pwData, currentPassword: e.target.value })}
                className="input-field"
                required
                style={{ width: '100%', backgroundColor: 'white' }}
              />
            </div>
            <div style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500' }}>
                New Password
              </label>
              <input
                type="password"
                value={pwData.newPassword}
                onChange={e => setPwData({ ...pwData, newPassword: e.target.value })}
                className="input-field"
                required
                style={{ width: '100%', backgroundColor: 'white' }}
              />
            </div>
            <div style={{ marginBottom: '24px' }}>
              <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500' }}>
                Confirm New Password
              </label>
              <input
                type="password"
                value={pwData.confirmPassword}
                onChange={e => setPwData({ ...pwData, confirmPassword: e.target.value })}
                className="input-field"
                required
                style={{ width: '100%', backgroundColor: 'white' }}
              />
            </div>
            {pwStatus.msg && (
              <div
                style={{
                  marginBottom: '16px',
                  padding: '12px',
                  borderRadius: '8px',
                  fontSize: '14px',
                  backgroundColor:
                    pwStatus.type === 'success'
                      ? 'rgba(46,125,50,0.1)'
                      : 'rgba(211,47,47,0.1)',
                  color:
                    pwStatus.type === 'success'
                      ? 'var(--color-success)'
                      : 'var(--color-danger)'
                }}
              >
                {pwStatus.msg}
              </div>
            )}
            <div style={{ display: 'flex', gap: '12px' }}>
              <button
                type="submit"
                className="btn"
                style={{ backgroundColor: 'var(--color-coral)' }}
              >
                Save Password
              </button>
              <button
                type="button"
                onClick={() => {
                  setShowPasswordForm(false);
                  setPwStatus({ type: '', msg: '' });
                }}
                className="btn"
                style={{
                  backgroundColor: 'transparent',
                  color: 'var(--color-ink)',
                  border: '1px solid #e5e4e7'
                }}
              >
                Cancel
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}

export default ProfileTab;
