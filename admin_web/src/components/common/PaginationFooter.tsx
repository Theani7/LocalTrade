import React from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';

export interface PaginationFooterProps {
  page: number;
  setPage: (p: number) => void;
}

export function PaginationFooter({ page, setPage }: PaginationFooterProps) {
  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'flex-end',
        gap: '16px',
        padding: '16px 24px',
        borderTop: '1px solid rgba(43,38,32,0.05)'
      }}
    >
      <button
        onClick={() => setPage(Math.max(1, page - 1))}
        disabled={page === 1}
        className="btn"
        style={{
          padding: '8px 16px',
          backgroundColor: page === 1 ? 'rgba(43,38,32,0.05)' : 'var(--color-ink)',
          color: page === 1 ? 'var(--color-muted)' : 'white'
        }}
      >
        <ChevronLeft size={16} /> Prev
      </button>
      <span style={{ fontWeight: '500' }}>Page {page}</span>
      <button
        onClick={() => setPage(page + 1)}
        className="btn"
        style={{
          padding: '8px 16px',
          backgroundColor: 'var(--color-ink)',
          color: 'white'
        }}
      >
        Next <ChevronRight size={16} />
      </button>
    </div>
  );
}

export default PaginationFooter;
