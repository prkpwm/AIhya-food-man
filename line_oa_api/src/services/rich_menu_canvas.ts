import sharp from 'sharp';

const W = 2500;
const H = 843;

interface ButtonArea {
  x: number;
  y: number;
  width: number;
  height: number;
  label: string;
}

// ─── Generate SVG overlay with button labels ──────────────────────────────────

function buildSvgOverlay(areas: ButtonArea[]): Buffer {
  const dividers = areas.slice(0, -1).map((a) => {
    const x = a.x + a.width;
    return `<line x1="${x}" y1="0" x2="${x}" y2="${H}" stroke="rgba(255,255,255,0.5)" stroke-width="3"/>`;
  });

  const labels = areas.map((a) => {
    const cx = a.x + a.width / 2;
    const cy = H / 2 + 10;
    return `
      <rect x="${a.x + 20}" y="${cy - 44}" width="${a.width - 40}" height="56"
            rx="28" fill="rgba(0,0,0,0.55)"/>
      <text x="${cx}" y="${cy + 4}"
            font-family="Arial, sans-serif" font-size="52" font-weight="bold"
            fill="white" text-anchor="middle" dominant-baseline="middle">${a.label}</text>`;
  });

  return Buffer.from(`
    <svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}">
      ${dividers.join('\n')}
      ${labels.join('\n')}
    </svg>`);
}

// ─── Compose final 2500×843 image ─────────────────────────────────────────────

export async function generateRichMenuImage(
  bgBuffer: Buffer,
  areas: ButtonArea[]
): Promise<Buffer> {
  const svg = buildSvgOverlay(areas);

  const result = await sharp(bgBuffer)
    .resize(W, H, { fit: 'cover', position: 'centre' })
    .composite([{ input: svg, top: 0, left: 0 }])
    .jpeg({ quality: 85 })
    .toBuffer();

  console.table({
    step: 'canvas-generated',
    size: result.length,
    buttons: areas.length,
  });

  return result;
}

// ─── Area definitions ─────────────────────────────────────────────────────────

export const customerAreas: ButtonArea[] = [
  { x: 0,    y: 0, width: 833,  height: H, label: 'ดูเมนู' },
  { x: 833,  y: 0, width: 834,  height: H, label: 'ออเดอร์' },
  { x: 1667, y: 0, width: 833,  height: H, label: 'โปรโมชั่น' },
];

export const merchantAreas: ButtonArea[] = [
  { x: 0,    y: 0, width: 625, height: H, label: 'ออเดอร์' },
  { x: 625,  y: 0, width: 625, height: H, label: 'สต๊อก' },
  { x: 1250, y: 0, width: 625, height: H, label: 'รายได้' },
  { x: 1875, y: 0, width: 625, height: H, label: 'เพิ่มเมนู' },
];
