import { messagingApi } from '@line/bot-sdk';
import { env } from '../config/env';
import { generateRichMenuImage, customerAreas, merchantAreas } from './rich_menu_canvas';

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

export function buildCustomerMenu(shopName: string, large = false): RichMenuRequest {
  const H = large ? 1686 : 843;
  const areas = large ? [
    { bounds: { x: 0,    y: 0,    width: 833,  height: H / 2 }, action: { type: 'message' as const, label: 'สั่งอาหาร',     text: 'สั่งอาหาร' } },
    { bounds: { x: 833,  y: 0,    width: 834,  height: H / 2 }, action: { type: 'message' as const, label: 'ติดตามสถานะ',   text: 'ติดตามสถานะ' } },
    { bounds: { x: 1667, y: 0,    width: 833,  height: H / 2 }, action: { type: 'message' as const, label: 'โปรโมชั่น',     text: 'โปรโมชั่น' } },
    { bounds: { x: 0,    y: H/2,  width: 833,  height: H / 2 }, action: { type: 'message' as const, label: 'เมนูโปรด',      text: 'เมนูโปรด' } },
    { bounds: { x: 833,  y: H/2,  width: 834,  height: H / 2 }, action: { type: 'message' as const, label: 'ดูตะกร้า',      text: 'ดูตะกร้า' } },
    { bounds: { x: 1667, y: H/2,  width: 833,  height: H / 2 }, action: { type: 'message' as const, label: 'ติดต่อร้าน',    text: 'ติดต่อร้าน' } },
  ] : [
    { bounds: { x: 0,    y: 0, width: 833,  height: H }, action: { type: 'message' as const, label: 'สั่งอาหาร',   text: 'สั่งอาหาร' } },
    { bounds: { x: 833,  y: 0, width: 834,  height: H }, action: { type: 'message' as const, label: 'ติดตามสถานะ', text: 'ติดตามสถานะ' } },
    { bounds: { x: 1667, y: 0, width: 833,  height: H }, action: { type: 'message' as const, label: 'โปรโมชั่น',   text: 'โปรโมชั่น' } },
  ];
  return { size: { width: 2500, height: H }, selected: true, name: `${shopName} - Customer Menu`, chatBarText: 'เมนูร้าน', areas };
}

export function buildMerchantMenu(shopName: string, large = false): RichMenuRequest {
  const H = large ? 1686 : 843;
  const areas = large ? [
    { bounds: { x: 0,    y: 0,   width: 625, height: H / 2 }, action: { type: 'message' as const, label: 'ออเดอร์',   text: 'ออเดอร์วันนี้' } },
    { bounds: { x: 625,  y: 0,   width: 625, height: H / 2 }, action: { type: 'message' as const, label: 'สต๊อก',     text: 'สต๊อกวันนี้' } },
    { bounds: { x: 1250, y: 0,   width: 625, height: H / 2 }, action: { type: 'message' as const, label: 'รายได้',    text: 'สรุปรายได้' } },
    { bounds: { x: 1875, y: 0,   width: 625, height: H / 2 }, action: { type: 'message' as const, label: 'เพิ่มเมนู', text: 'เพิ่มเมนู' } },
    { bounds: { x: 0,    y: H/2, width: 625, height: H / 2 }, action: { type: 'message' as const, label: 'ตั้งค่า',   text: 'ตั้งค่า' } },
    { bounds: { x: 625,  y: H/2, width: 625, height: H / 2 }, action: { type: 'message' as const, label: 'รายงาน',   text: 'รายงาน' } },
    { bounds: { x: 1250, y: H/2, width: 625, height: H / 2 }, action: { type: 'message' as const, label: 'โปรโมชั่น', text: 'โปรโมชั่น' } },
    { bounds: { x: 1875, y: H/2, width: 625, height: H / 2 }, action: { type: 'message' as const, label: 'ช่วยเหลือ', text: 'ช่วยเหลือ' } },
  ] : [
    { bounds: { x: 0,    y: 0, width: 625, height: H }, action: { type: 'message' as const, label: 'ออเดอร์',   text: 'ออเดอร์วันนี้' } },
    { bounds: { x: 625,  y: 0, width: 625, height: H }, action: { type: 'message' as const, label: 'สต๊อก',     text: 'สต๊อกวันนี้' } },
    { bounds: { x: 1250, y: 0, width: 625, height: H }, action: { type: 'message' as const, label: 'รายได้',    text: 'สรุปรายได้' } },
    { bounds: { x: 1875, y: 0, width: 625, height: H }, action: { type: 'message' as const, label: 'เพิ่มเมนู', text: 'เพิ่มเมนู' } },
  ];
  return { size: { width: 2500, height: H }, selected: true, name: `${shopName} - Merchant Menu`, chatBarText: 'จัดการร้าน', areas };
}

// ─── Deploy ───────────────────────────────────────────────────────────────────

export async function deployCustomerMenu(shopName: string, bgBuffer: Buffer, large = false): Promise<string> {
  const menuRequest = buildCustomerMenu(shopName, large);
  const H = large ? 1686 : 843;
  const image = await generateRichMenuImage(bgBuffer, customerAreas(H), H);
  return _createAndDeploy(menuRequest, image);
}

export async function deployMerchantMenu(shopName: string, bgBuffer: Buffer, large = false): Promise<string> {
  const menuRequest = buildMerchantMenu(shopName, large);
  const H = large ? 1686 : 843;
  const image = await generateRichMenuImage(bgBuffer, merchantAreas(H), H);
  return _createAndDeploy(menuRequest, image);
}

async function _createAndDeploy(
  menuRequest: RichMenuRequest,
  imageBuffer: Buffer
): Promise<string> {
  const client = getClient();
  const blobClient = getBlobClient();

  const { richMenuId } = await client.createRichMenu(menuRequest);

  const rawBuffer = imageBuffer.buffer instanceof SharedArrayBuffer
    ? (imageBuffer.buffer.slice(0) as unknown as ArrayBuffer)
    : (imageBuffer.buffer.slice(imageBuffer.byteOffset, imageBuffer.byteOffset + imageBuffer.byteLength) as unknown as ArrayBuffer);

  const blob = new Blob([rawBuffer], { type: 'image/jpeg' });
  await blobClient.setRichMenuImage(richMenuId, blob);

  await client.setDefaultRichMenu(richMenuId);

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
}
