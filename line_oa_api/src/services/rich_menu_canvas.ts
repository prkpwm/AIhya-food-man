import sharp from 'sharp';

const W = 2500;

interface ButtonArea {
  x: number;
  y: number;
  width: number;
  height: number;
  label: string;
}

// ─── SVG overlay ──────────────────────────────────────────────────────────────

function buildSvgOverlay(areas: ButtonArea[], H: number): Buffer {
  // vertical dividers between columns (same x, different rows)
  const seenX = new Set<number>();
  const dividers: string[] = [];
  for (const a of areas) {
    const x = a.x + a.width;
    if (!seenX.has(x) && x < W) {
      seenX.add(x);
      dividers.push(`<line x1="${x}" y1="0" x2="${x}" y2="${H}" stroke="rgba(255,255,255,0.4)" stroke-width="3"/>`);
    }
  }

  // horizontal divider for large menu
  const rows = [...new Set(areas.map((a) => a.y))];
  const hDividers = rows.slice(1).map((y) =>
    `<line x1="0" y1="${y}" x2="${W}" y2="${y}" stroke="rgba(255,255,255,0.4)" stroke-width="3"/>`
  );

  const labels = areas.map((a) => {
    const cx = a.x + a.width / 2;
    const cy = a.y + a.height / 2;
    return `
      <rect x="${a.x + 30}" y="${cy - 46}" width="${a.width - 60}" height="60"
            rx="30" fill="rgba(0,0,0,0.6)"/>
      <text x="${cx}" y="${cy + 6}"
            font-family="Arial, sans-serif" font-size="54" font-weight="bold"
            fill="white" text-anchor="middle" dominant-baseline="middle">${a.label}</text>`;
  });

  return Buffer.from(`
    <svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}">
      ${dividers.join('\n')}
      ${hDividers.join('\n')}
      ${labels.join('\n')}
    </svg>`);
}

// ─── Compose final image ──────────────────────────────────────────────────────

export async function generateRichMenuImage(
  bgBuffer: Buffer,
  areas: ButtonArea[],
  H: number = 843
): Promise<Buffer> {
  const svg = buildSvgOverlay(areas, H);

  const result = await sharp(bgBuffer)
    .resize(W, H, { fit: 'cover', position: 'centre' })
    .composite([{ input: svg, top: 0, left: 0 }])
    .jpeg({ quality: 85 })
    .toBuffer();

  console.table({ step: 'canvas-generated', size: result.length, buttons: areas.length, H });
  return result;
}

// ─── Area factories ───────────────────────────────────────────────────────────

export function customerAreas(H: number = 843): ButtonArea[] {
  if (H === 1686) return [
    { x: 0,    y: 0,      width: 833,  height: 843, label: 'ดูเมนู' },
    { x: 833,  y: 0,      width: 834,  height: 843, label: 'ออเดอร์' },
    { x: 1667, y: 0,      width: 833,  height: 843, label: 'โปรโมชั่น' },
    { x: 0,    y: 843,    width: 833,  height: 843, label: 'เมนูโปรด' },
    { x: 833,  y: 843,    width: 834,  height: 843, label: 'ดูตะกร้า' },
    { x: 1667, y: 843,    width: 833,  height: 843, label: 'ติดต่อร้าน' },
  ];
  return [
    { x: 0,    y: 0, width: 833,  height: H, label: 'ดูเมนู' },
    { x: 833,  y: 0, width: 834,  height: H, label: 'ออเดอร์' },
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
