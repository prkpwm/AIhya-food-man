import { messagingApi } from '@line/bot-sdk';
import { env } from '../config/env';
import sharp from 'sharp';

type RichMenuRequest = messagingApi.RichMenuRequest;
type RichMenuResponse = messagingApi.RichMenuResponse;

const W = 2500;

function getClient() {
  return new messagingApi.MessagingApiClient({ channelAccessToken: env.line.channelAccessToken });
}
function getBlobClient() {
  return new messagingApi.MessagingApiBlobClient({ channelAccessToken: env.line.channelAccessToken });
}

function liffUri(page: string): string {
  return `${env.liffUrl}?page=${page}`;
}

export function buildCustomerMenu(shopName: string, large = false): RichMenuRequest {
  const H = large ? 1686 : 843;
  const areas = large ? [
    { bounds: { x: 0,    y: 0,    width: 833,  height: H/2 }, action: { type: 'uri' as const, label: 'สั่งอาหาร',   uri: liffUri('order') } },
    { bounds: { x: 833,  y: 0,    width: 834,  height: H/2 }, action: { type: 'uri' as const, label: 'ติดตามสถานะ', uri: liffUri('status') } },
    { bounds: { x: 1667, y: 0,    width: 833,  height: H/2 }, action: { type: 'uri' as const, label: 'โปรโมชั่น',   uri: liffUri('promotion') } },
    { bounds: { x: 0,    y: H/2,  width: 833,  height: H/2 }, action: { type: 'uri' as const, label: 'เมนูโปรด',    uri: liffUri('favorites') } },
    { bounds: { x: 833,  y: H/2,  width: 834,  height: H/2 }, action: { type: 'uri' as const, label: 'ดูตะกร้า',    uri: liffUri('cart') } },
    { bounds: { x: 1667, y: H/2,  width: 833,  height: H/2 }, action: { type: 'uri' as const, label: 'ติดต่อร้าน',  uri: liffUri('contact') } },
  ] : [
    { bounds: { x: 0,    y: 0, width: 833,  height: H }, action: { type: 'uri' as const, label: 'สั่งอาหาร',   uri: liffUri('order') } },
    { bounds: { x: 833,  y: 0, width: 834,  height: H }, action: { type: 'uri' as const, label: 'ติดตามสถานะ', uri: liffUri('status') } },
    { bounds: { x: 1667, y: 0, width: 833,  height: H }, action: { type: 'uri' as const, label: 'โปรโมชั่น',   uri: liffUri('promotion') } },
  ];
  return { size: { width: W, height: H }, selected: true, name: `${shopName} - Customer Menu`, chatBarText: 'เมนูร้าน', areas };
}

export function buildMerchantMenu(shopName: string, large = false): RichMenuRequest {
  const H = large ? 1686 : 843;
  const areas = large ? [
    { bounds: { x: 0,    y: 0,   width: 625, height: H/2 }, action: { type: 'uri' as const, label: 'ออเดอร์',   uri: liffUri('merchant-orders') } },
    { bounds: { x: 625,  y: 0,   width: 625, height: H/2 }, action: { type: 'uri' as const, label: 'สต๊อก',     uri: liffUri('merchant-stock') } },
    { bounds: { x: 1250, y: 0,   width: 625, height: H/2 }, action: { type: 'uri' as const, label: 'รายได้',    uri: liffUri('merchant-income') } },
    { bounds: { x: 1875, y: 0,   width: 625, height: H/2 }, action: { type: 'uri' as const, label: 'เพิ่มเมนู', uri: liffUri('merchant-add-menu') } },
    { bounds: { x: 0,    y: H/2, width: 625, height: H/2 }, action: { type: 'uri' as const, label: 'ตั้งค่า',   uri: liffUri('merchant-settings') } },
    { bounds: { x: 625,  y: H/2, width: 625, height: H/2 }, action: { type: 'uri' as const, label: 'รายงาน',   uri: liffUri('merchant-report') } },
    { bounds: { x: 1250, y: H/2, width: 625, height: H/2 }, action: { type: 'uri' as const, label: 'โปรโมชั่น', uri: liffUri('merchant-promotion') } },
    { bounds: { x: 1875, y: H/2, width: 625, height: H/2 }, action: { type: 'uri' as const, label: 'ช่วยเหลือ', uri: liffUri('merchant-help') } },
  ] : [
    { bounds: { x: 0,    y: 0, width: 625, height: H }, action: { type: 'uri' as const, label: 'ออเดอร์',   uri: liffUri('merchant-orders') } },
    { bounds: { x: 625,  y: 0, width: 625, height: H }, action: { type: 'uri' as const, label: 'สต๊อก',     uri: liffUri('merchant-stock') } },
    { bounds: { x: 1250, y: 0, width: 625, height: H }, action: { type: 'uri' as const, label: 'รายได้',    uri: liffUri('merchant-income') } },
    { bounds: { x: 1875, y: 0, width: 625, height: H }, action: { type: 'uri' as const, label: 'เพิ่มเมนู', uri: liffUri('merchant-add-menu') } },
  ];
  return { size: { width: W, height: H }, selected: true, name: `${shopName} - Merchant Menu`, chatBarText: 'จัดการร้าน', areas };
}

async function generateImage(bgBuffer: Buffer, H: number): Promise<Buffer> {
  return sharp(bgBuffer).resize(W, H, { fit: 'cover', position: 'centre' }).jpeg({ quality: 85 }).toBuffer();
}

async function createAndDeploy(menuRequest: RichMenuRequest, imageBuffer: Buffer): Promise<string> {
  const client = getClient();
  const blobClient = getBlobClient();
  const { richMenuId } = await client.createRichMenu(menuRequest);
  const rawBuffer = imageBuffer.buffer instanceof SharedArrayBuffer
    ? (imageBuffer.buffer.slice(0) as unknown as ArrayBuffer)
    : (imageBuffer.buffer.slice(imageBuffer.byteOffset, imageBuffer.byteOffset + imageBuffer.byteLength) as unknown as ArrayBuffer);
  await blobClient.setRichMenuImage(richMenuId, new Blob([rawBuffer], { type: 'image/jpeg' }));
  await client.setDefaultRichMenu(richMenuId);
  return richMenuId;
}

export async function deployCustomerMenu(shopName: string, bgBuffer: Buffer, large = false): Promise<string> {
  const H = large ? 1686 : 843;
  return createAndDeploy(buildCustomerMenu(shopName, large), await generateImage(bgBuffer, H));
}

export async function deployMerchantMenu(shopName: string, bgBuffer: Buffer, large = false): Promise<string> {
  const H = large ? 1686 : 843;
  return createAndDeploy(buildMerchantMenu(shopName, large), await generateImage(bgBuffer, H));
}

export async function listRichMenus(): Promise<RichMenuResponse[]> {
  const res = await getClient().getRichMenuList();
  return (res.richmenus ?? []) as unknown as RichMenuResponse[];
}

export async function deleteRichMenu(richMenuId: string): Promise<void> {
  await getClient().deleteRichMenu(richMenuId);
}
