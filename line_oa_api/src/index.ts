import express from 'express';
import cors from 'cors';
import { env } from './config/env';
import { errorHandler, notFound } from './middleware/error';
import webhookRouter from './routes/webhook';
import ordersRouter from './routes/orders';
import menusRouter from './routes/menus';
import stockRouter from './routes/stock';
import richMenuRouter from './routes/rich_menu';

const app = express();

// ─── Middleware ───────────────────────────────────────────────────────────────

app.use(cors());

// increase body limit for base64 image uploads
app.use('/webhook', express.raw({ type: 'application/json' }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

// ─── Routes ───────────────────────────────────────────────────────────────────

app.get('/health', (_req, res) => res.json({ status: 'ok', ts: new Date().toISOString() }));

// keep-alive for Render free tier (prevents spin-down)
if (process.env.NODE_ENV === 'production' && process.env.RENDER_EXTERNAL_URL) {
  const keepAliveUrl = `${process.env.RENDER_EXTERNAL_URL}/health`;
  setInterval(async () => {
    try {
      await fetch(keepAliveUrl);
      console.table({ step: 'keep-alive', url: keepAliveUrl });
    } catch {
      // ignore
    }
  }, 14 * 60 * 1000); // every 14 minutes
}

app.use('/webhook', webhookRouter);
app.use('/orders', ordersRouter);
app.use('/menus', menusRouter);
app.use('/stock', stockRouter);
app.use('/rich-menu', richMenuRouter);

// ─── Error handling ───────────────────────────────────────────────────────────

app.use(notFound);
app.use(errorHandler);

// ─── Start ────────────────────────────────────────────────────────────────────

app.listen(env.port, () => {
  console.table({
    step: 'server-start',
    port: env.port,
    env: process.env.NODE_ENV ?? 'development',
  });
});

export default app;
