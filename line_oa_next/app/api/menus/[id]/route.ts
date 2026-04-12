import { NextRequest, NextResponse } from 'next/server';
import { ensureInit } from '@/lib/init';
import * as menuService from '@/lib/services/menu.service';
import { env } from '@/lib/config/env';
import { Menu } from '@/lib/types';
import * as path from 'node:path';
import * as fs from 'node:fs';

ensureInit();

function baseUrl() { return env.renderExternalUrl || 'http://localhost:3000'; }

export async function GET(_req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const menu = await menuService.getMenu(id);
    if (!menu) return NextResponse.json({ code: '500', en: 'Not found', th: 'ไม่พบเมนู' }, { status: 500 });
    return NextResponse.json({ success: true, data: menu });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}

export async function PUT(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
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

    const existing = await menuService.getMenu(id);
    const menu = await menuService.upsertMenu({
      ...(body as Omit<Menu, 'id'>),
      id,
      price: Number(body.price),
      maxSpiceLevel: Number(body.maxSpiceLevel ?? 3),
      isAvailable: body.isAvailable === true || (body.isAvailable as unknown as string) === 'true',
      ingredientIds: Array.isArray(body.ingredientIds) ? body.ingredientIds : [],
      imageUrl: imageUrl ?? (body.imageUrl as string | null) ?? existing?.imageUrl ?? null,
    });

    return NextResponse.json({ success: true, data: menu });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}

export async function DELETE(_req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const deleted = await menuService.deleteMenu(id);
    if (!deleted) return NextResponse.json({ code: '500', en: 'Not found', th: 'ไม่พบเมนู' }, { status: 500 });
    return NextResponse.json({ success: true });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}
