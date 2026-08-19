import React, { useState, useEffect } from 'react';
import { Star } from 'lucide-react';
import { FeedbackItem } from '../../types';
import { TableSkeleton } from '../common/Skeletons';

export interface FeedbackTabProps {
  feedback: FeedbackItem[];
}

export function FeedbackTab({ feedback }: FeedbackTabProps) {
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const t = setTimeout(() => setLoading(false), 800);
    return () => clearTimeout(t);
  }, []);

  if (loading && !feedback.length) {
    return <TableSkeleton headers={['User', 'Rating', 'Comment', 'Date']} />;
  }

  return (
    <div className="animate-fade-in">
      <div
        className="card table-container"
        style={{ margin: 0, padding: 0, border: 'none', boxShadow: 'none' }}
      >
        <table className="data-table" style={{ margin: 0 }}>
          <thead>
            <tr>
              <th>User</th>
              <th>Rating</th>
              <th>Comment</th>
              <th>Date</th>
            </tr>
          </thead>
          <tbody>
            {feedback.length > 0 ? (
              feedback.map(f => (
                <tr key={f._id}>
                  <td style={{ fontWeight: 500 }}>
                    {typeof f.userId === 'object' && f.userId ? f.userId.fullName : 'Anonymous'}
                  </td>
                  <td>
                    <Star
                      size={14}
                      color="var(--color-warning)"
                      fill="var(--color-warning)"
                      style={{ verticalAlign: 'middle', marginRight: 4 }}
                    />
                    {f.rating}/5
                  </td>
                  <td
                    style={{
                      maxWidth: '300px',
                      whiteSpace: 'normal',
                      color: 'var(--color-muted)'
                    }}
                  >
                    {f.comment}
                  </td>
                  <td style={{ color: 'var(--color-muted)' }}>
                    {f.createdAt ? new Date(f.createdAt).toLocaleDateString() : ''}
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td
                  colSpan={4}
                  style={{
                    textAlign: 'center',
                    padding: '40px',
                    color: 'var(--color-muted)'
                  }}
                >
                  No feedback received yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default FeedbackTab;
