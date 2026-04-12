import { NextRequest, NextResponse } from 'next/server';
import { ensureInit } from '@/lib/init';
import { getMenu, upsertMenu } from '@/lib/services/menu.service';

ensureInit();

export async function PATCH(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const body = await req.json() as { isAvailable: boolean };
    const existing = getMenu(id);
    if (!existing) {
      return NextResponse.json({ code: '500', en: 'Menu not found', th: 'ไม่พบเมนู' }, { status: 500 });
    }
    const updated = upsertMenu({ ...existing, isAvailable: Boolean(body.isAvailable) });
    return NextResponse.json({ success: true, data: updated });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}
