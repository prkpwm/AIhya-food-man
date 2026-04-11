import { NextRequest, NextResponse } from 'next/server';
import { ensureInit } from '@/lib/init';
import * as menuService from '@/lib/services/menu.service';
import { env } from '@/lib/config/env';
import { Menu } from '@/lib/types';
import * as path from 'node:path';
import * as fs from 'node:fs';

ensureInit();

function baseUrl() {
  return env.renderExternalUrl || 'http://localhost:3000';
}

export function GET(req: NextRequest) {
  const merchantId = req.nextUrl.searchParams.get('merchantId') ?? 'merchant-001';
  return NextResponse.json({ success: true, data: menuService.getMenusByMerchant(merchantId) });
}

export async function POST(req: NextRequest) {
  const contentType = req.headers.get('content-type') ?? '';
  let body: Partial<Menu> & { imageBase64?: string; imageName?: string } = {};
  let imageUrl: string | null = null;

  if (contentType.includes('multipart/form-data')) {
    const form = await req.formData();
    body = Object.fromEntries(form.entries()) as unknown as typeof body;
    const file = form.get('image') as File | null;
    if (file) {
      const buf = Buffer.from(await file.arrayBuffer());
      const ext = path.extname(file.name) || '.jpg';
      const filename = `menu-${Date.now()}${ext}`;
      const dir = path.join(process.cwd(), 'public', 'images', 'menus');
      fs.mkdirSync(dir, { recursive: true });
      fs.writeFileSync(path.join(dir, filename), buf);
      imageUrl = `${baseUrl()}/images/menus/${filename}`;
    }
  } else {
    body = await req.json();
  }

  if (!body.name || !body.merchantId) {
    return NextResponse.json({ code: '400', en: 'Missing required fields', th: 'ข้อมูลไม่ครบถ้วน' }, { status: 400 });
  }

  const menu = menuService.upsertMenu({
    ...(body as Omit<Menu, 'id'>),
    price: Number(body.price),
    maxSpiceLevel: Number(body.maxSpiceLevel ?? 3),
    isAvailable: body.isAvailable === true || (body.isAvailable as unknown as string) === 'true',
    ingredientIds: Array.isArray(body.ingredientIds) ? body.ingredientIds : [],
    imageUrl: imageUrl ?? (body.imageUrl as string | null) ?? null,
  });

  return NextResponse.json({ success: true, data: menu }, { status: 201 });
}
