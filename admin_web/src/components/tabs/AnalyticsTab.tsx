import React from 'react';
import {
  TrendingUp,
  ListOrdered,
  Users,
  Store,
  CheckCircle,
  Clock,
  Package,
  XCircle,
  Download
} from 'lucide-react';
import {
  AreaChart,
  Area,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  Legend,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer
} from 'recharts';
import { AnalyticsData, API_URL } from '../../types';
import { StatCard } from '../common/StatCard';
import { MiniStatCard } from '../common/MiniStatCard';
import { AnalyticsSkeleton } from '../common/Skeletons';

export interface AnalyticsTabProps {
  analytics: AnalyticsData | null;
}

export function AnalyticsTab({ analytics }: AnalyticsTabProps) {
  if (!analytics) return <AnalyticsSkeleton />;

  const handleExportCSV = async () => {
    try {
      const res = await fetch(`${API_URL}/admin/analytics/export`, {
        headers: { Authorization: `Bearer ${localStorage.getItem('adminToken')}` }
      });
      if (!res.ok) throw new Error('Export failed');
      const blob = await res.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `localtrade-analytics-${new Date().toISOString().split('T')[0]}.csv`;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url);
    } catch (err) {
      console.error(err);
      alert('Failed to export CSV. Please try again.');
    }
  };

  const stats = analytics.stats || {};
  const chartData =
    analytics.dailyStats?.map(day => ({
      name: new Date(day._id).toLocaleDateString('en-US', { weekday: 'short' }),
      revenue: day.revenue,
      orders: day.count
    })) || [];
  const userChartData =
    analytics.userDailyStats?.map(day => ({
      name: new Date(day._id).toLocaleDateString('en-US', { weekday: 'short' }),
      users: day.count
    })) || [];
  const categoryData =
    analytics.revenueByCategory?.map(c => ({
      name: c._id,
      revenue: c.revenue
    })) || [];
  const recentOrders = analytics.recentOrders || [];

  const COLORS = ['#FF6F52', '#F9A826', '#34C759', '#007AFF', '#5856D6', '#FF2D55', '#2B2620', '#6E6557'];

  return (
    <>
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: '24px' }}>
        <button
          onClick={handleExportCSV}
          className="btn"
          style={{ backgroundColor: 'white', border: '1px solid #e5e4e7', color: 'var(--color-ink)' }}
        >
          <Download size={16} /> Export CSV
        </button>
      </div>

      <div className="dashboard-grid" style={{ marginBottom: '24px' }}>
        <StatCard
          title="Total Revenue"
          value={`Rs. ${(stats.totalRevenue || 0).toLocaleString()}`}
          icon={<TrendingUp />}
          color="coral"
        />
        <StatCard
          title="Total Orders"
          value={(stats.totalOrders || 0).toLocaleString()}
          icon={<ListOrdered />}
          color="success"
        />
        <StatCard
          title="Total Customers"
          value={(stats.totalCustomers || 0).toLocaleString()}
          icon={<Users />}
          color="ink"
        />
        <StatCard
          title="Total Vendors"
          value={(stats.totalVendors || 0).toLocaleString()}
          icon={<Store />}
          color="warning"
        />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '24px', marginBottom: '32px' }}>
        <MiniStatCard
          title="Delivered Orders"
          value={stats.completedOrders || 0}
          icon={<CheckCircle />}
          color="success"
        />
        <MiniStatCard
          title="Pending Vendors"
          value={stats.pendingVendors || 0}
          icon={<Clock />}
          color="warning"
        />
        <MiniStatCard
          title="Total Products"
          value={stats.totalProducts || 0}
          icon={<Package />}
          color="ink"
        />
        <MiniStatCard
          title="Suspended Vendors"
          value={stats.suspendedVendors || 0}
          icon={<XCircle />}
          color="danger"
        />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px', marginBottom: '24px' }}>
        <div className="card animate-fade-in delay-200" style={{ height: '420px', display: 'flex', flexDirection: 'column' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
            <h3 style={{ fontSize: '18px', fontWeight: 'bold' }}>Revenue & Orders (Last 7 Days)</h3>
          </div>
          <div style={{ flex: 1, minHeight: 0 }}>
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorRev" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="var(--color-coral)" stopOpacity={0.4} />
                    <stop offset="95%" stopColor="var(--color-coral)" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="rgba(43,38,32,0.06)" />
                <XAxis
                  dataKey="name"
                  axisLine={false}
                  tickLine={false}
                  tick={{ fill: 'var(--color-muted)', fontSize: 13 }}
                  dy={10}
                />
                <YAxis
                  axisLine={false}
                  tickLine={false}
                  tick={{ fill: 'var(--color-muted)', fontSize: 13 }}
                  dx={-10}
                  tickFormatter={val => `Rs.${val}`}
                />
                <Tooltip
                  contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: 'var(--shadow-lg)' }}
                  itemStyle={{ color: 'var(--color-coral)', fontWeight: 600 }}
                />
                <Area
                  type="monotone"
                  dataKey="revenue"
                  stroke="var(--color-coral)"
                  strokeWidth={3}
                  fillOpacity={1}
                  fill="url(#colorRev)"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="card animate-fade-in delay-300" style={{ height: '420px', display: 'flex', flexDirection: 'column' }}>
          <h3 style={{ marginBottom: '8px', fontSize: '18px', fontWeight: 'bold' }}>Revenue by Category</h3>
          <div style={{ flex: 1, minHeight: 0, position: 'relative' }}>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={categoryData}
                  cx="50%"
                  cy="50%"
                  innerRadius={70}
                  outerRadius={110}
                  paddingAngle={4}
                  dataKey="revenue"
                  stroke="none"
                >
                  {categoryData.map((_entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: 'var(--shadow-lg)' }} />
                <Legend iconType="circle" wrapperStyle={{ fontSize: '13px', paddingTop: '20px' }} />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px', marginBottom: '24px' }}>
        <div className="card animate-fade-in delay-300" style={{ height: '420px', display: 'flex', flexDirection: 'column' }}>
          <h3 style={{ marginBottom: '16px', fontSize: '18px', fontWeight: 'bold' }}>Recent Orders</h3>
          <div className="table-container" style={{ margin: 0, padding: 0, border: 'none', boxShadow: 'none', flex: 1, overflowY: 'auto' }}>
            <table className="data-table" style={{ margin: 0 }}>
              <thead style={{ position: 'sticky', top: 0, background: 'rgba(251, 245, 234, 0.9)', backdropFilter: 'blur(8px)' }}>
                <tr>
                  <th>Order ID</th>
                  <th>Customer</th>
                  <th>Total</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {recentOrders.map(o => (
                  <tr key={o._id}>
                    <td style={{ fontWeight: 600, color: 'var(--color-ink)' }}>
                      #{o._id ? o._id.substring(o._id.length - 6).toUpperCase() : ''}
                    </td>
                    <td style={{ color: 'var(--color-muted)' }}>
                      {typeof o.customerId === 'object' && o.customerId?.fullName
                        ? o.customerId.fullName
                        : 'Unknown'}
                    </td>
                    <td style={{ fontWeight: 500 }}>Rs. {o.totalAmount.toLocaleString()}</td>
                    <td>
                      <span
                        className={`status-badge ${
                          o.orderStatus === 'Delivered'
                            ? 'success'
                            : o.orderStatus === 'Cancelled'
                            ? 'danger'
                            : 'warning'
                        }`}
                      >
                        {o.orderStatus}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        <div className="card animate-fade-in delay-300" style={{ height: '420px', display: 'flex', flexDirection: 'column' }}>
          <h3 style={{ marginBottom: '24px', fontSize: '18px', fontWeight: 'bold' }}>New Users Trend</h3>
          <div style={{ flex: 1, minHeight: 0 }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={userChartData} barSize={28} margin={{ top: 10, right: 10, left: -30, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="rgba(43,38,32,0.06)" />
                <XAxis
                  dataKey="name"
                  axisLine={false}
                  tickLine={false}
                  tick={{ fill: 'var(--color-muted)', fontSize: 13 }}
                  dy={10}
                />
                <YAxis
                  axisLine={false}
                  tickLine={false}
                  tick={{ fill: 'var(--color-muted)', fontSize: 13 }}
                  dx={-10}
                />
                <Tooltip
                  cursor={{ fill: 'rgba(43,38,32,0.03)' }}
                  contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: 'var(--shadow-lg)' }}
                  itemStyle={{ color: 'var(--color-ink)', fontWeight: 600 }}
                />
                <Bar dataKey="users" fill="var(--color-ink)" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </>
  );
}

export default AnalyticsTab;
