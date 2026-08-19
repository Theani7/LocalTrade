import React, { CSSProperties } from 'react';

export interface SkeletonProps {
  width?: string | number;
  height?: string | number;
  borderRadius?: string | number;
  style?: CSSProperties;
}

export function Skeleton({ width, height, borderRadius = '8px', style = {} }: SkeletonProps) {
  return (
    <div
      className="skeleton-pulse"
      style={{
        width,
        height,
        borderRadius,
        backgroundColor: 'rgba(43,38,32,0.06)',
        ...style
      }}
    />
  );
}

export interface TableSkeletonProps {
  headers: string[];
}

export function TableSkeleton({ headers }: TableSkeletonProps) {
  return (
    <div className="table-container animate-fade-in">
      <table className="data-table">
        <thead>
          <tr>
            {headers.map((h, i) => (
              <th key={i}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {[1, 2, 3, 4, 5].map(i => (
            <tr key={i}>
              {headers.map((_, j) => (
                <td key={j}>
                  <Skeleton width={j === 0 ? '150px' : '100px'} height="20px" />
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export function AnalyticsSkeleton() {
  return (
    <div className="animate-fade-in">
      <div className="dashboard-grid" style={{ marginBottom: '24px' }}>
        {[1, 2, 3, 4].map(i => (
          <div key={i} className="card" style={{ padding: '24px' }}>
            <Skeleton width="120px" height="16px" style={{ marginBottom: '12px' }} />
            <Skeleton width="80px" height="36px" />
          </div>
        ))}
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '24px', marginBottom: '24px' }}>
        {[1, 2, 3, 4].map(i => (
          <div key={i} className="card" style={{ display: 'flex', gap: '16px', alignItems: 'center', padding: '16px 20px' }}>
            <Skeleton width="48px" height="48px" borderRadius="12px" />
            <div style={{ flex: 1 }}>
              <Skeleton width="60px" height="14px" style={{ marginBottom: '4px' }} />
              <Skeleton width="40px" height="24px" />
            </div>
          </div>
        ))}
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px', marginBottom: '24px' }}>
        <div className="card" style={{ height: '400px' }}>
          <Skeleton width="200px" height="24px" style={{ marginBottom: '24px' }} />
          <Skeleton width="100%" height="280px" />
        </div>
        <div className="card" style={{ height: '400px' }}>
          <Skeleton width="200px" height="24px" style={{ marginBottom: '24px' }} />
          <Skeleton width="100%" height="280px" />
        </div>
      </div>
    </div>
  );
}

export function DetailSkeleton() {
  return (
    <div className="card animate-fade-in" style={{ maxWidth: '800px', display: 'flex', gap: '32px' }}>
      <Skeleton width="200px" height="200px" borderRadius="16px" />
      <div style={{ flex: 1 }}>
        <Skeleton width="100px" height="24px" style={{ marginBottom: '12px' }} borderRadius="100px" />
        <Skeleton width="80%" height="40px" style={{ marginBottom: '16px' }} />
        <Skeleton width="120px" height="30px" style={{ marginBottom: '24px' }} />
        <Skeleton width="100%" height="16px" style={{ marginBottom: '8px' }} />
        <Skeleton width="90%" height="16px" style={{ marginBottom: '8px' }} />
        <Skeleton width="60%" height="16px" style={{ marginBottom: '24px' }} />
      </div>
    </div>
  );
}

const Skeletons = {
  Skeleton,
  TableSkeleton,
  AnalyticsSkeleton,
  DetailSkeleton
};

export default Skeletons;
