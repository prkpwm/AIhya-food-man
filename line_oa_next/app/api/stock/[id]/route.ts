import { NextRequest, NextResponse } from 'next/server';
import { ensureInit } from '@/lib/init';
import * as menuService from '@/lib/services/menu.service';

ensureInit();

export async function PATCH(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const { quantity } = await req.json() as { quantity: number };
  const ingredient = menuService.updateStock(id, quantity);
  if (!ingredient) return NextResponse.json({ code: '404', en: 'Not found', th: 'ไม่พบวัตถุดิบ' }, { status: 404 });
  return NextResponse.json({ success: true, data: ingredient });
}
