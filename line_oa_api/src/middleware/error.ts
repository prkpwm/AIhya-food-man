import { Request, Response, NextFunction } from 'express';
import { ErrorResponse } from '../types';

export function errorHandler(
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
): void {
  console.table({ step: 'error-handler', message: err.message, stack: err.stack });

  // extract meaningful message from LINE API errors
  const message = (err as { originalError?: { message?: string } }).originalError?.message
    ?? err.message
    ?? 'Internal server error';

  const body: ErrorResponse = {
    code: '500',
    en: message,
    th: 'เกิดข้อผิดพลาดภายในเซิร์ฟเวอร์',
  };

  res.status(500).json(body);
}

export function notFound(_req: Request, res: Response): void {
  const body: ErrorResponse = {
    code: '404',
    en: 'Route not found',
    th: 'ไม่พบเส้นทางที่ร้องขอ',
  };
  res.status(404).json(body);
}
