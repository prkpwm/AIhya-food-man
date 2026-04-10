import { Request, Response, NextFunction } from 'express';
import { env } from '../config/env';

// simple Bearer token check (replace with JWT verify in production)
export function authMiddleware(req: Request, res: Response, next: NextFunction): void {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    res.status(401).json({ code: '401', en: 'Unauthorized', th: 'ไม่ได้รับอนุญาต' });
    return;
  }

  const token = header.slice(7);
  // TODO: verify JWT with env.jwtSecret
  if (!token) {
    res.status(401).json({ code: '401', en: 'Invalid token', th: 'Token ไม่ถูกต้อง' });
    return;
  }

  next();
}
