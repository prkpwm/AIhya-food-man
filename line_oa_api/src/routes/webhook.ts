import { Router, Request, Response, NextFunction } from 'express';
import * as line from '@line/bot-sdk';
import { env } from '../config/env';
import * as orderService from '../services/order.service';
import * as menuService from '../services/menu.service';
import * as lineService from '../services/line.service';

const router = Router();

function getClient(): line.messagingApi.MessagingApiClient {
  return new line.messagingApi.MessagingApiClient({ channelAccessToken: env.line.channelAccessToken });
}

// lazy LINE signature middleware
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
  await Promise.all(events.map(handleEvent));
  res.json({ status: 'ok' });
});

// ─── Event handler ────────────────────────────────────────────────────────────

async function handleEvent(event: line.WebhookEvent): Promise<void> {
  console.table({ step: 'webhook-event', type: event.type, source: event.source.type });

  if (event.type !== 'message' || event.message.type !== 'text') return;

  const replyToken = event.replyToken;
  const userId = event.source.userId ?? '';
  const text = event.message.text.trim();
  const merchantId = 'merchant-001';

  console.table({ step: 'webhook-text', text, userId: userId.slice(0, 8) });

  await handleTextMessage(replyToken, userId, text, merchantId);
}

// ─── Text message router ──────────────────────────────────────────────────────

async function handleTextMessage(
  replyToken: string,
  userId: string,
  text: string,
  merchantId: string
): Promise<void> {
  // ── เมนู ──────────────────────────────────────────────────────────────────
  if (text === 'เมนู' || text === 'menu') {
    const menus = menuService.getMenusByMerchant(merchantId).filter((m) => m.isAvailable);
    if (menus.length === 0) {
      await reply(replyToken, [{ type: 'text', text: 'ขณะนี้ยังไม่มีเมนูที่พร้อมให้บริการ' }]);
      return;
    }
    // reply supports up to 5 messages
    const msgs = menus.slice(0, 5).map((menu) => buildMenuFlex(menu));
    await reply(replyToken, msgs);
    return;
  }

  // ── สั่ง [ชื่อเมนู] ───────────────────────────────────────────────────────
  if (text.startsWith('สั่ง ')) {
    const menuName = text.slice(3).trim();
    const menus = menuService.getMenusByMerchant(merchantId);
    const menu = menus.find((m) => m.name === menuName);

    if (!menu) {
      await reply(replyToken, [{ type: 'text', text: `ไม่พบเมนู "${menuName}"\nพิมพ์ "เมนู" เพื่อดูรายการ` }]);
      return;
    }
    if (!menu.isAvailable) {
      await reply(replyToken, [{ type: 'text', text: `ขออภัย "${menuName}" หมดชั่วคราว` }]);
      return;
    }

    const order = orderService.createOrder(merchantId, userId, 'ลูกค้า LINE', [
      { menuId: menu.id, menuName: menu.name, quantity: 1, unitPrice: menu.price, spiceLevel: 2, customNote: null },
    ]);

    await reply(replyToken, [buildOrderConfirmFlex(order)]);
    return;
  }

  // ── ดูตะกร้า ─────────────────────────────────────────────────────────────
  if (text === 'ดูตะกร้า' || text === 'ออเดอร์ของฉัน') {
    const orders = orderService.getOrdersByMerchant(merchantId).filter(
      (o) => o.customerId === userId && ['pending', 'confirmed', 'preparing', 'ready'].includes(o.status)
    );
    if (orders.length === 0) {
      await reply(replyToken, [{ type: 'text', text: 'ไม่มีออเดอร์ที่กำลังดำเนินการ' }]);
      return;
    }
    await reply(replyToken, orders.slice(0, 5).map(buildOrderStatusFlex));
    return;
  }

  // ── สถานะ #xxx ────────────────────────────────────────────────────────────
  if (text.startsWith('สถานะ #')) {
    const shortId = text.slice(5).trim();
    const order = orderService.getOrdersByMerchant(merchantId).find((o) => o.id.endsWith(shortId));
    if (!order) {
      await reply(replyToken, [{ type: 'text', text: `ไม่พบออเดอร์ #${shortId}` }]);
      return;
    }
    await reply(replyToken, [buildOrderStatusFlex(order)]);
    return;
  }

  // ── โปรโมชั่น ─────────────────────────────────────────────────────────────
  if (text === 'โปรโมชั่น') {
    await reply(replyToken, [{
      type: 'text',
      text: '🎉 โปรโมชั่นพิเศษ!\n• สั่ง 2 จาน ลด 10%\n• สั่งครบ 200 บาท ฟรีน้ำ 1 แก้ว\n\nพิมพ์ "เมนู" เพื่อดูรายการอาหาร',
    }]);
    return;
  }

  // ── default ───────────────────────────────────────────────────────────────
  await reply(replyToken, [{
    type: 'text',
    text: '🍽️ สวัสดีครับ!\n\nพิมพ์คำสั่งได้เลย:\n• "เมนู" — ดูรายการอาหาร\n• "สั่ง [ชื่อเมนู]" — สั่งอาหาร\n• "ดูตะกร้า" — ดูออเดอร์ของฉัน\n• "โปรโมชั่น" — ดูโปรโมชั่น',
  }]);
}

// ─── Reply helper ─────────────────────────────────────────────────────────────

type LineMessage = Parameters<line.messagingApi.MessagingApiClient['replyMessage']>[0]['messages'][number];

