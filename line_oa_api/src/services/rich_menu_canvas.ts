import sharp from 'sharp';

const W = 2500;

interface ButtonArea {
  x: number;
  y: number;
  width: number;
  height: number;
  label: string;
}

// ─── Compose final image ──────────────────────────────────────────────────────

export async function generateRichMenuImage(
  bgBuffer: Buffer,
  _areas: ButtonArea[],
  H: number = 843
): Promise<Buffer> {
  return sharp(bgBuffer)
    .resize(W, H, { fit: 'cover', position: 'centre' })
    .jpeg({ quality: 85 })
    .toBuffer();
}

// ─── Area factories ───────────────────────────────────────────────────────────

export function customerAreas(H: number = 843): ButtonArea[] {
  if (H === 1686) return [
    { x: 0,    y: 0,      width: 833,  height: 843, label: 'สั่งอาหาร' },
    { x: 833,  y: 0,      width: 834,  height: 843, label: 'ติดตามสถานะ' },
    { x: 1667, y: 0,      width: 833,  height: 843, label: 'โปรโมชั่น' },
    { x: 0,    y: 843,    width: 833,  height: 843, label: 'เมนูโปรด' },
    { x: 833,  y: 843,    width: 834,  height: 843, label: 'ดูตะกร้า' },
    { x: 1667, y: 843,    width: 833,  height: 843, label: 'ติดต่อร้าน' },
  ];
  return [
    { x: 0,    y: 0, width: 833,  height: H, label: 'สั่งอาหาร' },
    { x: 833,  y: 0, width: 834,  height: H, label: 'ติดตามสถานะ' },
    { x: 1667, y: 0, width: 833,  height: H, label: 'โปรโมชั่น' },
  ];
}

export function merchantAreas(H: number = 843): ButtonArea[] {
  if (H === 1686) return [
    { x: 0,    y: 0,   width: 625, height: 843, label: 'ออเดอร์' },
    { x: 625,  y: 0,   width: 625, height: 843, label: 'สต๊อก' },
    { x: 1250, y: 0,   width: 625, height: 843, label: 'รายได้' },
    { x: 1875, y: 0,   width: 625, height: 843, label: 'เพิ่มเมนู' },
    { x: 0,    y: 843, width: 625, height: 843, label: 'ตั้งค่า' },
    { x: 625,  y: 843, width: 625, height: 843, label: 'รายงาน' },
    { x: 1250, y: 843, width: 625, height: 843, label: 'โปรโมชั่น' },
    { x: 1875, y: 843, width: 625, height: 843, label: 'ช่วยเหลือ' },
  ];
  return [
    { x: 0,    y: 0, width: 625, height: H, label: 'ออเดอร์' },
    { x: 625,  y: 0, width: 625, height: H, label: 'สต๊อก' },
    { x: 1250, y: 0, width: 625, height: H, label: 'รายได้' },
    { x: 1875, y: 0, width: 625, height: H, label: 'เพิ่มเมนู' },
  ];
}
