import { NextRequest, NextResponse } from 'next/server';
import * as line from '@line/bot-sdk';
import { env } from '@/lib/config/env';
import * as orderService from '@/lib/services/order.service';
import * as menuService from '@/lib/services/menu.service';
import * as cartService from '@/lib/services/cart.service';
import * as lineService from '@/lib/services/line.service';
import { fuzzyFind } from '@/lib/utils/fuzzy';
import { ensureInit } from '@/lib/init';

ensureInit();

type LineMessage = Parameters<line.messagingApi.MessagingApiClient['replyMessage']>[0]['messages'][number];
type WebhookEvent = line.webhook.Event;

const MERCHANT_ID = 'merchant-001';

async function replyMsg(replyToken: string, messages: LineMessage[]) {
  await lineService.replyMessage(env.line.channelAccessToken, replyToken, messages);
}

export async function POST(req: NextRequest) {
  // verify signature
  const sig = req.headers.get('x-line-signature') ?? '';
  const body = await req.text();
  if (!line.validateSignature(body, env.line.channelSecret, sig)) {
    return NextResponse.json({ error: 'invalid signature' }, { status: 401 });
  }

  const { events } = JSON.parse(body) as { events: WebhookEvent[] };
  await Promise.all(events.map(handleEvent));
  return NextResponse.json({ status: 'ok' });
}

async function handleEvent(event: WebhookEvent) {
  if (event.type !== 'message' || event.message.type !== 'text') return;
  const msgEvent = event as line.webhook.MessageEvent & { message: { text: string } };
  const replyToken = msgEvent.replyToken;
  if (!replyToken) return;
  const userId = event.source?.userId ?? '';
  const text = msgEvent.message.text.trim();
  await handleText(replyToken, userId, text);
}

