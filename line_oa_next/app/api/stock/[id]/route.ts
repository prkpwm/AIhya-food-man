import { NextRequest, NextResponse } from 'next/server';
import { ensureInit } from '@/lib/init';
import * as menuService from '@/lib/services/menu.service';

ensureInit();

export async function PATCH(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const { quantity } = await req.json() as { quantity: number };
    const ingredient = await menuService.updateStock(id, quantity);
    if (!ingredient) return NextResponse.json({ code: '500', en: 'Not found', th: 'ไม่พบวัตถุดิบ' }, { status: 500 });
    return NextResponse.json({ success: true, data: ingredient });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}
