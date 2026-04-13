import jwt from 'jsonwebtoken';
import { env } from './config/env';
import type { JwtPayload } from './types';

export function signToken(payload: JwtPayload): string {
  return jwt.sign(payload, env.jwtSecret, { expiresIn: '7d' });
}

export function verifyToken(token: string): JwtPayload | null {
  try {
    return jwt.verify(token, env.jwtSecret) as JwtPayload;
  } catch {
    return null;
  }
}

export function getTokenFromRequest(req: Request): string | null {
  const auth = req.headers.get('authorization');
  if (auth?.startsWith('Bearer ')) return auth.slice(7);
  const cookie = req.headers.get('cookie');
  if (cookie) {
    const match = /(?:^|;\s*)token=([^;]+)/.exec(cookie);
    if (match) return match[1];
  }
  return null;
}
