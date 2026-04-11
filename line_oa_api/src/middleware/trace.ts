import { Request, Response, NextFunction } from 'express';

export function traceMiddleware(req: Request, res: Response, next: NextFunction): void {
  const start = Date.now();
  const { method, url, body, query } = req;

  res.on('finish', () => {
    console.table({
      method,
      url,
      status: res.statusCode,
      ms: Date.now() - start,
      query: Object.keys(query).length ? JSON.stringify(query) : '-',
      body: method !== 'GET' && body && Object.keys(body).length
        ? JSON.stringify(body).slice(0, 120)
        : '-',
    });
  });

  next();
}
