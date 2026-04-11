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

// ─── Middleware ───────────────────────────────────────────────────────────────

app.use(cors());
app.use(traceMiddleware);
app.use('/images', express.static('public/images'));
app.use('/images/menus', express.static('public/images/menus'));

app.use('/webhook', express.raw({ type: 'application/json' }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// ─── Routes ───────────────────────────────────────────────────────────────────

app.get('/health', (_req, res) => res.json({ status: 'ok', ts: new Date().toISOString() }));

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