async function handleText(replyToken: string, userId: string, text: string) {
  if (text === 'เมนู' || text === 'menu') {
    const menus = menuService.getMenusByMerchant(MERCHANT_ID).filter((m) => m.isAvailable);
    if (!menus.length) { await replyMsg(replyToken, [{ type: 'text', text: 'ขณะนี้ยังไม่มีเมนูที่พร้อมให้บริการ' }]); return; }
    await replyMsg(replyToken, menus.slice(0, 5).map(buildMenuFlex));
    return;
  }

  if (text === 'สั่งอาหาร') {
    const orderUrl = env.liffUrl || `${env.renderExternalUrl}/order-web`;
    await replyMsg(replyToken, [{ type: 'flex', altText: 'สั่งอาหารออนไลน์', contents: { type: 'bubble', body: { type: 'box', layout: 'vertical', spacing: 'md', contents: [{ type: 'text', text: '🍽️ สั่งอาหารออนไลน์', weight: 'bold', size: 'xl' }, { type: 'text', text: 'เลือกเมนูและยืนยันการสั่งได้เลย', size: 'sm', color: '#999999', wrap: true }] }, footer: { type: 'box', layout: 'vertical', contents: [{ type: 'button', style: 'primary', color: '#FF6B00', action: { type: 'uri', label: '🛒 เปิดเมนูสั่งอาหาร', uri: orderUrl } }] } } } as unknown as LineMessage]);
    return;
  }

  if (text === 'ติดตามสถานะ') {
    const active = orderService.getOrdersByMerchant(MERCHANT_ID).filter((o) => o.customerId === userId && ['pending','confirmed','preparing','ready'].includes(o.status));
    if (!active.length) { await replyMsg(replyToken, [{ type: 'text', text: 'ไม่มีออเดอร์ที่กำลังดำเนินการ\n\nพิมพ์ "สั่งอาหาร" เพื่อสั่งอาหาร' }]); return; }
    await replyMsg(replyToken, active.slice(0, 5).map(buildOrderStatusFlex));
    return;
  }

  if (text.startsWith('สั่ง ')) {
    const menuName = text.slice(4).trim();
    const menus = menuService.getMenusByMerchant(MERCHANT_ID);
    const menu = fuzzyFind(menuName, menus, (m) => m.name, 3);
    if (!menu) { await replyMsg(replyToken, [{ type: 'text', text: `ไม่พบเมนู "${menuName}"\n\nพิมพ์ "เมนู" เพื่อดูทั้งหมด` }]); return; }
    if (!menu.isAvailable) { await replyMsg(replyToken, [{ type: 'text', text: `ขออภัย "${menu.name}" หมดชั่วคราว` }]); return; }
    const cart = cartService.addItem(userId, MERCHANT_ID, { menuId: menu.id, menuName: menu.name, quantity: 1, unitPrice: menu.price, spiceLevel: 2, customNote: null });
    await replyMsg(replyToken, [buildCartFlex(cart)]);
    return;
  }

  if (text.startsWith('เพิ่ม ')) {
    const menuName = text.slice(4).trim();
    const menu = fuzzyFind(menuName, menuService.getMenusByMerchant(MERCHANT_ID), (m) => m.name, 3);
    if (!menu || !menu.isAvailable) { await replyMsg(replyToken, [{ type: 'text', text: `ไม่พบเมนู "${menuName}" หรือหมดชั่วคราว` }]); return; }
    const cart = cartService.addItem(userId, MERCHANT_ID, { menuId: menu.id, menuName: menu.name, quantity: 1, unitPrice: menu.price, spiceLevel: 2, customNote: null });
    await replyMsg(replyToken, [buildCartFlex(cart)]);
    return;
  }

  if (text.startsWith('หมายเหตุ ')) {
    const note = text.slice(8).trim();
    const cart = cartService.getCart(userId);
    if (!cart?.items.length) { await replyMsg(replyToken, [{ type: 'text', text: 'ไม่มีรายการในตะกร้า' }]); return; }
    const items = [...cart.items];
    items[items.length - 1] = { ...items[items.length - 1], customNote: note };
    cartService.clearCart(userId);
    for (const item of items) cartService.addItem(userId, MERCHANT_ID, item);
    const finalCart = cartService.getCart(userId)!;
    await replyMsg(replyToken, [{ type: 'text', text: `✅ เพิ่มหมายเหตุ: "${note}"` }, buildCartFlex(finalCart)]);
    return;
  }

  if (text === 'ยืนยันออเดอร์') {
    const cart = cartService.getCart(userId);
    if (!cart?.items.length) { await replyMsg(replyToken, [{ type: 'text', text: 'ไม่มีรายการในตะกร้า' }]); return; }
    const order = orderService.createOrder(MERCHANT_ID, userId, 'ลูกค้า LINE', cart.items);
    cartService.clearCart(userId);
    await replyMsg(replyToken, [buildOrderConfirmFlex(order)]);
    return;
  }

  if (text === 'ยกเลิกตะกร้า') { cartService.clearCart(userId); await replyMsg(replyToken, [{ type: 'text', text: '🗑️ ล้างตะกร้าแล้ว' }]); return; }

  if (text === 'ดูตะกร้า' || text === 'ออเดอร์ของฉัน') {
    const cart = cartService.getCart(userId);
    if (cart?.items.length) { await replyMsg(replyToken, [buildCartFlex(cart)]); return; }
    const orders = orderService.getOrdersByMerchant(MERCHANT_ID).filter((o) => o.customerId === userId && ['pending','confirmed','preparing','ready'].includes(o.status));
    if (!orders.length) { await replyMsg(replyToken, [{ type: 'text', text: 'ไม่มีออเดอร์ที่กำลังดำเนินการ' }]); return; }
    await replyMsg(replyToken, orders.slice(0, 5).map(buildOrderStatusFlex));
    return;
  }

  if (text.startsWith('สถานะ #')) {
    const shortId = text.slice(5).trim();
    const order = orderService.getOrdersByMerchant(MERCHANT_ID).find((o) => o.id.endsWith(shortId));
    if (!order) { await replyMsg(replyToken, [{ type: 'text', text: `ไม่พบออเดอร์ #${shortId}` }]); return; }
    await replyMsg(replyToken, [buildOrderStatusFlex(order)]);
    return;
  }

  if (text === 'โปรโมชั่น') {
    await replyMsg(replyToken, [{ type: 'text', text: '🎉 โปรโมชั่นพิเศษ!\n• สั่ง 2 จาน ลด 10%\n• สั่งครบ 200 บาท ฟรีน้ำ 1 แก้ว\n\nพิมพ์ "เมนู" เพื่อดูรายการอาหาร' }]);
    return;
  }

  await replyMsg(replyToken, [{ type: 'text', text: '🍽️ สวัสดีครับ!\n\n• "สั่งอาหาร" — เปิดเมนูสั่งอาหาร\n• "ติดตามสถานะ" — ดูสถานะออเดอร์\n• "โปรโมชั่น" — ดูโปรโมชั่น' }]);
}

