import { Request, Response, NextFunction } from 'express';

export function traceMiddleware(req: Request, res: Response, next: NextFunction): void {
  const start = Date.now();
  const { method, url, body, query } = req;

  // log request
  console.table({
    dir: '→ REQ',
    method,
    url,
    query: Object.keys(query).length ? JSON.stringify(query) : '-',
    body: method !== 'GET' && body && Object.keys(body).length
      ? JSON.stringify(body)
      : '-',
  });

  // intercept response body
  const chunks: Buffer[] = [];
  const originalWrite = res.write.bind(res);
  const originalEnd = res.end.bind(res);

  res.write = (chunk: unknown, ...args: unknown[]): boolean => {
    if (Buffer.isBuffer(chunk)) chunks.push(chunk);
    else if (typeof chunk === 'string') chunks.push(Buffer.from(chunk));
    return (originalWrite as (...a: unknown[]) => boolean)(chunk, ...args);
  };

  res.end = (chunk: unknown, ...args: unknown[]): Response => {
    if (chunk) {
      if (Buffer.isBuffer(chunk)) chunks.push(chunk);
      else if (typeof chunk === 'string') chunks.push(Buffer.from(chunk));
    }

    const responseBody = Buffer.concat(chunks).toString('utf8');
    let parsedBody: unknown = responseBody;
    try { parsedBody = JSON.parse(responseBody); } catch { /* keep as string */ }

    console.table({
      dir: '← RES',
      method,
      url,
      status: res.statusCode,
      ms: Date.now() - start,
      body: JSON.stringify(parsedBody),
    });

    return (originalEnd as (...a: unknown[]) => Response)(chunk, ...args);
  };

  next();
}
