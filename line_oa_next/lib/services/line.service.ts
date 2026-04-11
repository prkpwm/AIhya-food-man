import * as line from '@line/bot-sdk';
import { Order } from '../types';

type LineMessage = Parameters<line.messagingApi.MessagingApiClient['pushMessage']>[0]['messages'][number];

function getClient(accessToken: string) {
  return new line.messagingApi.MessagingApiClient({ channelAccessToken: accessToken });
}

export async function pushMessage(accessToken: string, userId: string, messages: LineMessage[]): Promise<void> {
  await getClient(accessToken).pushMessage({ to: userId, messages });
}

export async function replyMessage(accessToken: string, replyToken: string, messages: LineMessage[]): Promise<void> {
  await getClient(accessToken).replyMessage({ replyToken, messages });
}

export async function pushOrderStatus(accessToken: string, userId: string, order: Order): Promise<void> {
  const statusLabel: Record<string, string> = { confirmed: 'ยืนยันแล้ว', preparing: 'กำลังทำ', ready: 'พร้อมส่ง', completed: 'เสร็จสิ้น', cancelled: 'ยกเลิก' };
  await pushMessage(accessToken, userId, [{
    type: 'text',
    text: `📦 ออเดอร์ #${order.id.slice(-6)}\nสถานะ: ${statusLabel[order.status] ?? order.status}${order.estimatedWaitMinutes > 0 ? `\nรออีก ~${order.estimatedWaitMinutes} นาที` : ''}`,
  } as LineMessage]);
}

export async function broadcastFlex(accessToken: string, flex: unknown): Promise<void> {
  await getClient(accessToken).broadcast({ messages: [flex as LineMessage] });
}

export async function pushFlex(accessToken: string, userId: string, flex: unknown) {
  return getClient(accessToken).pushMessage({ to: userId, messages: [flex as LineMessage] });
}
