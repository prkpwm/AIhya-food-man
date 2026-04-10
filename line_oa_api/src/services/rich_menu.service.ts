import { messagingApi } from '@line/bot-sdk';
import sharp from 'sharp';
import { env } from '../config/env';

type RichMenuRequest = messagingApi.RichMenuRequest;
type RichMenuResponse = messagingApi.RichMenuResponse;

function getClient(): messagingApi.MessagingApiClient {
  return new messagingApi.MessagingApiClient({
    channelAccessToken: env.line.channelAccessToken,
  });
}

function getBlobClient(): messagingApi.MessagingApiBlobClient {
  return new messagingApi.MessagingApiBlobClient({
    channelAccessToken: env.line.channelAccessToken,
  });
}

// ─── Customer Rich Menu ───────────────────────────────────────────────────────

export function buildCustomerMenu(shopName: string): RichMenuRequest {
  return {
    size: { width: 2500, height: 843 },
    selected: true,
    name: `${shopName} - Customer Menu`,
    chatBarText: 'เมนูร้าน',
    areas: [
      {
        bounds: { x: 0, y: 0, width: 833, height: 843 },
        action: { type: 'message', label: 'ดูเมนู', text: 'เมนู' },
      },
      {
        bounds: { x: 833, y: 0, width: 834, height: 843 },
        action: { type: 'message', label: 'ออเดอร์ของฉัน', text: 'ดูตะกร้า' },
      },
      {
        bounds: { x: 1667, y: 0, width: 833, height: 843 },
        action: { type: 'message', label: 'โปรโมชั่น', text: 'โปรโมชั่น' },
      },
    ],
  };
}

// ─── Merchant Rich Menu ───────────────────────────────────────────────────────

export function buildMerchantMenu(shopName: string): RichMenuRequest {
  return {
    size: { width: 2500, height: 843 },
    selected: true,
    name: `${shopName} - Merchant Menu`,
    chatBarText: 'จัดการร้าน',
    areas: [
      {
        bounds: { x: 0, y: 0, width: 625, height: 843 },
        action: { type: 'message', label: 'ออเดอร์', text: 'ออเดอร์วันนี้' },
      },
      {
        bounds: { x: 625, y: 0, width: 625, height: 843 },
        action: { type: 'message', label: 'สต๊อก', text: 'สต๊อกวันนี้' },
      },
      {
        bounds: { x: 1250, y: 0, width: 625, height: 843 },
        action: { type: 'message', label: 'รายได้', text: 'สรุปรายได้' },
      },
      {
        bounds: { x: 1875, y: 0, width: 625, height: 843 },
        action: { type: 'message', label: 'เพิ่มเมนู', text: 'เพิ่มเมนู' },
      },
    ],
  };
}

// ─── Compress image to fit LINE's 1MB limit at exact 2500x843 ────────────────

async function compressForLine(input: Buffer): Promise<{ buffer: Buffer; type: 'image/jpeg' | 'image/png' }> {
  // resize to exact 2500x843 and compress as JPEG under 1MB
  let quality = 90;
  let buffer: Buffer;

  do {
    buffer = await sharp(input)
      .resize(2500, 843, { fit: 'fill' })
      .jpeg({ quality })
      .toBuffer();
    quality -= 10;
  } while (buffer.length > 900 * 1024 && quality > 10); // stay under 900KB

  console.table({
    step: 'image-compressed',
    originalSize: input.length,
    compressedSize: buffer.length,
    quality: quality + 10,
  });

  return { buffer, type: 'image/jpeg' };
}

// ─── Deploy ───────────────────────────────────────────────────────────────────

export async function createAndSetDefault(
  menuRequest: RichMenuRequest,
  imageBuffer: Buffer,
  _imageType: 'image/jpeg' | 'image/png'
): Promise<string> {
  const client = getClient();
  const blobClient = getBlobClient();

  // 1. create rich menu
  const { richMenuId } = await client.createRichMenu(menuRequest);
  console.table({ step: 'rich-menu-created', richMenuId });

  // 2. compress + resize to LINE spec (2500x843, <1MB JPEG)
  const { buffer: compressed, type } = await compressForLine(imageBuffer);

  const rawBuffer = compressed.buffer instanceof SharedArrayBuffer
    ? (compressed.buffer.slice(0) as unknown as ArrayBuffer)
    : (compressed.buffer.slice(compressed.byteOffset, compressed.byteOffset + compressed.byteLength) as unknown as ArrayBuffer);
  const blob = new Blob([rawBuffer], { type });
  await blobClient.setRichMenuImage(richMenuId, blob);
  console.table({ step: 'rich-menu-image-uploaded', richMenuId, type, size: compressed.length });

  // 3. set as default
  await client.setDefaultRichMenu(richMenuId);
  console.table({ step: 'rich-menu-deployed', richMenuId });

  return richMenuId;
}

export async function listRichMenus(): Promise<RichMenuResponse[]> {
  const client = getClient();
  const res = await client.getRichMenuList();
  return (res.richmenus ?? []) as unknown as RichMenuResponse[];
}

export async function deleteRichMenu(richMenuId: string): Promise<void> {
  const client = getClient();
  await client.deleteRichMenu(richMenuId);
  console.table({ step: 'rich-menu-deleted', richMenuId });
}
