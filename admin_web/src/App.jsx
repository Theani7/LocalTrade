import React, { useState, useEffect } from 'react';
import { LayoutDashboard, Users, ShoppingBag, Store, Search, Bell, LogOut, TrendingUp, TrendingDown, Trash2, CheckCircle, XCircle, Power, ChevronLeft, Package, Clock, ListOrdered, Tags, Star, MapPin, Download, Edit, Plus, MessageSquare, UserCircle, Filter, ChevronRight } from 'lucide-react';
import { AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell, Legend, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import './index.css';

const API_URL = 'https://localtrade-backend-jg9l.onrender.com/api/v1';

function App() {
  const [token, setToken] = useState(localStorage.getItem('adminToken'));
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  
  const [activeTab, setActiveTab] = useState('overview');
  const [detailView, setDetailView] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [confirmDialog, setConfirmDialog] = useState({ isOpen: false });
  const [showNotifications, setShowNotifications] = useState(false);
  const [categoryModal, setCategoryModal] = useState({ isOpen: false, data: null });

  const [filters, setFilters] = useState({
    users: { page: 1, limit: 10, role: '' },
    vendors: { page: 1, limit: 10, status: '' },
    products: { page: 1, limit: 10 },
    orders: { page: 1, limit: 10 }
  });

  const [data, setData] = useState({
    analytics: null,
    users: [],
    vendors: [],
    products: [],
    orders: [],
    categories: [],
    feedback: [],
    profile: null,
    notifications: []
  });

  useEffect(() => {
    if (token && !detailView) {
      if (activeTab === 'overview' && !data.analytics) fetchAnalytics();
      else if (activeTab === 'users') fetchList('users');
      else if (activeTab === 'vendors') fetchList('vendors');
      else if (activeTab === 'products') fetchList('products');
      else if (activeTab === 'orders') fetchList('orders');
      else if (activeTab === 'categories' && data.categories.length === 0) fetchList('categories', 'categories/admin');
      else if (activeTab === 'feedback' && data.feedback.length === 0) fetchList('feedback', 'feedback');
      else if (activeTab === 'profile' && !data.profile) fetchList('profile', 'auth/me');
    }
  }, [token, activeTab, detailView, filters]);

  useEffect(() => {
    const handler = setTimeout(() => {
      if (token && !detailView && ['users', 'vendors', 'products', 'orders'].includes(activeTab)) {
        setFilters(prev => ({ ...prev, [activeTab]: { ...prev[activeTab], page: 1 } })); // Reset page on search
        fetchList(activeTab);
      }
    }, 400);
    return () => clearTimeout(handler);
  }, [searchQuery]);

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const res = await fetch(`${API_URL}/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password }) });
      const resData = await res.json();
      if (resData.status === 'success' && resData.data.user.role === 'admin') {
        localStorage.setItem('adminToken', resData.token);
        setToken(resData.token);
      } else setError(resData.message || 'Access denied. Admin only.');
    } catch (err) { setError('Connection error.'); } finally { setLoading(false); }
  };

  const handleLogout = () => {
    localStorage.removeItem('adminToken');
    setToken(null);
    setData({ analytics: null, users: [], vendors: [], products: [], orders: [], categories: [] });
    setDetailView(null);
  };

  const fetchAnalytics = async () => {
    try {
      const res = await fetch(`${API_URL}/admin/analytics`, { headers: { Authorization: `Bearer ${token}` } });
      const resData = await res.json();
      if (resData.status === 'success') setData(prev => ({ ...prev, analytics: resData.data }));
      else if (res.status === 401) handleLogout();
    } catch (err) { console.error(err); }
  };

  const fetchList = async (stateKey, endpointOverride) => {
    try {
      let ep = endpointOverride || `admin/${stateKey}`;
      const queryParams = new URLSearchParams();
      
      if (['users', 'vendors', 'products', 'orders'].includes(stateKey)) {
        if (searchQuery) queryParams.append('search', searchQuery);
        if (filters[stateKey]?.page) queryParams.append('page', filters[stateKey].page);
        if (filters[stateKey]?.limit) queryParams.append('limit', filters[stateKey].limit);
        if (filters[stateKey]?.role) queryParams.append('role', filters[stateKey].role);
        if (filters[stateKey]?.status) queryParams.append('status', filters[stateKey].status);
      }

      const qs = queryParams.toString();
      if (qs) ep += (ep.includes('?') ? '&' : '?') + qs;

      const res = await fetch(`${API_URL}/${ep}`, { headers: { Authorization: `Bearer ${token}` } });
      const resData = await res.json();
      if (resData.status === 'success' || resData.success === true) {
        const arr = resData.data[stateKey] || resData.data.data || resData.data || resData.data.user || [];
        setData(prev => ({ ...prev, [stateKey]: arr }));
      }
    } catch (err) { console.error(err); }
  };

  const fetchNotifications = async () => {
    try {
      const res = await fetch(`${API_URL}/notifications`, { headers: { Authorization: `Bearer ${token}` } });
      const resData = await res.json();
      if (resData.success) setData(prev => ({ ...prev, notifications: resData.data.notifications || [] }));
    } catch (err) { console.error(err); }
  };

  const loadDetail = async (type, id) => {
    if (type === 'order') {
      const orderData = data.orders.find(o => o._id === id) || (data.analytics?.recentOrders || []).find(o => o._id === id);
      setDetailView({ type, id, data: orderData, loading: false });
      return;
    }
    
    setDetailView({ type, id, data: null, loading: true });
    try {
      const res = await fetch(`${API_URL}/admin/${type}s/${id}`, { headers: { Authorization: `Bearer ${token}` } });
      const resData = await res.json();
      if (resData.status === 'success') setDetailView({ type, id, data: resData.data, loading: false });
    } catch (err) { console.error(err); }
  };

  const toggleUserStatus = async (id) => {
    await fetch(`${API_URL}/admin/users/${id}/toggle-status`, { method: 'PATCH', headers: { Authorization: `Bearer ${token}` } });
    fetchList('users');
  };

  const changeVendorStatus = async (id, status) => {
    await fetch(`${API_URL}/admin/vendors/${id}/status`, { method: 'PATCH', headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify({ status }) });
    fetchList('vendors');
    if (detailView?.type === 'vendor' && detailView.id === id) loadDetail('vendor', id);
  };

  const deleteProduct = async (id) => {
    await fetch(`${API_URL}/admin/products/${id}`, { method: 'DELETE', headers: { Authorization: `Bearer ${token}` } });
    fetchList('products');
    if (detailView?.type === 'product' && detailView.id === id) setDetailView(null);
  };

  const confirmLogout = () => setConfirmDialog({ isOpen: true, title: 'Log Out', message: 'Are you sure you want to securely log out of the admin console?', action: handleLogout, confirmText: 'Log Out', confirmColor: 'danger' });
  const confirmUserToggle = (user) => setConfirmDialog({ isOpen: true, title: user.isActive ? 'Suspend User' : 'Activate User', message: `Are you sure you want to ${user.isActive ? 'suspend' : 'activate'} ${user.fullName}?`, action: () => toggleUserStatus(user._id), confirmText: user.isActive ? 'Suspend' : 'Activate', confirmColor: user.isActive ? 'danger' : 'success' });
  const confirmVendorStatus = (vendorId, status) => setConfirmDialog({ isOpen: true, title: status === 'approved' ? 'Approve Vendor' : 'Suspend Vendor', message: `Are you sure you want to ${status === 'approved' ? 'approve' : 'suspend'} this vendor?`, action: () => changeVendorStatus(vendorId, status), confirmText: status === 'approved' ? 'Approve' : 'Suspend', confirmColor: status === 'approved' ? 'success' : 'danger' });
  const confirmProductDelete = (productId) => setConfirmDialog({ isOpen: true, title: 'Delete Product', message: 'Are you sure you want to permanently delete this product? This action cannot be undone.', action: () => deleteProduct(productId), confirmText: 'Delete', confirmColor: 'danger' });

  const handleSaveCategory = async (e) => {
    e.preventDefault();
    const isEdit = !!categoryModal.data?._id;
    const url = `${API_URL}/categories${isEdit ? `/${categoryModal.data._id}` : ''}`;
    const method = isEdit ? 'PATCH' : 'POST';
    
    try {
      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify(categoryModal.data)
      });
      const resData = await res.json();
      if (resData.success) {
        setCategoryModal({ isOpen: false, data: null });
        fetchList('categories', 'categories/admin');
      } else {
        alert(resData.message || 'Error saving category');
      }
    } catch (err) { console.error(err); }
  };

  if (!token) {
    return (
      <div className="dashboard-layout" style={{ alignItems: 'center', justifyContent: 'center' }}>
        <div className="card animate-fade-in" style={{ maxWidth: '420px', width: '100%', padding: '40px' }}>
          <div style={{ textAlign: 'center', marginBottom: '32px' }}>
            <div style={{ width: '64px', height: '64px', borderRadius: '16px', overflow: 'hidden', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: '16px', backgroundColor: 'var(--color-coral)', boxShadow: 'var(--shadow-sm)' }}>
              <img src="/logo.png" alt="LocalTrade Logo" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
            </div>
            <h1 style={{ fontSize: '24px', fontWeight: 'bold' }}>LocalTrade Admin</h1>
            <p style={{ color: 'var(--color-muted)', marginTop: '8px' }}>Log in to manage your platform</p>
          </div>
          <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            {error && <div style={{ padding: '12px', backgroundColor: 'rgba(211, 47, 47, 0.1)', color: 'var(--color-danger)', borderRadius: '8px', fontSize: '14px' }}>{error}</div>}
            <div><label style={{ display: 'block', marginBottom: '8px', fontSize: '14px', fontWeight: '500' }}>Email Address</label><input type="email" className="input-field" placeholder="admin@localtrade.com" value={email} onChange={(e) => setEmail(e.target.value)} required /></div>
            <div><label style={{ display: 'block', marginBottom: '8px', fontSize: '14px', fontWeight: '500' }}>Password</label><input type="password" className="input-field" placeholder="••••••••" value={password} onChange={(e) => setPassword(e.target.value)} required /></div>
            <button type="submit" className="btn" style={{ width: '100%', marginTop: '8px' }} disabled={loading}>{loading ? 'Authenticating...' : 'Sign In'}</button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div className="dashboard-layout">
      {/* Sidebar */}
      <aside className="sidebar" style={{ width: '260px', padding: '32px 24px', display: 'flex', flexDirection: 'column' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '40px', padding: '0 8px' }}>
          <div style={{ width: '40px', height: '40px', borderRadius: '10px', overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: 'var(--color-coral)' }}>
            <img src="/logo.png" alt="Logo" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
          </div>
          <h2 style={{ margin: 0, fontSize: '20px', fontWeight: 'bold', letterSpacing: '-0.5px', color: 'var(--color-ink)' }}>LocalTrade</h2>
        </div>

        <nav style={{ display: 'flex', flexDirection: 'column', gap: '8px', flex: 1 }}>
          <NavItem icon={<LayoutDashboard size={20} />} label="Analytics" active={!detailView && activeTab === 'overview'} onClick={() => { setDetailView(null); setActiveTab('overview'); }} />
          <NavItem icon={<Users size={20} />} label="Users" active={!detailView && activeTab === 'users'} onClick={() => { setDetailView(null); setActiveTab('users'); }} />
          <NavItem icon={<Store size={20} />} label="Vendors" active={(!detailView && activeTab === 'vendors') || detailView?.type === 'vendor'} onClick={() => { setDetailView(null); setActiveTab('vendors'); }} />
          <NavItem icon={<ShoppingBag size={20} />} label="Products" active={(!detailView && activeTab === 'products') || detailView?.type === 'product'} onClick={() => { setDetailView(null); setActiveTab('products'); }} />
          <NavItem icon={<ListOrdered size={20} />} label="Orders" active={!detailView && activeTab === 'orders'} onClick={() => { setDetailView(null); setActiveTab('orders'); }} />
          <NavItem icon={<Tags size={20} />} label="Categories" active={!detailView && activeTab === 'categories'} onClick={() => { setDetailView(null); setActiveTab('categories'); }} />
          <NavItem icon={<MessageSquare size={20} />} label="Feedback" active={!detailView && activeTab === 'feedback'} onClick={() => { setDetailView(null); setActiveTab('feedback'); }} />
        </nav>
        
        <div style={{ marginTop: 'auto', display: 'flex', flexDirection: 'column', gap: '8px' }}>
          <NavItem icon={<UserCircle size={20} />} label="Profile" active={!detailView && activeTab === 'profile'} onClick={() => { setDetailView(null); setActiveTab('profile'); }} />
          <button onClick={confirmLogout} style={{ display: 'flex', alignItems: 'center', gap: '12px', padding: '12px', background: 'none', border: 'none', color: 'var(--color-muted)', cursor: 'pointer', fontWeight: '500', borderRadius: '8px', transition: 'all 0.2s' }}>
            <LogOut size={20} /><span>Log Out</span>
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="dashboard-content">
        {detailView ? (
          <div className="animate-fade-in">
            <button onClick={() => setDetailView(null)} style={{ display: 'inline-flex', alignItems: 'center', gap: '8px', background: 'none', border: 'none', color: 'var(--color-muted)', cursor: 'pointer', fontWeight: '500', marginBottom: '24px' }}>
              <ChevronLeft size={20} /> Back to List
            </button>
            {detailView.loading ? <DetailSkeleton /> : (
              detailView.type === 'vendor' ? <VendorDetail data={detailView.data} onStatusChange={confirmVendorStatus} /> : 
              detailView.type === 'product' ? <ProductDetail data={detailView.data} onDelete={confirmProductDelete} /> :
              detailView.type === 'order' ? <OrderDetail data={detailView.data} /> : null
            )}
          </div>
        ) : (
          <>
            <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px', position: 'relative', zIndex: 9999 }}>
              <div>
                <h1 style={{ fontSize: '32px', marginBottom: '8px' }}>{activeTab === 'overview' ? 'Overview' : activeTab.charAt(0).toUpperCase() + activeTab.slice(1)}</h1>
                <p style={{ color: 'var(--color-muted)' }}>Manage your platform's {activeTab === 'overview' ? 'overview' : activeTab} below.</p>
              </div>
              <div style={{ display: 'flex', gap: '16px', alignItems: 'center' }}>
                {activeTab !== 'overview' && activeTab !== 'categories' && (
                  <div style={{ position: 'relative' }}>
                    <Search size={18} color="var(--color-muted)" style={{ position: 'absolute', left: '12px', top: '12px' }} />
                    <input type="text" placeholder={`Search ${activeTab}...`} value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} className="input-field" style={{ paddingLeft: '40px', width: '250px', backgroundColor: 'white' }} />
                  </div>
                )}
                <div style={{ position: 'relative' }}>
                  <button onClick={() => { setShowNotifications(!showNotifications); if(!showNotifications) fetchNotifications(); }} style={{ width: '44px', height: '44px', borderRadius: '12px', border: '1px solid #e5e4e7', background: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', position: 'relative' }}>
                    <Bell size={20} color="var(--color-ink)" />
                    {data.notifications?.some(n => !n.isRead) && <span style={{ position: 'absolute', top: 10, right: 12, width: 8, height: 8, backgroundColor: 'var(--color-coral)', borderRadius: '50%' }}></span>}
                  </button>
                  {showNotifications && (
                    <div className="card animate-fade-in" style={{ position: 'absolute', top: '56px', right: 0, width: '320px', padding: '16px', zIndex: 9999, boxShadow: 'var(--shadow-lg)' }}>
                      <h4 style={{ marginBottom: '12px' }}>Notifications</h4>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', maxHeight: '300px', overflowY: 'auto' }}>
                        {data.notifications.length === 0 ? <p style={{ color: 'var(--color-muted)', fontSize: '14px' }}>No notifications</p> : 
                          data.notifications.map(n => (
                            <div key={n._id} style={{ padding: '12px', backgroundColor: n.isRead ? 'transparent' : 'rgba(255,111,82,0.05)', borderRadius: '8px', border: '1px solid rgba(43,38,32,0.05)' }}>
                              <h5 style={{ fontSize: '13px', marginBottom: '4px' }}>{n.title}</h5>
                              <p style={{ fontSize: '12px', color: 'var(--color-muted)' }}>{n.message}</p>
                            </div>
                          ))
                        }
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </header>

            {activeTab === 'overview' && <AnalyticsTab analytics={data.analytics} />}
            {activeTab === 'users' && <UsersTab users={data.users} filters={filters.users} setPage={(p) => setFilters(prev => ({...prev, users: {...prev.users, page: p}}))} onToggle={confirmUserToggle} />}
            {activeTab === 'vendors' && <VendorsTab vendors={data.vendors} filters={filters.vendors} setPage={(p) => setFilters(prev => ({...prev, vendors: {...prev.vendors, page: p}}))} onStatusChange={confirmVendorStatus} onView={(id) => loadDetail('vendor', id)} />}
            {activeTab === 'products' && <ProductsTab products={data.products} filters={filters.products} setPage={(p) => setFilters(prev => ({...prev, products: {...prev.products, page: p}}))} onDelete={confirmProductDelete} onView={(id) => loadDetail('product', id)} />}
            {activeTab === 'orders' && <OrdersTab orders={data.orders} filters={filters.orders} setPage={(p) => setFilters(prev => ({...prev, orders: {...prev.orders, page: p}}))} onView={(id) => loadDetail('order', id)} />}
            {activeTab === 'categories' && <CategoriesTab categories={data.categories} onAdd={() => setCategoryModal({ isOpen: true, data: null })} onEdit={(c) => setCategoryModal({ isOpen: true, data: c })} />}
            {activeTab === 'feedback' && <FeedbackTab feedback={data.feedback} />}
            {activeTab === 'profile' && <ProfileTab profile={data.profile} token={token} />}
          </>
        )}
      </main>

      {/* Confirmation Modal Overlay */}
      <ConfirmModal 
        isOpen={confirmDialog.isOpen} 
        title={confirmDialog.title} 
        message={confirmDialog.message} 
        confirmText={confirmDialog.confirmText} 
        confirmColor={confirmDialog.confirmColor} 
        onConfirm={() => { if(confirmDialog.action) confirmDialog.action(); setConfirmDialog(prev => ({ ...prev, isOpen: false })); }} 
        onCancel={() => setConfirmDialog(prev => ({ ...prev, isOpen: false }))} 
      />

      {categoryModal.isOpen && (
        <CategoryModal
          category={categoryModal.data || { name: '', icon: '📦', isActive: true, sortOrder: 0 }}
          onChange={(data) => setCategoryModal({ isOpen: true, data })}
          onSave={handleSaveCategory}
          onCancel={() => setCategoryModal({ isOpen: false, data: null })}
        />
      )}
    </div>
  );
}

// -----------------------------------------------------------------------------
// Tabs
// -----------------------------------------------------------------------------
function AnalyticsTab({ analytics }) {
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
      alert('Failed to export CSV. Please try again.');
    }
  };

  const stats = analytics.stats || {};
  const chartData = analytics.dailyStats?.map(day => ({ name: new Date(day._id).toLocaleDateString('en-US', { weekday: 'short' }), revenue: day.revenue, orders: day.count })) || [];
  const userChartData = analytics.userDailyStats?.map(day => ({ name: new Date(day._id).toLocaleDateString('en-US', { weekday: 'short' }), users: day.count })) || [];
  const categoryData = analytics.revenueByCategory?.map(c => ({ name: c._id, revenue: c.revenue })) || [];
  const recentOrders = analytics.recentOrders || [];

  const COLORS = ['#FF6F52', '#F9A826', '#34C759', '#007AFF', '#5856D6', '#FF2D55', '#2B2620', '#6E6557'];

  return (
    <>
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: '24px' }}>
        <button onClick={handleExportCSV} className="btn" style={{ backgroundColor: 'white', border: '1px solid #e5e4e7', color: 'var(--color-ink)' }}>
          <Download size={16} /> Export CSV
        </button>
      </div>

      <div className="dashboard-grid" style={{ marginBottom: '24px' }}>
        <StatCard title="Total Revenue" value={`Rs. ${(stats.totalRevenue || 0).toLocaleString()}`} icon={<TrendingUp />} color="coral" />
        <StatCard title="Total Orders" value={(stats.totalOrders || 0).toLocaleString()} icon={<ListOrdered />} color="success" />
        <StatCard title="Total Customers" value={(stats.totalCustomers || 0).toLocaleString()} icon={<Users />} color="ink" />
        <StatCard title="Total Vendors" value={(stats.totalVendors || 0).toLocaleString()} icon={<Store />} color="warning" />
      </div>
      
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '24px', marginBottom: '32px' }}>
        <MiniStatCard title="Delivered Orders" value={stats.completedOrders || 0} icon={<CheckCircle />} color="success" />
        <MiniStatCard title="Pending Vendors" value={stats.pendingVendors || 0} icon={<Clock />} color="warning" />
        <MiniStatCard title="Total Products" value={stats.totalProducts || 0} icon={<Package />} color="ink" />
        <MiniStatCard title="Suspended Vendors" value={stats.suspendedVendors || 0} icon={<XCircle />} color="danger" />
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
                    <stop offset="5%" stopColor="var(--color-coral)" stopOpacity={0.4}/>
                    <stop offset="95%" stopColor="var(--color-coral)" stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="rgba(43,38,32,0.06)" />
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill: 'var(--color-muted)', fontSize: 13}} dy={10} />
                <YAxis axisLine={false} tickLine={false} tick={{fill: 'var(--color-muted)', fontSize: 13}} dx={-10} tickFormatter={(val) => `Rs.${val}`} />
                <Tooltip contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: 'var(--shadow-lg)' }} itemStyle={{ color: 'var(--color-coral)', fontWeight: 600 }} />
                <Area type="monotone" dataKey="revenue" stroke="var(--color-coral)" strokeWidth={3} fillOpacity={1} fill="url(#colorRev)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>


        <div className="card animate-fade-in delay-300" style={{ height: '420px', display: 'flex', flexDirection: 'column' }}>
          <h3 style={{ marginBottom: '8px', fontSize: '18px', fontWeight: 'bold' }}>Revenue by Category</h3>
          <div style={{ flex: 1, minHeight: 0, position: 'relative' }}>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={categoryData} cx="50%" cy="50%" innerRadius={70} outerRadius={110} paddingAngle={4} dataKey="revenue" stroke="none">
                  {categoryData.map((entry, index) => (
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
                <tr><th>Order ID</th><th>Customer</th><th>Total</th><th>Status</th></tr>
              </thead>
              <tbody>
                {recentOrders.map(o => (
                  <tr key={o._id}>
                    <td style={{ fontWeight: 600, color: 'var(--color-ink)' }}>#{o._id.substring(o._id.length - 6).toUpperCase()}</td>
                    <td style={{ color: 'var(--color-muted)' }}>{o.customerId?.fullName || 'Unknown'}</td>
                    <td style={{ fontWeight: 500 }}>Rs. {o.totalAmount.toLocaleString()}</td>
                    <td><span className={`status-badge ${o.orderStatus === 'Delivered' ? 'success' : o.orderStatus === 'Cancelled' ? 'danger' : 'warning'}`}>{o.orderStatus}</span></td>
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
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{fill: 'var(--color-muted)', fontSize: 13}} dy={10} />
                <YAxis axisLine={false} tickLine={false} tick={{fill: 'var(--color-muted)', fontSize: 13}} dx={-10} />
                <Tooltip cursor={{fill: 'rgba(43,38,32,0.03)'}} contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: 'var(--shadow-lg)' }} itemStyle={{ color: 'var(--color-ink)', fontWeight: 600 }} />
                <Bar dataKey="users" fill="var(--color-ink)" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </>
  );
}

function UsersTab({ users, onToggle, filters, setPage }) {
  if (!users.length && filters.page === 1) return <TableSkeleton headers={['User', 'Email', 'Role', 'Status', 'Actions']} />;
  
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
            <thead><tr><th>User</th><th>Email</th><th>Role</th><th>Status</th><th>Actions</th></tr></thead>
            <tbody>
              {users.map(u => (
                <tr key={u._id}>
                  <td style={{ fontWeight: 500 }}>{u.fullName}</td>
                  <td style={{ color: 'var(--color-muted)' }}>{u.email}</td>
                  <td><span className="status-badge info">{u.role}</span></td>
                  <td><span className={`status-badge ${u.isActive ? 'success' : 'danger'}`}>{u.isActive ? 'Active' : 'Disabled'}</span></td>
                  <td>
                    <button onClick={() => onToggle(u._id, !u.isActive)} className="btn" style={{ padding: '6px 12px', fontSize: '13px', backgroundColor: u.isActive ? 'rgba(211,47,47,0.1)' : 'rgba(46,125,50,0.1)', color: u.isActive ? 'var(--color-danger)' : 'var(--color-success)' }}>
                      <Power size={14} /> {u.isActive ? 'Disable' : 'Enable'}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <PaginationFooter page={filters.page} setPage={setPage} />
      </div>
    </div>
  );
}

function VendorsTab({ vendors, onStatusChange, onView, filters, setPage }) {
  if (!vendors.length && filters.page === 1) return <TableSkeleton headers={['Shop Name', 'Owner', 'Status', 'Products', 'Actions']} />;
  
  const total = vendors.length;
  const approved = vendors.filter(v => v.vendorApprovalStatus === 'approved').length;

  return (
    <div className="animate-fade-in">
      <div style={{ display: 'flex', gap: '24px', marginBottom: '24px' }}>
        <MiniStatCard title="Total Vendors" value={total} icon={<Store />} color="ink" />
        <MiniStatCard title="Approved" value={approved} icon={<CheckCircle />} color="success" />
      </div>

      <div className="card">
        <div className="table-container" style={{ margin: 0, padding: 0, border: 'none', boxShadow: 'none' }}>
          <table className="data-table" style={{ margin: 0 }}>
            <thead><tr><th>Shop Name</th><th>Owner</th><th>Status</th><th>Products</th><th>Actions</th></tr></thead>
            <tbody>
              {vendors.map(v => (
                <tr key={v._id}>
                  <td style={{ fontWeight: 500 }}>{v.shopName || 'N/A'}</td>
                  <td style={{ color: 'var(--color-muted)' }}>{v.fullName}</td>
                  <td><span className={`status-badge ${v.vendorApprovalStatus === 'approved' ? 'success' : v.vendorApprovalStatus === 'suspended' ? 'danger' : 'warning'}`}>{v.vendorApprovalStatus}</span></td>
                  <td>{v.productCount || 0}</td>
                  <td>
                    <div style={{ display: 'flex', gap: '8px' }}>
                      <button onClick={() => onView(v._id)} className="btn" style={{ padding: '6px 12px', fontSize: '13px', backgroundColor: 'var(--color-cream)', color: 'var(--color-ink)' }}>View Detail</button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <PaginationFooter page={filters.page} setPage={setPage} />
      </div>
    </div>
  );
}

function ProductsTab({ products, onDelete, onView, filters, setPage }) {
  if (!products.length && filters.page === 1) return <TableSkeleton headers={['Product Name', 'Category', 'Price', 'Stock', 'Actions']} />;
  
  const total = products.length;
  const inStock = products.filter(p => p.stockQuantity > 0).length;

  return (
    <div className="animate-fade-in">
      <div style={{ display: 'flex', gap: '24px', marginBottom: '24px' }}>
        <MiniStatCard title="Total Products" value={total} icon={<Package />} color="ink" />
        <MiniStatCard title="In Stock" value={inStock} icon={<CheckCircle />} color="success" />
      </div>

      <div className="card">
        <div className="table-container" style={{ margin: 0, padding: 0, border: 'none', boxShadow: 'none' }}>
          <table className="data-table" style={{ margin: 0 }}>
            <thead><tr><th>Product Name</th><th>Category</th><th>Price</th><th>Stock</th><th>Actions</th></tr></thead>
            <tbody>
              {products.map(p => (
                <tr key={p._id}>
                  <td style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    {p.images?.length > 0 ? <img src={p.images[0]} style={{ width: '40px', height: '40px', borderRadius: '8px', objectFit: 'cover' }} /> : <div style={{ width: '40px', height: '40px', backgroundColor: 'var(--color-cream)', borderRadius: '8px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Package size={20} color="var(--color-muted)" /></div>}
                    <span style={{ fontWeight: 500 }}>{p.title}</span>
                  </td>
                  <td style={{ color: 'var(--color-muted)' }}>{p.category}</td>
                  <td>Rs. {p.price}</td>
                  <td><span className={`status-badge ${p.stockQuantity > 0 ? 'success' : 'danger'}`}>{p.stockQuantity}</span></td>
                  <td>
                    <button onClick={() => onView(p._id)} className="btn" style={{ padding: '6px 12px', fontSize: '13px', backgroundColor: 'var(--color-cream)', color: 'var(--color-ink)' }}>View</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <PaginationFooter page={filters.page} setPage={setPage} />
      </div>
    </div>
  );
}

function OrdersTab({ orders, onView, filters, setPage }) {
  if (!orders.length && filters.page === 1) return <TableSkeleton headers={['Order ID', 'Customer', 'Total', 'Status', 'Date']} />;
  
  const total = orders.length;
  const delivered = orders.filter(o => o.orderStatus === 'Delivered').length;

  return (
    <div className="animate-fade-in">
      <div style={{ display: 'flex', gap: '24px', marginBottom: '24px' }}>
        <MiniStatCard title="Total Orders" value={total} icon={<ListOrdered />} color="ink" />
        <MiniStatCard title="Delivered" value={delivered} icon={<CheckCircle />} color="success" />
      </div>

      <div className="card">
        <div className="table-container" style={{ margin: 0, padding: 0, border: 'none', boxShadow: 'none' }}>
          <table className="data-table" style={{ margin: 0 }}>
            <thead><tr><th>Order ID</th><th>Customer</th><th>Total</th><th>Status</th><th>Date</th></tr></thead>
            <tbody>
              {orders.map(o => (
                <tr key={o._id} onClick={() => onView(o._id)} style={{ cursor: 'pointer' }}>
                  <td style={{ fontWeight: 500 }}>{o._id.substring(o._id.length - 6).toUpperCase()}</td>
                  <td style={{ color: 'var(--color-muted)' }}>{o.customerId?.fullName || 'Unknown'}</td>
                  <td style={{ fontWeight: 500 }}>Rs. {o.totalAmount}</td>
                  <td><span className={`status-badge ${o.orderStatus === 'Delivered' ? 'success' : o.orderStatus === 'Cancelled' ? 'danger' : 'warning'}`}>{o.orderStatus}</span></td>
                  <td style={{ color: 'var(--color-muted)' }}>{new Date(o.createdAt).toLocaleDateString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <PaginationFooter page={filters.page} setPage={setPage} />
      </div>
    </div>
  );
}

function CategoriesTab({ categories, onAdd, onEdit }) {
  if (!categories.length) return <TableSkeleton headers={['Icon', 'Category Name', 'Status', 'Actions']} />;
  return (
    <div className="animate-fade-in">
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: '16px' }}>
        <button onClick={onAdd} className="btn" style={{ backgroundColor: 'var(--color-ink)', color: 'white' }}>
          <Plus size={16} /> Add Category
        </button>
      </div>
      <div className="card table-container" style={{ margin: 0, padding: 0, border: 'none', boxShadow: 'none' }}>
        <table className="data-table" style={{ margin: 0 }}>
          <thead><tr><th style={{ width: '80px' }}>Icon</th><th>Category Name</th><th>Status</th><th style={{ textAlign: 'right' }}>Actions</th></tr></thead>
          <tbody>
            {categories.map(c => (
              <tr key={c._id}>
                <td style={{ fontSize: '24px', textAlign: 'center' }}>{c.icon}</td>
                <td style={{ fontWeight: 500 }}>{c.name}</td>
                <td><span className={`status-badge ${c.isActive ? 'success' : 'danger'}`}>{c.isActive ? 'Active' : 'Hidden'}</span></td>
                <td style={{ textAlign: 'right' }}>
                  <button onClick={() => onEdit(c)} className="btn" style={{ padding: '6px 12px', fontSize: '13px', backgroundColor: 'var(--color-cream)', color: 'var(--color-ink)' }}>
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

// -----------------------------------------------------------------------------
// Detail Views
// -----------------------------------------------------------------------------
function VendorDetail({ data, onStatusChange }) {
  if (!data || !data.vendor) return null;
  const { vendor, stats, products, recentOrders } = data;
  
  return (
    <div className="animate-fade-in">
      <div className="card" style={{ display: 'flex', alignItems: 'center', gap: '20px', marginBottom: '24px' }}>
        <div style={{ width: '64px', height: '64px', backgroundColor: 'var(--color-coral)', borderRadius: '16px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Store color="white" size={32} /></div>
        <div style={{ flex: 1 }}>
          <h2 style={{ marginBottom: '4px' }}>{vendor.shopName || vendor.fullName}</h2>
          <p style={{ color: 'var(--color-muted)' }}>{vendor.email} • {vendor.phone}</p>
        </div>
        <div style={{ display: 'flex', gap: '12px' }}>
          {vendor.vendorApprovalStatus !== 'approved' && <button onClick={() => onStatusChange(vendor._id, 'approved')} className="btn" style={{ backgroundColor: 'var(--color-success)' }}><CheckCircle size={16} /> Approve</button>}
          {vendor.vendorApprovalStatus !== 'suspended' && <button onClick={() => onStatusChange(vendor._id, 'suspended')} className="btn" style={{ backgroundColor: 'var(--color-danger)' }}><XCircle size={16} /> Suspend</button>}
        </div>
      </div>
      
      <div className="dashboard-grid" style={{ marginTop: 0 }}>
        <StatCard title="Products" value={stats.totalProducts || 0} icon={<Package />} color="ink" />
        <StatCard title="Orders" value={stats.totalOrders || 0} icon={<ListOrdered />} color="warning" />
        <StatCard title="Delivered" value={stats.deliveredOrders || 0} icon={<CheckCircle />} color="success" />
        <StatCard title="Revenue" value={`Rs. ${stats.totalRevenue || 0}`} icon={<TrendingUp />} color="coral" />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px' }}>
        <div className="card">
          <h3 style={{ marginBottom: '16px' }}>Shop Products</h3>
          <ProductsTab products={products} onDelete={() => {}} onView={() => {}} />
        </div>
        <div className="card">
          <h3 style={{ marginBottom: '16px' }}>Recent Orders</h3>
          <OrdersTab orders={recentOrders} />
        </div>
      </div>
    </div>
  );
}

function ProductDetail({ data, onDelete }) {
  if (!data || !data.product) return null;
  const p = data.product;
  const rating = p.ratingsAverage || 0;
  const ratingCount = p.ratingsQuantity || 0;

  return (
    <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '24px', maxWidth: '900px' }}>
      {/* Top Banner / Images */}
      <div className="card" style={{ padding: '24px' }}>
        <div style={{ display: 'flex', gap: '32px' }}>
          <div style={{ width: '280px', display: 'flex', flexDirection: 'column', gap: '12px' }}>
            <div style={{ width: '280px', height: '280px', borderRadius: '16px', backgroundColor: 'var(--color-cream)', overflow: 'hidden' }}>
              {p.images?.length > 0 ? <img src={p.images[0]} style={{ width: '100%', height: '100%', objectFit: 'cover' }} /> : <Package size={64} color="var(--color-muted)" style={{ margin: '108px' }} />}
            </div>
            {p.images?.length > 1 && (
              <div style={{ display: 'flex', gap: '8px', overflowX: 'auto' }}>
                {p.images.slice(1).map((img, i) => (
                  <img key={i} src={img} style={{ width: '60px', height: '60px', borderRadius: '8px', objectFit: 'cover' }} />
                ))}
              </div>
            )}
          </div>
          
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
            <div style={{ display: 'inline-block', padding: '4px 12px', backgroundColor: 'rgba(43,38,32,0.05)', borderRadius: '100px', fontSize: '12px', fontWeight: '500', color: 'var(--color-muted)', alignSelf: 'flex-start', marginBottom: '12px' }}>
              {p.category || 'Uncategorized'}
            </div>
            
            <h2 style={{ fontSize: '32px', marginBottom: '12px', lineHeight: '1.2' }}>{p.title}</h2>
            
            <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '24px' }}>
              <p style={{ color: 'var(--color-coral)', fontSize: '28px', fontWeight: '600' }}>Rs. {p.price} <span style={{ fontSize: '15px', color: 'var(--color-muted)' }}>/ {p.priceUnit || 'item'}</span></p>
              {p.originalPrice && <p style={{ fontSize: '16px', color: 'var(--color-muted)', textDecoration: 'line-through' }}>Rs. {p.originalPrice}</p>}
            </div>

            <div style={{ display: 'flex', gap: '32px', marginBottom: '24px', paddingBottom: '24px', borderBottom: '1px solid rgba(43,38,32,0.05)' }}>
              <div>
                <p style={{ color: 'var(--color-muted)', fontSize: '13px', marginBottom: '4px' }}>Stock</p>
                <span className={`status-badge ${p.stockQuantity > 0 ? 'success' : 'danger'}`} style={{ padding: '4px 10px' }}>{p.stockQuantity} units</span>
              </div>
              <div>
                <p style={{ color: 'var(--color-muted)', fontSize: '13px', marginBottom: '4px' }}>Status</p>
                <span className={`status-badge ${p.productStatus === 'Available' ? 'success' : 'warning'}`} style={{ padding: '4px 10px' }}>{p.productStatus || 'Unknown'}</span>
              </div>
              <div>
                <p style={{ color: 'var(--color-muted)', fontSize: '13px', marginBottom: '4px' }}>Rating</p>
                <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '15px', fontWeight: '500' }}>
                  <Star size={16} color="var(--color-warning)" fill="var(--color-warning)" /> {rating.toFixed(1)} <span style={{ color: 'var(--color-muted)', fontSize: '13px', fontWeight: '400' }}>({ratingCount})</span>
                </div>
              </div>
            </div>

            <h4 style={{ marginBottom: '8px', fontSize: '16px' }}>Description</h4>
            <p style={{ color: 'var(--color-muted)', lineHeight: '1.6', marginBottom: '24px' }}>{p.description || 'No description provided.'}</p>
            
            {p.location && (
              <div style={{ display: 'flex', gap: '8px', color: 'var(--color-muted)', marginBottom: '24px' }}>
                <MapPin size={18} /> <span style={{ fontSize: '14px', lineHeight: '1.5' }}>{typeof p.location === 'object' ? `${p.location.street}, ${p.location.city}` : p.location}</span>
              </div>
            )}

            <div style={{ marginTop: 'auto', display: 'flex', justifyContent: 'flex-end' }}>
              <button onClick={() => onDelete(p._id)} className="btn" style={{ backgroundColor: 'white', color: 'var(--color-danger)', border: '1px solid rgba(211,47,47,0.3)' }}><Trash2 size={16} /> Delete Product</button>
            </div>
          </div>
        </div>
      </div>

      {/* Vendor Info Card */}
      {p.vendorId && (
        <div className="card" style={{ padding: '24px' }}>
          <h3 style={{ marginBottom: '16px', fontSize: '18px' }}>Vendor Information</h3>
          <div style={{ display: 'flex', alignItems: 'center', gap: '16px', backgroundColor: 'var(--color-cream)', padding: '16px', borderRadius: '12px' }}>
            <div style={{ width: '48px', height: '48px', borderRadius: '50%', backgroundColor: 'var(--color-coral)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontSize: '20px', fontWeight: '600' }}>
              {p.vendorId.shopName ? p.vendorId.shopName[0].toUpperCase() : (p.vendorId.fullName ? p.vendorId.fullName[0].toUpperCase() : 'V')}
            </div>
            <div>
              <p style={{ fontWeight: '600', fontSize: '16px', marginBottom: '4px' }}>{p.vendorId.shopName || p.vendorName || 'Unknown Vendor'}</p>
              <p style={{ color: 'var(--color-muted)', fontSize: '14px' }}>{p.vendorId.fullName} • {p.vendorId.email || ''}</p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function OrderDetail({ data }) {
  if (!data) return null;
  const o = data;
  return (
    <div className="animate-fade-in card" style={{ maxWidth: '800px' }}>
      <h2 style={{ marginBottom: '16px' }}>Order #{o._id.substring(o._id.length - 6).toUpperCase()}</h2>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px', marginBottom: '24px' }}>
        <div><p style={{ color: 'var(--color-muted)', fontSize: '14px' }}>Customer</p><p style={{ fontWeight: '500' }}>{o.customerId?.fullName || 'Unknown'}</p></div>
        <div><p style={{ color: 'var(--color-muted)', fontSize: '14px' }}>Vendor</p><p style={{ fontWeight: '500' }}>{o.vendorId?.shopName || o.vendorId?.fullName || 'Unknown'}</p></div>
        <div><p style={{ color: 'var(--color-muted)', fontSize: '14px' }}>Status</p><span className={`status-badge ${o.orderStatus === 'Delivered' ? 'success' : o.orderStatus === 'Cancelled' ? 'danger' : 'warning'}`}>{o.orderStatus}</span></div>
        <div><p style={{ color: 'var(--color-muted)', fontSize: '14px' }}>Total Amount</p><p style={{ fontWeight: '600', fontSize: '18px', color: 'var(--color-coral)' }}>Rs. {o.totalAmount}</p></div>
      </div>
      <div style={{ backgroundColor: 'var(--color-cream)', padding: '16px', borderRadius: '12px', marginBottom: '24px' }}>
        <h4 style={{ marginBottom: '8px' }}>Shipping Address</h4>
        <p style={{ color: 'var(--color-ink)', fontSize: '14px', lineHeight: '1.5' }}>
          {o.shippingAddress?.fullName}<br/>{o.shippingAddress?.street}, {o.shippingAddress?.landmark}<br/>{o.shippingAddress?.city}, {o.shippingAddress?.state} {o.shippingAddress?.zipCode}<br/>{o.shippingAddress?.phone}
        </p>
      </div>
      <h4 style={{ marginBottom: '12px' }}>Order Items ({o.products?.length || 0})</h4>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
        {o.products?.map((item, idx) => (
          <div key={idx} style={{ display: 'flex', justifyContent: 'space-between', padding: '12px', border: '1px solid rgba(43,38,32,0.05)', borderRadius: '8px' }}>
            <span>Item ID: {item.product?.toString().substring(item.product?.toString().length - 6)}</span>
            <span>{item.quantity} {item.priceUnit || 'item'} x Rs. {item.price}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

// -----------------------------------------------------------------------------
// Subcomponents
// -----------------------------------------------------------------------------
function NavItem({ icon, label, active, onClick }) {
  return (
    <button onClick={onClick} style={{
      display: 'flex', alignItems: 'center', gap: '12px', padding: '12px 16px', borderRadius: '10px', width: '100%', border: 'none', cursor: 'pointer',
      color: active ? 'white' : 'var(--color-ink)', backgroundColor: active ? 'var(--color-ink)' : 'transparent', fontWeight: '500', fontSize: '15px', fontFamily: 'inherit', transition: 'all 0.2s', textAlign: 'left'
    }}><span style={{ color: active ? 'var(--color-coral)' : 'var(--color-muted)' }}>{icon}</span>{label}</button>
  );
}


function StatCard({ title, value, icon, color = 'coral' }) {
  const bgColors = {
    coral: 'linear-gradient(135deg, rgba(255,111,82,0.1) 0%, rgba(255,111,82,0.02) 100%)',
    success: 'linear-gradient(135deg, rgba(46,125,50,0.1) 0%, rgba(46,125,50,0.02) 100%)',
    warning: 'linear-gradient(135deg, rgba(249,168,38,0.1) 0%, rgba(249,168,38,0.02) 100%)',
    ink: 'linear-gradient(135deg, rgba(43,38,32,0.1) 0%, rgba(43,38,32,0.02) 100%)',
    danger: 'linear-gradient(135deg, rgba(211,47,47,0.1) 0%, rgba(211,47,47,0.02) 100%)',
  };
  const borderColors = { coral: '#FF6F5230', success: '#2E7D3230', warning: '#F9A82630', ink: '#2B262030', danger: '#D32F2F30' };
  const iconColors = { coral: '#FF6F52', success: '#2E7D32', warning: '#F9A826', ink: '#2B2620', danger: '#D32F2F' };

  return (
    <div className="card hover-expand" style={{ background: bgColors[color], border: `1px solid ${borderColors[color]}`, display: 'flex', flexDirection: 'column', gap: '20px', position: 'relative', overflow: 'hidden', padding: '28px' }}>
      <div style={{ position: 'absolute', right: '-15%', top: '-15%', opacity: 0.04, transform: 'scale(3.5)' }}>
        {icon}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: '16px', position: 'relative', zIndex: 1 }}>
        <div style={{ width: '48px', height: '48px', borderRadius: '14px', backgroundColor: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', color: iconColors[color], boxShadow: '0 8px 16px rgba(0,0,0,0.06)' }}>
          {React.cloneElement(icon, { size: 24 })}
        </div>
        <span style={{ fontSize: '15px', color: 'var(--color-muted)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.5px' }}>{title}</span>
      </div>
      <div style={{ position: 'relative', zIndex: 1 }}>
        <h3 style={{ fontSize: '38px', margin: 0, fontWeight: '800', color: 'var(--color-ink)', letterSpacing: '-1px' }}>{value}</h3>
      </div>
    </div>
  );
}

function MiniStatCard({ title, value, icon, color = 'ink' }) {
  const iconColors = { coral: '#FF6F52', success: '#2E7D32', warning: '#F9A826', ink: '#2B2620', danger: '#D32F2F' };
  const bgColors = { coral: '#FF6F5215', success: '#2E7D3215', warning: '#F9A82615', ink: '#2B262015', danger: '#D32F2F15' };
  
  return (
    <div className="card" style={{ display: 'flex', alignItems: 'center', gap: '16px', padding: '20px' }}>
      <div style={{ width: '44px', height: '44px', borderRadius: '12px', backgroundColor: bgColors[color], color: iconColors[color], display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        {icon}
      </div>
      <div>
        <p style={{ color: 'var(--color-muted)', fontSize: '13px', fontWeight: '500', marginBottom: '2px' }}>{title}</p>
        <h4 style={{ fontSize: '20px', fontWeight: '600' }}>{value}</h4>
      </div>
    </div>
  );
}

function ConfirmModal({ isOpen, title, message, onConfirm, onCancel, confirmText = 'Confirm', confirmColor = 'danger' }) {
  if (!isOpen) return null;
  return (
    <div style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(43,38,32,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9999, backdropFilter: 'blur(4px)' }} className="animate-fade-in">
      <div className="card" style={{ width: '420px', maxWidth: '90%', padding: '32px', boxShadow: 'var(--shadow-lg)', border: '1px solid rgba(255,255,255,0.2)' }}>
        <h3 style={{ marginBottom: '12px', fontSize: '20px' }}>{title}</h3>
        <p style={{ color: 'var(--color-muted)', marginBottom: '32px', lineHeight: 1.5, fontSize: '15px' }}>{message}</p>
        <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
          <button onClick={onCancel} className="btn" style={{ backgroundColor: 'white', color: 'var(--color-ink)', border: '1px solid #e5e4e7', padding: '10px 20px' }}>Cancel</button>
          <button onClick={onConfirm} className="btn" style={{ backgroundColor: `var(--color-${confirmColor})`, padding: '10px 20px' }}>{confirmText}</button>
        </div>
      </div>
    </div>
  );
}

// -----------------------------------------------------------------------------
// Skeletons
// -----------------------------------------------------------------------------
function Skeleton({ width, height, borderRadius = '8px', style = {} }) {
  return <div className="skeleton-pulse" style={{ width, height, borderRadius, backgroundColor: 'rgba(43,38,32,0.06)', ...style }}></div>;
}

function TableSkeleton({ headers }) {
  return (
    <div className="table-container animate-fade-in">
      <table className="data-table">
        <thead><tr>{headers.map((h, i) => <th key={i}>{h}</th>)}</tr></thead>
        <tbody>
          {[1,2,3,4,5].map(i => (
            <tr key={i}>
              {headers.map((_, j) => <td key={j}><Skeleton width={j === 0 ? "150px" : "100px"} height="20px" /></td>)}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function AnalyticsSkeleton() {
  return (
    <div className="animate-fade-in">
      <div className="dashboard-grid" style={{ marginBottom: '24px' }}>
        {[1,2,3,4].map(i => <div key={i} className="card" style={{ padding: '24px' }}><Skeleton width="120px" height="16px" style={{marginBottom:'12px'}}/><Skeleton width="80px" height="36px"/></div>)}
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '24px', marginBottom: '24px' }}>
        {[1,2,3,4].map(i => <div key={i} className="card" style={{ display: 'flex', gap: '16px', alignItems: 'center', padding: '16px 20px' }}><Skeleton width="48px" height="48px" borderRadius="12px"/><div style={{flex:1}}><Skeleton width="60px" height="14px" style={{marginBottom:'4px'}}/><Skeleton width="40px" height="24px"/></div></div>)}
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px', marginBottom: '24px' }}>
        <div className="card" style={{ height: '400px' }}><Skeleton width="200px" height="24px" style={{marginBottom:'24px'}}/><Skeleton width="100%" height="280px"/></div>
        <div className="card" style={{ height: '400px' }}><Skeleton width="200px" height="24px" style={{marginBottom:'24px'}}/><Skeleton width="100%" height="280px"/></div>
      </div>
    </div>
  );
}

function DetailSkeleton() {
  return (
    <div className="card animate-fade-in" style={{ maxWidth: '800px', display: 'flex', gap: '32px' }}>
      <Skeleton width="200px" height="200px" borderRadius="16px" />
      <div style={{ flex: 1 }}>
        <Skeleton width="100px" height="24px" style={{marginBottom:'12px'}} borderRadius="100px" />
        <Skeleton width="80%" height="40px" style={{marginBottom:'16px'}} />
        <Skeleton width="120px" height="30px" style={{marginBottom:'24px'}} />
        <Skeleton width="100%" height="16px" style={{marginBottom:'8px'}} />
        <Skeleton width="90%" height="16px" style={{marginBottom:'8px'}} />
        <Skeleton width="60%" height="16px" style={{marginBottom:'24px'}} />
      </div>
    </div>
  );
}

// -----------------------------------------------------------------------------
// New Tabs & Pagination
// -----------------------------------------------------------------------------
function PaginationFooter({ page, setPage }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: '16px', padding: '16px 24px', borderTop: '1px solid rgba(43,38,32,0.05)' }}>
      <button onClick={() => setPage(Math.max(1, page - 1))} disabled={page === 1} className="btn" style={{ padding: '8px 16px', backgroundColor: page === 1 ? 'rgba(43,38,32,0.05)' : 'var(--color-ink)', color: page === 1 ? 'var(--color-muted)' : 'white' }}>
        <ChevronLeft size={16} /> Prev
      </button>
      <span style={{ fontWeight: '500' }}>Page {page}</span>
      <button onClick={() => setPage(page + 1)} className="btn" style={{ padding: '8px 16px', backgroundColor: 'var(--color-ink)', color: 'white' }}>
        Next <ChevronRight size={16} />
      </button>
    </div>
  );
}

function FeedbackTab({ feedback }) {
  const [loading, setLoading] = useState(true);
  useEffect(() => { const t = setTimeout(() => setLoading(false), 800); return () => clearTimeout(t); }, []);

  if (loading && !feedback.length) return <TableSkeleton headers={['User', 'Rating', 'Comment', 'Date']} />;
  
  return (
    <div className="animate-fade-in">
      <div className="card table-container" style={{ margin: 0, padding: 0, border: 'none', boxShadow: 'none' }}>
        <table className="data-table" style={{ margin: 0 }}>
          <thead><tr><th>User</th><th>Rating</th><th>Comment</th><th>Date</th></tr></thead>
          <tbody>
            {feedback.length > 0 ? feedback.map(f => (
              <tr key={f._id}>
                <td style={{ fontWeight: 500 }}>{f.userId?.fullName || 'Anonymous'}</td>
                <td><Star size={14} color="var(--color-warning)" fill="var(--color-warning)" style={{ verticalAlign: 'middle', marginRight: 4 }}/>{f.rating}/5</td>
                <td style={{ maxWidth: '300px', whiteSpace: 'normal', color: 'var(--color-muted)' }}>{f.comment}</td>
                <td style={{ color: 'var(--color-muted)' }}>{new Date(f.createdAt).toLocaleDateString()}</td>
              </tr>
            )) : (
              <tr><td colSpan="4" style={{ textAlign: 'center', padding: '40px', color: 'var(--color-muted)' }}>No feedback received yet.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function ProfileTab({ profile, token }) {
  const [showPasswordForm, setShowPasswordForm] = useState(false);
  const [pwData, setPwData] = useState({ currentPassword: '', newPassword: '', confirmPassword: '' });
  const [pwStatus, setPwStatus] = useState({ type: '', msg: '' });

  const handlePasswordChange = async (e) => {
    e.preventDefault();
    setPwStatus({ type: 'loading', msg: 'Updating...' });
    try {
      const res = await fetch('https://localtrade-backend-jg9l.onrender.com/api/v1/auth/change-password', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify(pwData)
      });
      const data = await res.json();
      if (data.success || data.status === 'success') {
        setPwStatus({ type: 'success', msg: 'Password successfully updated!' });
        setPwData({ currentPassword: '', newPassword: '', confirmPassword: '' });
        setTimeout(() => { setShowPasswordForm(false); setPwStatus({ type: '', msg: '' }); }, 2000);
      } else {
        setPwStatus({ type: 'error', msg: data.message || 'Update failed' });
      }
    } catch (err) {
      setPwStatus({ type: 'error', msg: 'Connection error' });
    }
  };

  if (!profile) return <AnalyticsSkeleton />;
  const u = profile.user || profile;
  
  return (
    <div className="card animate-fade-in" style={{ maxWidth: '600px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '20px', marginBottom: '32px' }}>
        <div style={{ width: '80px', height: '80px', backgroundColor: 'var(--color-coral)', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontSize: '32px', fontWeight: 'bold' }}>
          {u.fullName?.[0]?.toUpperCase() || 'A'}
        </div>
        <div>
          <h2 style={{ fontSize: '24px', marginBottom: '4px' }}>{u.fullName}</h2>
          <p style={{ color: 'var(--color-muted)' }}>{u.email}</p>
          <span className="status-badge info" style={{ marginTop: '8px' }}>{u.role?.toUpperCase()}</span>
        </div>
      </div>
      <div style={{ backgroundColor: 'var(--color-cream)', padding: '24px', borderRadius: '16px' }}>
        <h3 style={{ marginBottom: '16px', fontSize: '18px' }}>Account Settings</h3>
        {!showPasswordForm ? (
          <>
            <p style={{ color: 'var(--color-muted)', marginBottom: '16px', lineHeight: 1.5 }}>Update your security credentials below.</p>
            <button onClick={() => setShowPasswordForm(true)} className="btn" style={{ backgroundColor: 'var(--color-ink)', color: 'white' }}>Change Password</button>
          </>
        ) : (
          <form onSubmit={handlePasswordChange} className="animate-fade-in">
            <div style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500' }}>Current Password</label>
              <input type="password" value={pwData.currentPassword} onChange={e => setPwData({...pwData, currentPassword: e.target.value})} className="input-field" required style={{ width: '100%', backgroundColor: 'white' }} />
            </div>
            <div style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500' }}>New Password</label>
              <input type="password" value={pwData.newPassword} onChange={e => setPwData({...pwData, newPassword: e.target.value})} className="input-field" required style={{ width: '100%', backgroundColor: 'white' }} />
            </div>
            <div style={{ marginBottom: '24px' }}>
              <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500' }}>Confirm New Password</label>
              <input type="password" value={pwData.confirmPassword} onChange={e => setPwData({...pwData, confirmPassword: e.target.value})} className="input-field" required style={{ width: '100%', backgroundColor: 'white' }} />
            </div>
            {pwStatus.msg && (
              <div style={{ marginBottom: '16px', padding: '12px', borderRadius: '8px', fontSize: '14px', backgroundColor: pwStatus.type === 'success' ? 'rgba(46,125,50,0.1)' : 'rgba(211,47,47,0.1)', color: pwStatus.type === 'success' ? 'var(--color-success)' : 'var(--color-danger)' }}>
                {pwStatus.msg}
              </div>
            )}
            <div style={{ display: 'flex', gap: '12px' }}>
              <button type="submit" className="btn" style={{ backgroundColor: 'var(--color-coral)' }}>Save Password</button>
              <button type="button" onClick={() => { setShowPasswordForm(false); setPwStatus({type:'',msg:''}); }} className="btn" style={{ backgroundColor: 'transparent', color: 'var(--color-ink)', border: '1px solid #e5e4e7' }}>Cancel</button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}

function CategoryModal({ category, onChange, onSave, onCancel }) {
  return (
    <div style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(43,38,32,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9999, backdropFilter: 'blur(4px)' }} className="animate-fade-in">
      <div className="card" style={{ width: '480px', maxWidth: '90%', padding: '32px', boxShadow: 'var(--shadow-lg)' }}>
        <h3 style={{ marginBottom: '24px', fontSize: '20px' }}>{category._id ? 'Edit Category' : 'Add Category'}</h3>
        <form onSubmit={onSave}>
          <div style={{ marginBottom: '16px' }}>
            <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500' }}>Category Name</label>
            <input type="text" value={category.name} onChange={e => onChange({...category, name: e.target.value})} className="input-field" required style={{ width: '100%' }} />
          </div>
          <div style={{ marginBottom: '16px', display: 'flex', gap: '16px' }}>
            <div style={{ flex: 1 }}>
              <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500' }}>Icon (Emoji)</label>
              <input type="text" value={category.icon} onChange={e => onChange({...category, icon: e.target.value})} className="input-field" required style={{ width: '100%', fontSize: '20px' }} />
            </div>
            <div style={{ flex: 1 }}>
              <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500' }}>Sort Order</label>
              <input type="number" value={category.sortOrder} onChange={e => onChange({...category, sortOrder: Number(e.target.value)})} className="input-field" required style={{ width: '100%' }} />
            </div>
          </div>
          <div style={{ marginBottom: '32px' }}>
            <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer' }}>
              <input type="checkbox" checked={category.isActive} onChange={e => onChange({...category, isActive: e.target.checked})} style={{ width: '18px', height: '18px', accentColor: 'var(--color-coral)' }} />
              <span style={{ fontWeight: '500' }}>Active Category</span>
            </label>
            <p style={{ color: 'var(--color-muted)', fontSize: '13px', marginTop: '4px', marginLeft: '26px' }}>Inactive categories will be hidden from the customer app.</p>
          </div>
          <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
            <button type="button" onClick={onCancel} className="btn" style={{ backgroundColor: 'white', color: 'var(--color-ink)', border: '1px solid #e5e4e7' }}>Cancel</button>
            <button type="submit" className="btn" style={{ backgroundColor: 'var(--color-coral)' }}>{category._id ? 'Save Changes' : 'Create Category'}</button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default App;
