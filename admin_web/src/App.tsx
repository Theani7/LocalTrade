import React, { useState, useEffect } from 'react';
import {
  LayoutDashboard,
  Users,
  ShoppingBag,
  Store,
  Search,
  Bell,
  LogOut,
  ChevronLeft,
  ListOrdered,
  Tags,
  MessageSquare,
  UserCircle,
  XCircle,
  CheckCheck
} from 'lucide-react';
import './index.css';

import {
  API_URL,
  TabType,
  DetailViewType,
  DetailViewState,
  ConfirmDialogState,
  CategoryModalState,
  TabFilters,
  AppData,
  Category,
  User,
  Vendor
} from './types';

import { NavItem } from './components/common/NavItem';
import { ConfirmModal } from './components/common/ConfirmModal';
import { CategoryModal } from './components/common/CategoryModal';
import { DetailSkeleton } from './components/common/Skeletons';

import { AnalyticsTab } from './components/tabs/AnalyticsTab';
import { UsersTab } from './components/tabs/UsersTab';
import { VendorsTab } from './components/tabs/VendorsTab';
import { ProductsTab } from './components/tabs/ProductsTab';
import { OrdersTab } from './components/tabs/OrdersTab';
import { CategoriesTab } from './components/tabs/CategoriesTab';
import { FeedbackTab } from './components/tabs/FeedbackTab';
import { ProfileTab } from './components/tabs/ProfileTab';

import { VendorDetail } from './components/details/VendorDetail';
import { ProductDetail } from './components/details/ProductDetail';
import { OrderDetail } from './components/details/OrderDetail';