// ─── Flex builders ────────────────────────────────────────────────────────────

function buildMenuFlex(menu: ReturnType<typeof menuService.getMenusByMerchant>[number]): LineMessage {
  return { type: 'flex', altText: menu.name, contents: { type: 'bubble', ...(menu.imageUrl ? { hero: { type: 'image', url: menu.imageUrl, size: 'full', aspectRatio: '20:13', aspectMode: 'cover' } } : {}), body: { type: 'box', layout: 'vertical', spacing: 'md', contents: [{ type: 'text', text: menu.name, weight: 'bold', size: 'xl' }, { type: 'text', text: `฿${menu.price.toFixed(0)}`, color: '#FF6B00', size: 'lg', weight: 'bold' }, { type: 'text', text: menu.description, size: 'sm', color: '#999999', wrap: true }] }, footer: { type: 'box', layout: 'vertical', spacing: 'sm', contents: [{ type: 'button', style: 'primary', color: '#FF6B00', action: { type: 'message', label: 'สั่งเลย', text: `สั่ง ${menu.name}` } }, { type: 'button', style: 'secondary', action: { type: 'message', label: 'ดูเมนูทั้งหมด', text: 'เมนู' } }] } } } as unknown as LineMessage;
}

function buildCartFlex(cart: ReturnType<typeof cartService.getCart>): LineMessage {
  if (!cart) return { type: 'text', text: 'ตะกร้าว่าง' } as LineMessage;
  const total = cartService.cartTotal(cart);
  const rows = cart.items.map((i) => ({ type: 'box' as const, layout: 'baseline' as const, contents: [{ type: 'text' as const, text: `${i.menuName} ×${i.quantity}${i.customNote ? ` (${i.customNote})` : ''}`, size: 'sm' as const, color: '#555555', flex: 4 }, { type: 'text' as const, text: `฿${(i.unitPrice * i.quantity).toFixed(0)}`, align: 'end' as const, size: 'sm' as const, flex: 2 }] }));
  return { type: 'flex', altText: `ตะกร้า — ฿${total.toFixed(0)}`, contents: { type: 'bubble', body: { type: 'box', layout: 'vertical', spacing: 'md', contents: [{ type: 'text', text: '🛒 ตะกร้าของคุณ', weight: 'bold', size: 'xl' }, { type: 'separator' }, { type: 'box', layout: 'vertical', margin: 'sm', contents: rows }, { type: 'separator', margin: 'sm' }, { type: 'box', layout: 'baseline', contents: [{ type: 'text', text: 'ยอดรวม', size: 'sm', color: '#555555', flex: 4 }, { type: 'text', text: `฿${total.toFixed(0)}`, align: 'end', size: 'md', weight: 'bold', color: '#FF6B00', flex: 2 }] }] }, footer: { type: 'box', layout: 'vertical', spacing: 'sm', contents: [{ type: 'button', style: 'primary', color: '#FF6B00', action: { type: 'message', label: '✅ ยืนยันออเดอร์', text: 'ยืนยันออเดอร์' } }, { type: 'button', style: 'secondary', action: { type: 'message', label: '🗑️ ยกเลิก', text: 'ยกเลิกตะกร้า' } }] } } } as unknown as LineMessage;
}

