import { Router, Request, Response, NextFunction } from 'express';
import * as line from '@line/bot-sdk';
import { env } from '../config/env';
import * as orderService from '../services/order.service';
import * as menuService from '../services/menu.service';
import * as lineService from '../services/line.service';

const router = Router();

// lazy LINE middleware — created on first request so .env is already loaded
let _lineMiddleware: ReturnType<typeof line.middleware> | null = null;
function getLineMiddleware(): ReturnType<typeof line.middleware> {
  if (!_lineMiddleware) {
    _lineMiddleware = line.middleware({ channelSecret: env.line.channelSecret });
  }
  return _lineMiddleware;
}

function lazyLineMiddleware(req: Request, res: Response, next: NextFunction): void {
  getLineMiddleware()(req, res, next);
}

router.post('/', lazyLineMiddleware, async (req: Request, res: Response): Promise<void> => {
  const events: line.WebhookEvent[] = req.body.events;

  await Promise.all(events.map((event) => handleEvent(event)));
  res.json({ status: 'ok' });
});

async function handleEvent(event: line.WebhookEvent): Promise<void> {
  console.table({
    step: 'webhook-event',
    type: event.type,
    source: event.source.type,
  });

  if (event.type !== 'message' || event.message.type !== 'text') return;

  const userId = event.source.userId ?? '';
  const text = event.message.text.trim();
  const merchantId = 'merchant-001'; // TODO: resolve from userId mapping

  await handleTextMessage(userId, text, merchantId);
}

async function handleTextMessage(
  userId: string,
  text: string,
  merchantId: string
): Promise<void> {
  const accessToken = env.line.channelAccessToken;

  // ── ดูเมนู ────────────────────────────────────────────────────────────────
  if (text === 'เมนู' || text === 'menu') {
    const menus = menuService.getMenusByMerchant(merchantId).filter((m) => m.isAvailable);
    for (const menu of menus.slice(0, 5)) {
      await lineService.pushMenuCard(accessToken, userId, menu);
    }
    return;
  }

  // ── สั่งอาหาร ─────────────────────────────────────────────────────────────
  if (text.startsWith('สั่ง ')) {
    const menuName = text.slice(3).trim();
    const menus = menuService.getMenusByMerchant(merchantId);
    const menu = menus.find((m) => m.name === menuName);

    if (!menu) {
      await pushText(accessToken, userId, `ไม่พบเมนู "${menuName}" กรุณาพิมพ์ "เมนู" เพื่อดูรายการ`);
      return;
    }

    if (!menu.isAvailable) {
      await pushText(accessToken, userId, `ขออภัย "${menuName}" หมดชั่วคราว`);
      return;
    }

    const order = orderService.createOrder(merchantId, userId, 'ลูกค้า LINE', [
      { menuId: menu.id, menuName: menu.name, quantity: 1, unitPrice: menu.price, spiceLevel: 2, customNote: null },
    ]);

    await lineService.pushOrderConfirmation(accessToken, userId, order);
    return;
  }

  // ── ดูสถานะ ───────────────────────────────────────────────────────────────
  if (text.startsWith('สถานะ #')) {
    const orderId = text.slice(5).trim();
    const orders = orderService.getOrdersByMerchant(merchantId);
    const order = orders.find((o) => o.id.endsWith(orderId));

    if (!order) {
      await pushText(accessToken, userId, `ไม่พบออเดอร์ #${orderId}`);
      return;
    }

    await lineService.pushOrderStatus(accessToken, userId, order);
    return;
  }

  // ── ดูตะกร้า ─────────────────────────────────────────────────────────────
  if (text === 'ดูตะกร้า') {
    const orders = orderService.getOrdersByMerchant(merchantId).filter(
      (o) => o.customerId === userId && ['pending', 'confirmed', 'preparing'].includes(o.status)
    );

    if (orders.length === 0) {
      await pushText(accessToken, userId, 'ไม่มีออเดอร์ที่กำลังดำเนินการ');
      return;
    }

    for (const order of orders) {
      await lineService.pushOrderStatus(accessToken, userId, order);
    }
    return;
  }

  // ── default ───────────────────────────────────────────────────────────────
  await pushText(accessToken, userId, 'พิมพ์ "เมนู" เพื่อดูรายการอาหาร หรือ "สั่ง [ชื่อเมนู]" เพื่อสั่งอาหาร');
}

async function pushText(accessToken: string, userId: string, text: string): Promise<void> {
  const client = new line.messagingApi.MessagingApiClient({ channelAccessToken: accessToken });
  await client.pushMessage({ to: userId, messages: [{ type: 'text', text }] });
}

export default router;
