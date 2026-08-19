import { Request, Response, NextFunction } from 'express';
import { Document, Types } from 'mongoose';

// ==========================================
// Enums & Literal Types
// ==========================================

export type UserRole = 'customer' | 'vendor' | 'admin';

export type VendorApprovalStatus = 'pending' | 'approved' | 'rejected' | 'suspended';

export type PriceUnit = 'piece' | 'kg' | '100g' | 'liter' | 'dozen' | 'packet' | 'bundle';

export type ProductStatus = 'Available' | 'OutOfStock' | 'Inactive';

export type OrderStatus =
  | 'Pending'
  | 'Confirmed'
  | 'Processing'
  | 'Shipped'
  | 'Delivered'
  | 'Cancelled';

export type NotificationType = 'Order' | 'System' | 'Account' | 'Promotional';

// ==========================================
// Address Interfaces
// ==========================================

export interface IAddress {
  fullName?: string;
  phone?: string;
  street?: string;
  landmark?: string;
  city?: string;
  state?: string;
  zipCode?: string;
}

export interface IShippingAddress {
  fullName: string;
  phone: string;
  street?: string;
  landmark?: string;
  city: string;
  state: string;
  zipCode: string;
}

// ==========================================
// User Domain & Document Interfaces
// ==========================================

export interface IUser {
  fullName: string;
  email: string;
  phone: string;
  password?: string;
  address?: IAddress | null;
  shopName?: string;
  businessDescription?: string;
  openingHours?: string;
  categories?: string[];
  profileImage?: string;
  role: UserRole;
  vendorApprovalStatus: VendorApprovalStatus;
  isActive: boolean;
  fcmToken?: string;
  mustChangePassword?: boolean;
  passwordChangedAt?: Date;
  passwordResetOtp?: string;
  passwordResetOtpExpires?: Date;
  passwordResetTempToken?: string;
  passwordResetTempTokenExpires?: Date;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface IUserDoc extends IUser, Document<Types.ObjectId> {
  _id: Types.ObjectId;
  comparePassword(candidatePassword: string, userPassword?: string): Promise<boolean>;
}

// ==========================================
// Product Domain & Document Interfaces
// ==========================================

export interface IProduct {
  title: string;
  description: string;
  category: string;
  price: number;
  originalPrice?: number | null;
  priceUnit: PriceUnit;
  minOrder: number;
  images: string[];
  vendorId: Types.ObjectId | IUserDoc | string;
  stockQuantity: number;
  productStatus: ProductStatus;
  sizes?: string[];
  vendorName?: string;
  location?: string;
  ratingsAverage?: number;
  ratingsQuantity?: number;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface IProductDoc extends IProduct, Document<Types.ObjectId> {
  _id: Types.ObjectId;
  stock?: number;
  isAvailable?: boolean;
}

// ==========================================
// Order Domain & Document Interfaces
// ==========================================

export interface IOrderItem {
  product: Types.ObjectId | IProductDoc | string;
  quantity: number;
  price: number;
  priceUnit?: PriceUnit | string;
  size?: string | null;
}

export interface IOrder {
  customerId: Types.ObjectId | IUserDoc | string;
  vendorId: Types.ObjectId | IUserDoc | string;
  products: IOrderItem[];
  totalAmount: number;
  orderStatus: OrderStatus;
  shippingAddress: IShippingAddress;
  notes?: string;
  cancellationReason?: string;
  cancellationFeedback?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface IOrderDoc extends IOrder, Document<Types.ObjectId> {
  _id: Types.ObjectId;
}

// ==========================================
// Category Domain & Document Interfaces
// ==========================================

export interface ICategory {
  name: string;
  icon?: string;
  sortOrder?: number;
  isActive?: boolean;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface ICategoryDoc extends ICategory, Document<Types.ObjectId> {
  _id: Types.ObjectId;
}

// ==========================================
// Review Domain & Document Interfaces
// ==========================================

export interface IVendorReply {
  text: string;
  repliedAt?: Date;
}

export interface IReview {
  reviewText: string;
  rating: number;
  createdAt?: Date;
  productId: Types.ObjectId | IProductDoc | string;
  userId: Types.ObjectId | IUserDoc | string;
  vendorReply?: IVendorReply;
}

export interface IReviewDoc extends IReview, Document<Types.ObjectId> {
  _id: Types.ObjectId;
}

// ==========================================
// Notification Domain & Document Interfaces
// ==========================================

export interface INotification {
  recipient: Types.ObjectId | IUserDoc | string;
  title: string;
  message: string;
  data?: Map<string, string> | Record<string, string>;
  isRead?: boolean;
  type?: NotificationType;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface INotificationDoc extends INotification, Document<Types.ObjectId> {
  _id: Types.ObjectId;
}

// ==========================================
// Feedback Domain & Document Interfaces
// ==========================================

export interface IFeedback {
  userId: Types.ObjectId | IUserDoc | string;
  role: UserRole;
  rating: number;
  usabilityRating: number;
  designRating: number;
  performanceRating: number;
  featureCompletenessRating: number;
  comment: string;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface IFeedbackDoc extends IFeedback, Document<Types.ObjectId> {
  _id: Types.ObjectId;
}

// ==========================================
// Express / Middleware Interfaces
// ==========================================

export interface AuthRequest<
  P = any,
  ResBody = any,
  ReqBody = any,
  ReqQuery = any,
  Locals extends Record<string, any> = Record<string, any>
> extends Request<P, ResBody, ReqBody, ReqQuery, Locals> {
  user?: IUserDoc | any;
  file?: Express.Multer.File;
  files?: Express.Multer.File[] | { [fieldname: string]: Express.Multer.File[] };
}

export type AsyncRequestHandler = (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => Promise<any>;
