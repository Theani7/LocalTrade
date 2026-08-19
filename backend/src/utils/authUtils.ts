import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { Response } from 'express';
import { IUserDoc } from '../types';

export const signToken = (id: string | any): string => {
  return jwt.sign({ id }, process.env.JWT_SECRET as string, {
    expiresIn: (process.env.JWT_EXPIRES_IN || '30d') as any,
  });
};

export const sendToken = (user: IUserDoc | any, statusCode: number, res: Response): void => {
  const token = signToken(user._id);
  const userObj = typeof user.toObject === 'function' ? user.toObject() : { ...user };
  delete userObj.password;

  res.status(statusCode).json({
    success: true,
    status: 'success',
    token,
    data: { user: userObj },
  });
};

export interface OtpResult {
  otp: string;
  hashedOtp: string;
  expires: number;
}

export const generateOtp = (): OtpResult => {
  const otp = crypto.randomInt(100000, 1000000).toString();
  const hashedOtp = crypto.createHash('sha256').update(otp).digest('hex');
  const expires = Date.now() + 10 * 60 * 1000; // 10 minutes
  return { otp, hashedOtp, expires };
};

export interface TempResetTokenResult {
  raw: string;
  hashed: string;
  expires: number;
}

export const createTempResetToken = (): TempResetTokenResult => {
  const raw = crypto.randomBytes(32).toString('hex');
  const hashed = crypto.createHash('sha256').update(raw).digest('hex');
  const expires = Date.now() + 5 * 60 * 1000; // 5 minutes
  return { raw, hashed, expires };
};

export default { signToken, sendToken, generateOtp, createTempResetToken };
