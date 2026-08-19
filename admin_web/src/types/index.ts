export interface Address {
  fullName?: string;
  phone?: string;
  street?: string;
  landmark?: string;
  city?: string;
  state?: string;
  zipCode?: string;
}

export type UserRole = 'admin' | 'vendor' | 'customer';
export type VendorApprovalStatus = 'pending' | 'approved' | 'suspended';

export interface User {
  _id: string;
  fullName: string;
  email: string;
  phone?: string;
  role: UserRole | string;
  isActive: boolean;
  mustChangePassword?: boolean;
  vendorApprovalStatus?: VendorApprovalStatus | string;
  shopName?: string;
  businessDescription?: string;
  openingHours?: string;
  categories?: string[];
  profileImage?: string;
  address?: Address | null;
  productCount?: number;
  fcmToken?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface Vendor extends User {
  role: 'vendor';
  vendorApprovalStatus: VendorApprovalStatus | string;
}

export type PriceUnit = 'piece' | 'kg' | '100g' | 'liter' | 'dozen' | 'packet' | 'bundle' | string;
export type ProductStatus = 'Available' | 'OutOfStock' | 'Inactive' | string;

export interface Product {
  _id: string;
  title: string;
  description?: string;
  category: string;
  price: number;
  originalPrice?: number;
  priceUnit?: PriceUnit;
  minOrder?: number;
  images: string[];
  vendorId?: string | User | Vendor;
  vendorName?: string;
  location?: string | Address;
  stockQuantity: number;
  productStatus?: ProductStatus;
  ratingsAverage?: number;
  ratingsQuantity?: number;
  createdAt?: string;
  updatedAt?: string;
}

export interface OrderItem {
  product?: string | Product;
  quantity: number;
  price: number;
  priceUnit?: PriceUnit;
}

export type OrderStatus = 'Pending' | 'Confirmed' | 'Processing' | 'Shipped' | 'Delivered' | 'Cancelled' | string;

export interface Order {
  _id: string;
  customerId?: User | { _id?: string; fullName?: string; email?: string; phone?: string };
  vendorId?: User | Vendor | { _id?: string; fullName?: string; shopName?: string; email?: string; phone?: string };
  products: OrderItem[];
  totalAmount: number;
  orderStatus: OrderStatus;
  shippingAddress?: Address;
  notes?: string;
  cancellationReason?: string;
  cancellationFeedback?: string;
  createdAt: string;
  updatedAt?: string;
}

export interface Category {
  _id?: string;
  name: string;
  icon: string;
  sortOrder: number;
  isActive: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export type NotificationType = 'Account' | 'Order' | 'System' | 'Promotional' | string;

export interface NotificationItem {
  _id: string;
  recipient?: string | User;
  title: string;
  message: string;
  data?: Record<string, string>;
  isRead: boolean;
  type?: NotificationType;
  createdAt?: string;
  updatedAt?: string;
}

export type Notification = NotificationItem;

export interface FeedbackItem {
  _id: string;
  userId?: User | { _id?: string; fullName?: string; email?: string };
  rating: number;
  comment: string;
  createdAt: string;
  updatedAt?: string;
}

export type Feedback = FeedbackItem;

export interface AnalyticsStats {
  totalRevenue?: number;
  totalOrders?: number;
  totalCustomers?: number;
  totalVendors?: number;
  completedOrders?: number;
  pendingVendors?: number;
  totalProducts?: number;
  suspendedVendors?: number;
}

export interface DailyStat {
  _id: string;
  revenue: number;
  count: number;
}

export interface UserDailyStat {
  _id: string;
  count: number;
}

export interface RevenueByCategory {
  _id: string;
  revenue: number;
}

export interface AnalyticsData {
  stats?: AnalyticsStats;
  dailyStats?: DailyStat[];
  userDailyStats?: UserDailyStat[];
  revenueByCategory?: RevenueByCategory[];
  recentOrders?: Order[];
}

export interface TabPaginationFilter {
  page: number;
  limit: number;
  role?: string;
  status?: string;
}

export interface TabFilters {
  users: TabPaginationFilter;
  vendors: TabPaginationFilter;
  products: TabPaginationFilter;
  orders: TabPaginationFilter;
}

export type TabType = 'overview' | 'users' | 'vendors' | 'products' | 'orders' | 'categories' | 'feedback' | 'profile';

export type DetailViewType = 'vendor' | 'product' | 'order';

export interface DetailViewState {
  type: DetailViewType;
  id: string;
  data: any;
  loading: boolean;
}

export interface ConfirmDialogState {
  isOpen: boolean;
  title?: string;
  message?: string;
  action?: (() => void) | (() => Promise<void>);
  confirmText?: string;
  confirmColor?: 'danger' | 'success' | 'ink' | 'coral' | 'warning';
}

export interface CategoryModalState {
  isOpen: boolean;
  data: Category | null;
}

export interface VendorDetailData {
  vendor: Vendor;
  stats: {
    totalProducts?: number;
    totalOrders?: number;
    deliveredOrders?: number;
    totalRevenue?: number;
  };
  products: Product[];
  recentOrders: Order[];
}

export interface ProductDetailData {
  product: Product;
}

export interface AppData {
  analytics: AnalyticsData | null;
  users: User[];
  vendors: Vendor[];
  products: Product[];
  orders: Order[];
  categories: Category[];
  feedback: FeedbackItem[];
  profile: User | { user: User } | null;
  notifications: NotificationItem[];
  stats?: {
    products?: {
      totalProducts?: number;
      availableProducts?: number;
    };
    [key: string]: any;
  };
}
