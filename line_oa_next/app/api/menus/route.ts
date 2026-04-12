import { NextRequest, NextResponse } from 'next/server';
import { ensureInit } from '@/lib/init';
import * as menuService from '@/lib/services/menu.service';
import { env } from '@/lib/config/env';
import { Menu } from '@/lib/types';
import * as path from 'node:path';
import * as fs from 'node:fs';

ensureInit();

export const dynamic = 'force-dynamic';

function baseUrl() { return env.renderExternalUrl || 'http://localhost:3000'; }

export async function GET(req: NextRequest) {
  try {
    const merchantId = req.nextUrl.searchParams.get('merchantId') ?? 'merchant-001';
    const data = await menuService.getMenusByMerchant(merchantId);
    return NextResponse.json({ success: true, data });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  try {
    const contentType = req.headers.get('content-type') ?? '';
    let body: Partial<Menu> = {};
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

    const menu = await menuService.upsertMenu({
      ...(body as Omit<Menu, 'id'>),
      price: Number(body.price),
      maxSpiceLevel: Number(body.maxSpiceLevel ?? 3),
      isAvailable: body.isAvailable === true || (body.isAvailable as unknown as string) === 'true',
      ingredientIds: Array.isArray(body.ingredientIds) ? body.ingredientIds : [],
      imageUrl: imageUrl ?? (body.imageUrl as string | null) ?? null,
    });

    return NextResponse.json({ success: true, data: menu }, { status: 201 });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}
