import * as line from '@line/bot-sdk';
import { Order } from '../types';

type LineMessage = Parameters<line.messagingApi.MessagingApiClient['pushMessage']>[0]['messages'][number];

const LINE_REPLY_URL = 'https://api.line.me/v2/bot/message/reply';
const LINE_PUSH_URL = 'https://api.line.me/v2/bot/message/push';
const LINE_BROADCAST_URL = 'https://api.line.me/v2/bot/message/broadcast';

function authHeader(accessToken: string) {
  return { 'Content-Type': 'application/json', Authorization: `Bearer ${accessToken}` };
}

function getClient(accessToken: string) {
  return new line.messagingApi.MessagingApiClient({ channelAccessToken: accessToken });
}

export async function pushMessage(accessToken: string, userId: string, messages: LineMessage[]) {
  return fetch(LINE_PUSH_URL, {
    method: 'POST',
    headers: authHeader(accessToken),
    body: JSON.stringify({ to: userId, messages }),
  });
}

export async function replyMessage(accessToken: string, replyToken: string, messages: LineMessage[]) {
  return fetch(LINE_REPLY_URL, {
    method: 'POST',
    headers: authHeader(accessToken),
    body: JSON.stringify({ replyToken, messages }),
  });
}

export async function pushOrderStatus(accessToken: string, userId: string, order: Order) {
  const statusLabel: Record<string, string> = { confirmed: 'ยืนยันแล้ว', preparing: 'กำลังทำ', ready: 'พร้อมส่ง', completed: 'เสร็จสิ้น', cancelled: 'ยกเลิก' };
  return pushMessage(accessToken, userId, [{
    type: 'text',
    text: `📦 ออเดอร์ #${order.id.slice(-6)}\nสถานะ: ${statusLabel[order.status] ?? order.status}${order.estimatedWaitMinutes > 0 ? `\nรออีก ~${order.estimatedWaitMinutes} นาที` : ''}`,
  } as LineMessage]);
}

export async function broadcastFlex(accessToken: string, flex: unknown) {
  return fetch(LINE_BROADCAST_URL, {
    method: 'POST',
    headers: authHeader(accessToken),
    body: JSON.stringify({ messages: [flex] }),
  });
}

export async function pushFlex(accessToken: string, userId: string, flex: unknown) {
  return pushMessage(accessToken, userId, [flex as LineMessage]);
}
