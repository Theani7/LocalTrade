import { Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import User from '../models/userModel';
import catchAsync from '../utils/catchAsync';
import AppError from '../utils/appError';
import { AuthRequest, UserRole } from '../types';

export const protect = catchAsync(async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
  // 1) Getting token and check if it's there
  let token: string | undefined;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  if (!token) {
    return next(new AppError('You are not logged in! Please log in to get access.', 401));
  }

  // 2) Verification token
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET as string) as { id: string; iat: number };
    
    // 3) Check if user still exists
    const currentUser = await User.findById(decoded.id);

    if (!currentUser) {
      return next(new AppError('The user belonging to this token no longer exists.', 401));
    }

    if (!currentUser.isActive) {
      return next(new AppError('Your account has been deactivated. Please contact support.', 401));
    }

    // 4) Check if password was changed after token was issued
    if (
      currentUser.passwordChangedAt &&
      decoded.iat < Math.floor(currentUser.passwordChangedAt.getTime() / 1000)
    ) {
      return next(new AppError('Password was recently changed. Please log in again.', 401));
    }

    // GRANT ACCESS TO PROTECTED ROUTE
    req.user = currentUser;
    next();
  } catch (err) {
    return next(new AppError('Invalid token. Please log in again.', 401));
  }
});

export const restrictTo = (...roles: (UserRole | string)[]) => {
  return (req: AuthRequest, res: Response, next: NextFunction): void => {
    if (!req.user || !roles.includes(req.user.role)) {
      return next(new AppError('You do not have permission to perform this action', 403));
    }

    next();
  };
};

// @desc    Check if vendor is approved
export const isApprovedVendor = (req: AuthRequest, res: Response, next: NextFunction): void => {
  if (req.user && req.user.role === 'vendor' && req.user.vendorApprovalStatus !== 'approved') {
    return next(
      new AppError(
        `Your vendor account is ${req.user.vendorApprovalStatus}. Please contact admin.`,
        403
      )
    );
  }
  next();
};

export default {
  protect,
  restrictTo,
  isApprovedVendor,
};