export function App() {
  const [token, setToken] = useState<string | null>(localStorage.getItem('adminToken'));
  const [email, setEmail] = useState<string>('');
  const [password, setPassword] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string>('');

  const [activeTab, setActiveTab] = useState<TabType>('overview');
  const [detailView, setDetailView] = useState<DetailViewState | null>(null);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [confirmDialog, setConfirmDialog] = useState<ConfirmDialogState>({ isOpen: false });
  const [showNotifications, setShowNotifications] = useState<boolean>(false);
  const [categoryModal, setCategoryModal] = useState<CategoryModalState>({ isOpen: false, data: null });

  const [filters, setFilters] = useState<TabFilters>({
    users: { page: 1, limit: 10, role: '' },
    vendors: { page: 1, limit: 10, status: '' },
    products: { page: 1, limit: 10 },
    orders: { page: 1, limit: 10 }
  });

  const [data, setData] = useState<AppData>({
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

  const handleLogout = () => {
    localStorage.removeItem('adminToken');
    setToken(null);
    setData({
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
    setDetailView(null);
  };

  const fetchAnalytics = async () => {
    try {
      const res = await fetch(`${API_URL}/admin/analytics`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const resData = await res.json();
      if (resData.status === 'success') {
        setData(prev => ({ ...prev, analytics: resData.data }));
      } else if (res.status === 401) {
        handleLogout();
      }
    } catch (err) {
      console.error(err);
    }
  };

  const fetchList = async (stateKey: string, endpointOverride?: string) => {
    try {
      let ep = endpointOverride || `admin/${stateKey}`;
      const queryParams = new URLSearchParams();

      if (['users', 'vendors', 'products', 'orders'].includes(stateKey)) {
        const filterKey = stateKey as keyof TabFilters;
        const tabFilter = filters[filterKey];
        if (searchQuery) queryParams.append('search', searchQuery);
        if (tabFilter?.page) queryParams.append('page', String(tabFilter.page));
        if (tabFilter?.limit) queryParams.append('limit', String(tabFilter.limit));
        if ('role' in tabFilter && tabFilter.role) queryParams.append('role', tabFilter.role);
        if ('status' in tabFilter && tabFilter.status) queryParams.append('status', tabFilter.status);
      }

      const qs = queryParams.toString();
      if (qs) ep += (ep.includes('?') ? '&' : '?') + qs;

      const res = await fetch(`${API_URL}/${ep}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const resData = await res.json();
      if (resData.status === 'success' || resData.success === true) {
        const arr =
          resData.data?.[stateKey] ||
          resData.data?.data ||
          resData.data?.categories ||
          resData.data?.feedback ||
          resData.data ||
          resData.data?.user ||
          [];
        const stats = resData.data?.stats || null;
        setData(prev => ({
          ...prev,
          [stateKey]: arr,
          stats: { ...(prev.stats || {}), [stateKey]: stats }
        }));
      }
    } catch (err) {
      console.error(err);
    }
  };

  const fetchNotifications = async () => {
    try {
      const res = await fetch(`${API_URL}/notifications`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const resData = await res.json();
      if (resData.success) {
        setData(prev => ({ ...prev, notifications: resData.data?.notifications || [] }));
      }
    } catch (err) {
      console.error(err);
    }
  };

  const markNotificationRead = async (id: string) => {
    try {
      const res = await fetch(`${API_URL}/notifications/${id}/read`, {
        method: 'PATCH',
        headers: { Authorization: `Bearer ${token}` }
      });
      const resData = await res.json();
      if (resData.success) {
        setData(prev => ({
          ...prev,
          notifications: prev.notifications.map(n => (n._id === id ? { ...n, isRead: true } : n))
        }));
      }
    } catch (err) {
      console.error(err);
    }
  };

  const markAllNotificationsRead = async () => {
    try {
      const res = await fetch(`${API_URL}/notifications/mark-all-read`, {
        method: 'PATCH',
        headers: { Authorization: `Bearer ${token}` }
      });
      const resData = await res.json();
      if (resData.success) {
        setData(prev => ({
          ...prev,
          notifications: prev.notifications.map(n => ({ ...n, isRead: true }))
        }));
      }
    } catch (err) {
      console.error(err);
    }
  };

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
        const tabKey = activeTab as keyof TabFilters;
        setFilters(prev => ({ ...prev, [tabKey]: { ...prev[tabKey], page: 1 } })); // Reset page on search
        fetchList(activeTab);
      }
    }, 400);
    return () => clearTimeout(handler);
  }, [searchQuery]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const res = await fetch(`${API_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      });
      const resData = await res.json();
      if (resData.status === 'success' && resData.data?.user?.role === 'admin') {
        localStorage.setItem('adminToken', resData.token);
        setToken(resData.token);
      } else {
        setError(resData.message || 'Access denied. Admin only.');
      }
    } catch (err) {
      console.error(err);
      setError('Connection error.');
    } finally {
      setLoading(false);
    }
  };

  const loadDetail = async (type: DetailViewType, id: string) => {
    if (type === 'order') {
      const orderData =
        data.orders.find(o => o._id === id) ||
        (data.analytics?.recentOrders || []).find(o => o._id === id);
      setDetailView({ type, id, data: orderData, loading: false });
      return;
    }

    setDetailView({ type, id, data: null, loading: true });
    try {
      const res = await fetch(`${API_URL}/admin/${type}s/${id}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const resData = await res.json();
      if (resData.status === 'success') {
        setDetailView({ type, id, data: resData.data, loading: false });
      }
    } catch (err) {
      console.error(err);
    }
  };

  const toggleUserStatus = async (id: string) => {
    await fetch(`${API_URL}/admin/users/${id}/toggle-status`, {
      method: 'PATCH',
      headers: { Authorization: `Bearer ${token}` }
    });
    fetchList('users');
  };

  const changeVendorStatus = async (id: string, status: string) => {
    await fetch(`${API_URL}/admin/vendors/${id}/status`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify({ status })
    });
    fetchList('vendors');
    if (detailView?.type === 'vendor' && detailView.id === id) {
      loadDetail('vendor', id);
    }
  };

  const deleteProduct = async (id: string) => {
    await fetch(`${API_URL}/admin/products/${id}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${token}` }
    });
    fetchList('products');
    if (detailView?.type === 'product' && detailView.id === id) {
      setDetailView(null);
    }
  };

  const confirmLogout = () =>
    setConfirmDialog({
      isOpen: true,
      title: 'Log Out',
      message: 'Are you sure you want to securely log out of the admin console?',
      action: handleLogout,
      confirmText: 'Log Out',
      confirmColor: 'danger'
    });

  const confirmUserToggle = (idOrUser: string | User, nextActive?: boolean) => {
    const user = typeof idOrUser === 'object' ? idOrUser : data.users.find(u => u._id === idOrUser);
    const isActive = user ? user.isActive : !nextActive;
    const name = user ? user.fullName : 'this user';
    const id = typeof idOrUser === 'string' ? idOrUser : user?._id || '';

    setConfirmDialog({
      isOpen: true,
      title: isActive ? 'Suspend User' : 'Activate User',
      message: `Are you sure you want to ${isActive ? 'suspend' : 'activate'} ${name}?`,
      action: () => toggleUserStatus(id),
      confirmText: isActive ? 'Suspend' : 'Activate',
      confirmColor: isActive ? 'danger' : 'success'
    });
  };

  const confirmVendorStatus = (vendorId: string, status: string) =>
    setConfirmDialog({
      isOpen: true,
      title: status === 'approved' ? 'Approve Vendor' : 'Suspend Vendor',
      message: `Are you sure you want to ${status === 'approved' ? 'approve' : 'suspend'} this vendor?`,
      action: () => changeVendorStatus(vendorId, status),
      confirmText: status === 'approved' ? 'Approve' : 'Suspend',
      confirmColor: status === 'approved' ? 'success' : 'danger'
    });

  const confirmProductDelete = (productId: string) =>
    setConfirmDialog({
      isOpen: true,
      title: 'Delete Product',
      message: 'Are you sure you want to permanently delete this product? This action cannot be undone.',
      action: () => deleteProduct(productId),
      confirmText: 'Delete',
      confirmColor: 'danger'
    });

  const handleSaveCategory = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!categoryModal.data) return;
    const isEdit = Boolean(categoryModal.data._id);
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
    } catch (err) {
      console.error(err);
    }
  };

  if (!token) {
    return (
      <div className="dashboard-layout" style={{ alignItems: 'center', justifyContent: 'center' }}>
        <div className="card animate-fade-in" style={{ maxWidth: '420px', width: '100%', padding: '40px' }}>
          <div style={{ textAlign: 'center', marginBottom: '32px' }}>
            <div
              style={{
                width: '64px',
                height: '64px',
                borderRadius: '16px',
                overflow: 'hidden',
                display: 'inline-flex',
                alignItems: 'center',
                justifyContent: 'center',
                marginBottom: '16px',
                backgroundColor: 'var(--color-coral)',
                boxShadow: 'var(--shadow-sm)'
              }}
            >
              <img src="/logo.png" alt="LocalTrade Logo" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
            </div>
            <h1 style={{ fontSize: '24px', fontWeight: 'bold' }}>LocalTrade Admin</h1>
            <p style={{ color: 'var(--color-muted)', marginTop: '8px' }}>Log in to manage your platform</p>
          </div>
          <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            {error && (
              <div
                style={{
                  padding: '12px',
                  backgroundColor: 'rgba(211, 47, 47, 0.1)',
                  color: 'var(--color-danger)',
                  borderRadius: '8px',
                  fontSize: '14px'
                }}
              >
                {error}
              </div>
            )}
            <div>
              <label style={{ display: 'block', marginBottom: '8px', fontSize: '14px', fontWeight: '500' }}>
                Email Address
              </label>
              <input
                type="email"
                className="input-field"
                placeholder="admin@localtrade.com"
                value={email}
                onChange={e => setEmail(e.target.value)}
                required
              />
            </div>
            <div>
              <label style={{ display: 'block', marginBottom: '8px', fontSize: '14px', fontWeight: '500' }}>
                Password
              </label>
              <input
                type="password"
                className="input-field"
                placeholder="••••••••"
                value={password}
                onChange={e => setPassword(e.target.value)}
                required
              />
            </div>
            <button
              type="submit"
              className="btn"
              style={{ width: '100%', marginTop: '8px' }}
              disabled={loading}
            >
              {loading ? 'Authenticating...' : 'Sign In'}
            </button>
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
          <div
            style={{
              width: '40px',
              height: '40px',
              borderRadius: '10px',
              overflow: 'hidden',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              backgroundColor: 'var(--color-coral)'
            }}
          >
            <img src="/logo.png" alt="Logo" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
          </div>
          <h2 style={{ margin: 0, fontSize: '20px', fontWeight: 'bold', letterSpacing: '-0.5px', color: 'var(--color-ink)' }}>
            LocalTrade
          </h2>
        </div>

        <nav style={{ display: 'flex', flexDirection: 'column', gap: '8px', flex: 1 }}>
          <NavItem
            icon={<LayoutDashboard size={20} />}
            label="Analytics"
            active={!detailView && activeTab === 'overview'}
            onClick={() => {
              setDetailView(null);
              setActiveTab('overview');
            }}
          />
          <NavItem
            icon={<Users size={20} />}
            label="Users"
            active={!detailView && activeTab === 'users'}
            onClick={() => {
              setDetailView(null);
              setActiveTab('users');
            }}
          />
          <NavItem
            icon={<Store size={20} />}
            label="Vendors"
            active={(!detailView && activeTab === 'vendors') || detailView?.type === 'vendor'}
            onClick={() => {
              setDetailView(null);
              setActiveTab('vendors');
            }}
          />
          <NavItem
            icon={<ShoppingBag size={20} />}
            label="Products"
            active={(!detailView && activeTab === 'products') || detailView?.type === 'product'}
            onClick={() => {
              setDetailView(null);
              setActiveTab('products');
            }}
          />
          <NavItem
            icon={<ListOrdered size={20} />}
            label="Orders"
            active={!detailView && activeTab === 'orders'}
            onClick={() => {
              setDetailView(null);
              setActiveTab('orders');
            }}
          />
          <NavItem
            icon={<Tags size={20} />}
            label="Categories"
            active={!detailView && activeTab === 'categories'}
            onClick={() => {
              setDetailView(null);
              setActiveTab('categories');
            }}
          />
          <NavItem
            icon={<MessageSquare size={20} />}
            label="Feedback"
            active={!detailView && activeTab === 'feedback'}
            onClick={() => {
              setDetailView(null);
              setActiveTab('feedback');
            }}
          />
        </nav>

        <div style={{ marginTop: 'auto', display: 'flex', flexDirection: 'column', gap: '8px' }}>
          <NavItem
            icon={<UserCircle size={20} />}
            label="Profile"
            active={!detailView && activeTab === 'profile'}
            onClick={() => {
              setDetailView(null);
              setActiveTab('profile');
            }}
          />
          <button
            onClick={confirmLogout}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              padding: '12px',
              background: 'none',
              border: 'none',
              color: 'var(--color-muted)',
              cursor: 'pointer',
              fontWeight: '500',
              borderRadius: '8px',
              transition: 'all 0.2s'
            }}
          >
            <LogOut size={20} />
            <span>Log Out</span>
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="dashboard-content">
        {detailView ? (
          <div className="animate-fade-in">
            <button
              onClick={() => setDetailView(null)}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '8px',
                background: 'none',
                border: 'none',
                color: 'var(--color-muted)',
                cursor: 'pointer',
                fontWeight: '500',
                marginBottom: '24px'
              }}
            >
              <ChevronLeft size={20} /> Back to List
            </button>
            {detailView.loading ? (
              <DetailSkeleton />
            ) : detailView.type === 'vendor' ? (
              <VendorDetail data={detailView.data} onStatusChange={confirmVendorStatus} />
            ) : detailView.type === 'product' ? (
              <ProductDetail data={detailView.data} onDelete={confirmProductDelete} />
            ) : detailView.type === 'order' ? (
              <OrderDetail data={detailView.data} />
            ) : null}
          </div>
        ) : (
          <>
            <header
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                marginBottom: '32px',
                position: 'relative',
                zIndex: 9999
              }}
            >
              <div>
                <h1 style={{ fontSize: '32px', marginBottom: '8px' }}>
                  {activeTab === 'overview'
                    ? 'Overview'
                    : activeTab.charAt(0).toUpperCase() + activeTab.slice(1)}
                </h1>
                <p style={{ color: 'var(--color-muted)' }}>
                  Manage your platform's {activeTab === 'overview' ? 'overview' : activeTab} below.
                </p>
              </div>
              <div style={{ display: 'flex', gap: '16px', alignItems: 'center' }}>
                {activeTab !== 'overview' && activeTab !== 'categories' && (
                  <div style={{ position: 'relative', width: '250px' }}>
                    <Search
                      size={18}
                      color="var(--color-muted)"
                      style={{ position: 'absolute', left: '12px', top: '12px' }}
                    />
                    <input
                      type="text"
                      placeholder={`Search ${activeTab}...`}
                      value={searchQuery}
                      onChange={e => setSearchQuery(e.target.value)}
                      className="input-field"
                      style={{
                        paddingLeft: '40px',
                        paddingRight: '30px',
                        width: '100%',
                        backgroundColor: 'white'
                      }}
                    />
                    {searchQuery && (
                      <button
                        onClick={() => setSearchQuery('')}
                        style={{
                          position: 'absolute',
                          right: '12px',
                          top: '50%',
                          transform: 'translateY(-50%)',
                          background: 'none',
                          border: 'none',
                          color: 'var(--color-muted)',
                          cursor: 'pointer',
                          padding: '0',
                          width: '24px',
                          height: '24px',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center'
                        }}
                      >
                        <XCircle size={18} color="var(--color-muted)" />
                      </button>
                    )}
                  </div>
                )}
                <div style={{ position: 'relative' }}>
                  <button
                    onClick={() => {
                      setShowNotifications(!showNotifications);
                      if (!showNotifications) fetchNotifications();
                    }}
                    style={{
                      width: '44px',
                      height: '44px',
                      borderRadius: '12px',
                      border: '1px solid #e5e4e7',
                      background: 'white',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      cursor: 'pointer',
                      position: 'relative'
                    }}
                  >
                    <Bell size={20} color="var(--color-ink)" />
                    {data.notifications?.some(n => !n.isRead) && (
                      <span
                        style={{
                          position: 'absolute',
                          top: 10,
                          right: 12,
                          width: 8,
                          height: 8,
                          backgroundColor: 'var(--color-coral)',
                          borderRadius: '50%'
                        }}
                      />
                    )}
                  </button>
                  {showNotifications && (
                    <div
                      className="card animate-fade-in"
                      style={{
                        position: 'absolute',
                        top: '56px',
                        right: 0,
                        width: '320px',
                        padding: '16px',
                        zIndex: 9999,
                        boxShadow: 'var(--shadow-lg)'
                      }}
                    >
                      <div
                        style={{
                          display: 'flex',
                          justifyContent: 'space-between',
                          alignItems: 'center',
                          marginBottom: '12px'
                        }}
                      >
                        <h4 style={{ margin: 0 }}>Notifications</h4>
                        {data.notifications?.some(n => !n.isRead) && (
                          <button
                            onClick={markAllNotificationsRead}
                            style={{
                              background: 'none',
                              border: 'none',
                              color: 'var(--color-coral)',
                              fontSize: '12px',
                              cursor: 'pointer',
                              fontWeight: '500',
                              display: 'flex',
                              alignItems: 'center',
                              gap: '4px'
                            }}
                          >
                            <CheckCheck size={14} /> Mark all read
                          </button>
                        )}
                      </div>
                      <div
                        style={{
                          display: 'flex',
                          flexDirection: 'column',
                          gap: '8px',
                          maxHeight: '300px',
                          overflowY: 'auto'
                        }}
                      >
                        {data.notifications.length === 0 ? (
                          <p style={{ color: 'var(--color-muted)', fontSize: '14px' }}>No notifications</p>
                        ) : (
                          data.notifications.map(n => (
                            <div
                              key={n._id}
                              onClick={() => !n.isRead && markNotificationRead(n._id)}
                              style={{
                                padding: '12px',
                                backgroundColor: n.isRead ? 'transparent' : 'rgba(255,111,82,0.05)',
                                borderRadius: '8px',
                                border: '1px solid rgba(43,38,32,0.05)',
                                cursor: n.isRead ? 'default' : 'pointer'
                              }}
                            >
                              <h5 style={{ fontSize: '13px', marginBottom: '4px' }}>{n.title}</h5>
                              <p style={{ fontSize: '12px', color: 'var(--color-muted)' }}>{n.message}</p>
                            </div>
                          ))
                        )}
                      </div>
                    </div>
                  )}
                </div>
              </div>
            </header>

            {activeTab === 'overview' && <AnalyticsTab analytics={data.analytics} />}
            {activeTab === 'users' && (
              <UsersTab
                users={data.users}
                filters={filters.users}
                setPage={(p: number) =>
                  setFilters(prev => ({ ...prev, users: { ...prev.users, page: p } }))
                }
                onToggle={confirmUserToggle}
              />
            )}
            {activeTab === 'vendors' && (
              <VendorsTab
                vendors={data.vendors as Vendor[]}
                filters={filters.vendors}
                setPage={(p: number) =>
                  setFilters(prev => ({ ...prev, vendors: { ...prev.vendors, page: p } }))
                }
                onStatusChange={confirmVendorStatus}
                onView={(id: string) => loadDetail('vendor', id)}
              />
            )}
            {activeTab === 'products' && (
              <ProductsTab
                products={data.products}
                stats={data.stats?.products}
                filters={filters.products}
                setPage={(p: number) =>
                  setFilters(prev => ({ ...prev, products: { ...prev.products, page: p } }))
                }
                onDelete={confirmProductDelete}
                onView={(id: string) => loadDetail('product', id)}
              />
            )}
            {activeTab === 'orders' && (
              <OrdersTab
                orders={data.orders}
                filters={filters.orders}
                setPage={(p: number) =>
                  setFilters(prev => ({ ...prev, orders: { ...prev.orders, page: p } }))
                }
                onView={(id: string) => loadDetail('order', id)}
              />
            )}
            {activeTab === 'categories' && (
              <CategoriesTab
                categories={data.categories}
                onAdd={() =>
                  setCategoryModal({
                    isOpen: true,
                    data: { name: '', icon: '📦', isActive: true, sortOrder: 0 }
                  })
                }
                onEdit={(c: Category) => setCategoryModal({ isOpen: true, data: c })}
              />
            )}
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
        onConfirm={() => {
          if (confirmDialog.action) confirmDialog.action();
          setConfirmDialog(prev => ({ ...prev, isOpen: false }));
        }}
        onCancel={() => setConfirmDialog(prev => ({ ...prev, isOpen: false }))}
      />

      {categoryModal.isOpen && (
        <CategoryModal
          category={categoryModal.data || { name: '', icon: '📦', isActive: true, sortOrder: 0 }}
          onChange={(data: Category) => setCategoryModal({ isOpen: true, data })}
          onSave={handleSaveCategory}
          onCancel={() => setCategoryModal({ isOpen: false, data: null })}
        />
      )}
    </div>
  );
}

export default App;