function buildOrderConfirmFlex(order: ReturnType<typeof orderService.createOrder>): LineMessage {
  const rows = order.items.map((i) => ({ type: 'box' as const, layout: 'baseline' as const, contents: [{ type: 'text' as const, text: `${i.menuName} ×${i.quantity}`, size: 'sm' as const, color: '#555555', flex: 4 }, { type: 'text' as const, text: `฿${(i.unitPrice * i.quantity).toFixed(0)}`, align: 'end' as const, size: 'sm' as const, flex: 2 }] }));
  return { type: 'flex', altText: `✅ ยืนยันออเดอร์ #${order.id.slice(-6)}`, contents: { type: 'bubble', body: { type: 'box', layout: 'vertical', spacing: 'md', contents: [{ type: 'text', text: '✅ ยืนยันออเดอร์แล้ว', weight: 'bold', size: 'xl' }, { type: 'text', text: `#${order.id.slice(-6)}`, size: 'sm', color: '#999999' }, { type: 'separator' }, { type: 'box', layout: 'vertical', margin: 'sm', contents: rows }, { type: 'separator', margin: 'sm' }, { type: 'box', layout: 'baseline', contents: [{ type: 'text', text: 'ยอดรวม', size: 'sm', color: '#555555', flex: 4 }, { type: 'text', text: `฿${order.totalPrice.toFixed(0)}`, align: 'end', size: 'sm', weight: 'bold', flex: 2 }] }, ...(order.estimatedWaitMinutes > 0 ? [{ type: 'text' as const, text: `⏱ รอประมาณ ${order.estimatedWaitMinutes} นาที`, size: 'sm' as const, color: '#999999' }] : [])] }, footer: { type: 'box', layout: 'vertical', spacing: 'sm', contents: [{ type: 'button', style: 'primary', color: '#FF6B00', action: { type: 'message', label: 'ติดตามออเดอร์', text: `สถานะ #${order.id.slice(-6)}` } }, { type: 'button', style: 'secondary', action: { type: 'message', label: 'สั่งเพิ่ม', text: 'เมนู' } }] } } } as unknown as LineMessage;
}

function buildOrderStatusFlex(order: ReturnType<typeof orderService.getOrdersByMerchant>[number]): LineMessage {
  const statusLabel: Record<string, string> = { pending: '🕐 รอยืนยัน', confirmed: '✅ ยืนยันแล้ว', preparing: '👨‍🍳 กำลังทำ', ready: '🛵 พร้อมส่ง', completed: '✅ เสร็จสิ้น', cancelled: '❌ ยกเลิก' };
  return { type: 'flex', altText: `สถานะ #${order.id.slice(-6)}`, contents: { type: 'bubble', body: { type: 'box', layout: 'vertical', spacing: 'md', contents: [{ type: 'text', text: 'สถานะออเดอร์', weight: 'bold', size: 'lg' }, { type: 'text', text: `#${order.id.slice(-6)}`, size: 'sm', color: '#999999' }, { type: 'separator' }, { type: 'text', text: statusLabel[order.status] ?? order.status, size: 'xl', weight: 'bold' }, ...(order.estimatedWaitMinutes > 0 ? [{ type: 'text' as const, text: `⏱ รออีก ~${order.estimatedWaitMinutes} นาที`, size: 'sm' as const, color: '#999999' }] : []), { type: 'text', text: `ยอดรวม ฿${order.totalPrice.toFixed(0)}`, size: 'sm', color: '#555555' }] } } } as unknown as LineMessage;
}
