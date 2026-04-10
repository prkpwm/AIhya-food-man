import * as line from '@line/bot-sdk';
import { Order, Menu } from '../types';

type LineMessage = Parameters<line.messagingApi.MessagingApiClient['pushMessage']>[0]['messages'][number];

// create a client per merchant (each has own channel token)
function getClient(accessToken: string): line.messagingApi.MessagingApiClient {
  return new line.messagingApi.MessagingApiClient({ channelAccessToken: accessToken });
}

// ─── Push order confirmation ──────────────────────────────────────────────────

export async function pushOrderConfirmation(
  accessToken: string,
  userId: string,
  order: Order
): Promise<void> {
  const client = getClient(accessToken);

  const itemRows = order.items.map((item) => ({
    type: 'box' as const,
    layout: 'baseline' as const,
    contents: [
      { type: 'text' as const, text: `${item.menuName} ×${item.quantity}`, size: 'sm' as const, color: '#555555', flex: 4 },
      { type: 'text' as const, text: `฿${(item.unitPrice * item.quantity).toFixed(0)}`, align: 'end' as const, size: 'sm' as const, flex: 2 },
    ],
  }));

  const flex: line.FlexMessage = {
    type: 'flex',
    altText: `ยืนยันออเดอร์ #${order.id.slice(-6)}`,
    contents: {
      type: 'bubble',
      body: {
        type: 'box',
        layout: 'vertical',
        spacing: 'md',
        contents: [
          { type: 'text', text: 'ยืนยันออเดอร์', weight: 'bold', size: 'xl' },
          { type: 'text', text: `#${order.id.slice(-6)} · ${order.customerName}`, size: 'sm', color: '#999999' },
          { type: 'separator' },
          { type: 'box', layout: 'vertical', margin: 'sm', contents: [...itemRows] },
          { type: 'separator', margin: 'sm' },
          {
            type: 'box', layout: 'baseline', contents: [
              { type: 'text', text: 'ยอดรวม', size: 'sm', color: '#555555', flex: 4 },
              { type: 'text', text: `฿${order.totalPrice.toFixed(0)}`, align: 'end', size: 'sm', weight: 'bold', flex: 2 },
            ],
          },
          ...(order.estimatedWaitMinutes > 0
            ? [{ type: 'text' as const, text: `รอประมาณ ${order.estimatedWaitMinutes} นาที`, size: 'sm' as const, color: '#999999' }]
            : []),
        ],
      },
      footer: {
        type: 'box',
        layout: 'vertical',
        spacing: 'sm',
        contents: [
          {
            type: 'button', style: 'primary', color: '#FF6B00',
            action: { type: 'message', label: 'ติดตามออเดอร์', text: `สถานะ #${order.id.slice(-6)}` },
          },
          {
            type: 'button', style: 'secondary',
            action: { type: 'message', label: 'ยกเลิก', text: `ยกเลิก #${order.id.slice(-6)}` },
          },
        ],
      },
    },
  };

  await client.pushMessage({ to: userId, messages: [flex as unknown as LineMessage] });
}

// ─── Push order status update ─────────────────────────────────────────────────

export async function pushOrderStatus(
  accessToken: string,
  userId: string,
  order: Order
): Promise<void> {
  const client = getClient(accessToken);

  const statusLabel: Record<string, string> = {
    confirmed: 'ยืนยันแล้ว',
    preparing: 'กำลังทำ',
    ready: 'พร้อมส่ง',
    completed: 'เสร็จสิ้น',
    cancelled: 'ยกเลิก',
  };

  const msg: line.TextMessage = {
    type: 'text',
    text: `📦 ออเดอร์ #${order.id.slice(-6)}\nสถานะ: ${statusLabel[order.status] ?? order.status}${order.estimatedWaitMinutes > 0 ? `\nรออีก ~${order.estimatedWaitMinutes} นาที` : ''}`,
  };

  await client.pushMessage({ to: userId, messages: [msg] });
}

// ─── Push menu card ───────────────────────────────────────────────────────────

export async function pushMenuCard(
  accessToken: string,
  userId: string,
  menu: Menu
): Promise<void> {
  const client = getClient(accessToken);

  const flex: line.FlexMessage = {
    type: 'flex',
    altText: menu.name,
    contents: {
      type: 'bubble',
      ...(menu.imageUrl ? {
        hero: {
          type: 'image',
          url: menu.imageUrl,
          size: 'full',
          aspectRatio: '20:13',
          aspectMode: 'cover',
        },
      } : {}),
      body: {
        type: 'box',
        layout: 'vertical',
        spacing: 'md',
        contents: [
          { type: 'text', text: menu.name, weight: 'bold', size: 'xl' },
          { type: 'text', text: `฿${menu.price.toFixed(0)}`, color: '#FF6B00', size: 'lg', weight: 'bold' },
          { type: 'text', text: menu.description, size: 'sm', color: '#999999', wrap: true },
          ...(!menu.isAvailable ? [{ type: 'text' as const, text: '⚠️ หมดชั่วคราว', size: 'sm' as const, color: '#F44336' }] : []),
        ],
      },
      footer: {
        type: 'box',
        layout: 'vertical',
        spacing: 'sm',
        contents: [
          {
            type: 'button', style: 'primary', color: '#FF6B00',
            action: { type: 'message', label: 'สั่งเลย', text: `สั่ง ${menu.name}` },
          },
          {
            type: 'button', style: 'secondary',
            action: { type: 'message', label: 'ดูเมนูทั้งหมด', text: 'เมนู' },
          },
        ],
      },
    },
  };

  await client.pushMessage({ to: userId, messages: [flex as unknown as LineMessage] });
}
