import { Response, NextFunction } from 'express';
import { AuthRequest } from '../types';

type AsyncFunction = (req: AuthRequest, res: Response, next: NextFunction) => Promise<any>;

const catchAsync = (fn: AsyncFunction) => {
  return (req: AuthRequest, res: Response, next: NextFunction): void => {
    if (typeof next !== 'function') {
      console.error('CRITICAL: next is not a function in catchAsync wrapper!');
      console.error('req.method:', req.method);
      console.error('req.url:', req.url);
    }
    fn(req, res, next).catch(next);
  };
};

export = catchAsync;