async function reply(replyToken: string, messages: LineMessage[]): Promise<void> {
  const client = getClient();
  await client.replyMessage({ replyToken, messages });
}

// ─── Flex builders ────────────────────────────────────────────────────────────

function buildMenuFlex(menu: ReturnType<typeof menuService.getMenusByMerchant>[number]): LineMessage {
  return {
    type: 'flex',
    altText: menu.name,
    contents: {
      type: 'bubble',
      ...(menu.imageUrl ? { hero: { type: 'image', url: menu.imageUrl, size: 'full', aspectRatio: '20:13', aspectMode: 'cover' } } : {}),
      body: {
        type: 'box', layout: 'vertical', spacing: 'md',
        contents: [
          { type: 'text', text: menu.name, weight: 'bold', size: 'xl' },
          { type: 'text', text: `฿${menu.price.toFixed(0)}`, color: '#FF6B00', size: 'lg', weight: 'bold' },
          { type: 'text', text: menu.description, size: 'sm', color: '#999999', wrap: true },
          ...(!menu.isAvailable ? [{ type: 'text' as const, text: '⚠️ หมดชั่วคราว', size: 'sm' as const, color: '#F44336' }] : []),
        ],
      },
      footer: {
        type: 'box', layout: 'vertical', spacing: 'sm',
        contents: [
          { type: 'button', style: 'primary', color: '#FF6B00', action: { type: 'message', label: 'สั่งเลย', text: `สั่ง ${menu.name}` } },
          { type: 'button', style: 'secondary', action: { type: 'message', label: 'ดูเมนูทั้งหมด', text: 'เมนู' } },
        ],
      },
    },
  } as unknown as LineMessage;
}

function buildOrderConfirmFlex(order: ReturnType<typeof orderService.createOrder>): LineMessage {
  const itemRows = order.items.map((item) => ({
    type: 'box' as const, layout: 'baseline' as const,
    contents: [
      { type: 'text' as const, text: `${item.menuName} ×${item.quantity}`, size: 'sm' as const, color: '#555555', flex: 4 },
      { type: 'text' as const, text: `฿${(item.unitPrice * item.quantity).toFixed(0)}`, align: 'end' as const, size: 'sm' as const, flex: 2 },
    ],
  }));

  return {
    type: 'flex',
    altText: `ยืนยันออเดอร์ #${order.id.slice(-6)}`,
    contents: {
      type: 'bubble',
      body: {
        type: 'box', layout: 'vertical', spacing: 'md',
        contents: [
          { type: 'text', text: '✅ ยืนยันออเดอร์', weight: 'bold', size: 'xl' },
          { type: 'text', text: `#${order.id.slice(-6)}`, size: 'sm', color: '#999999' },
          { type: 'separator' },
          { type: 'box', layout: 'vertical', margin: 'sm', contents: itemRows },
          { type: 'separator', margin: 'sm' },
          {
            type: 'box', layout: 'baseline',
            contents: [
              { type: 'text', text: 'ยอดรวม', size: 'sm', color: '#555555', flex: 4 },
              { type: 'text', text: `฿${order.totalPrice.toFixed(0)}`, align: 'end', size: 'sm', weight: 'bold', flex: 2 },
            ],
          },
          ...(order.estimatedWaitMinutes > 0
            ? [{ type: 'text' as const, text: `⏱ รอประมาณ ${order.estimatedWaitMinutes} นาที`, size: 'sm' as const, color: '#999999' }]
            : []),
        ],
      },
      footer: {
        type: 'box', layout: 'vertical', spacing: 'sm',
        contents: [
          { type: 'button', style: 'primary', color: '#FF6B00', action: { type: 'message', label: 'ติดตามออเดอร์', text: `สถานะ #${order.id.slice(-6)}` } },
          { type: 'button', style: 'secondary', action: { type: 'message', label: 'ดูตะกร้า', text: 'ดูตะกร้า' } },
        ],
      },
    },
  } as unknown as LineMessage;
}

function buildOrderStatusFlex(order: ReturnType<typeof orderService.getOrdersByMerchant>[number]): LineMessage {
  const statusLabel: Record<string, string> = {
    pending: '🕐 รอยืนยัน', confirmed: '✅ ยืนยันแล้ว',
    preparing: '👨‍🍳 กำลังทำ', ready: '🛵 พร้อมส่ง',
    completed: '✅ เสร็จสิ้น', cancelled: '❌ ยกเลิก',
  };

  return {
    type: 'flex',
    altText: `สถานะ #${order.id.slice(-6)}`,
    contents: {
      type: 'bubble',
      body: {
        type: 'box', layout: 'vertical', spacing: 'md',
        contents: [
          { type: 'text', text: 'สถานะออเดอร์', weight: 'bold', size: 'lg' },
          { type: 'text', text: `#${order.id.slice(-6)}`, size: 'sm', color: '#999999' },
          { type: 'separator' },
          { type: 'text', text: statusLabel[order.status] ?? order.status, size: 'xl', weight: 'bold' },
          ...(order.estimatedWaitMinutes > 0
            ? [{ type: 'text' as const, text: `⏱ รออีก ~${order.estimatedWaitMinutes} นาที`, size: 'sm' as const, color: '#999999' }]
            : []),
          { type: 'text', text: `ยอดรวม ฿${order.totalPrice.toFixed(0)}`, size: 'sm', color: '#555555' },
        ],
      },
    },
  } as unknown as LineMessage;
}

export default router;
