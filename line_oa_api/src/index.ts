import express from 'express';
import cors from 'cors';
import { env } from './config/env';
import { errorHandler, notFound } from './middleware/error';
import { traceMiddleware } from './middleware/trace';
import webhookRouter from './routes/webhook';
import ordersRouter from './routes/orders';
import menusRouter from './routes/menus';
import stockRouter from './routes/stock';
import richMenuRouter from './routes/rich_menu';
import broadcastRouter from './routes/broadcast';
import orderWebRouter from './routes/order_web';
import paymentRouter from './routes/payment';
import { seedData } from './data/seed';

const app = express();

// ─── In-memory log store ──────────────────────────────────────────────────────

interface LogEntry {
  ts: string;
  dir: string;
  method: string;
  url: string;
  status?: number;
  ms?: number;
  query?: string;
  body?: string;
}

const logs: LogEntry[] = [];
const MAX_LOGS = 500;

export function pushLog(entry: LogEntry): void {
  logs.unshift(entry);
  if (logs.length > MAX_LOGS) logs.pop();
}


// ─── Middleware ───────────────────────────────────────────────────────────────

// ─── CORS (manual headers to guarantee browser compliance) ───────────────────
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,PATCH,DELETE,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type,Authorization,X-Requested-With');
  if (req.method === 'OPTIONS') {
    res.sendStatus(204);
    return;
  }
  next();
});
app.use(traceMiddleware);
app.use('/images', express.static('public/images'));
app.use('/images/menus', express.static('public/images/menus'));

app.use('/webhook', express.raw({ type: 'application/json' }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// ─── Routes ───────────────────────────────────────────────────────────────────

app.get('/health', (_req, res) => res.json({ status: 'ok', ts: new Date().toISOString() }));

app.get('/logs', (_req, res) => res.json({ count: logs.length, logs }));

if (process.env.NODE_ENV === 'production' && process.env.RENDER_EXTERNAL_URL) {
  const keepAliveUrl = `${process.env.RENDER_EXTERNAL_URL}/health`;
  setInterval(async () => {
    try { await fetch(keepAliveUrl); } catch { /* ignore */ }
  }, 14 * 60 * 1000);
}

app.use('/webhook', webhookRouter);
app.use('/orders', ordersRouter);
app.use('/menus', menusRouter);
app.use('/stock', stockRouter);
app.use('/rich-menu', richMenuRouter);
app.use('/broadcast', broadcastRouter);
app.use('/order-web', orderWebRouter);
app.use('/payment', paymentRouter);

// ─── Error handling ───────────────────────────────────────────────────────────

app.use(notFound);
app.use(errorHandler);

// ─── Start ────────────────────────────────────────────────────────────────────

app.listen(env.port, () => {
  seedData();
});

export default app;
