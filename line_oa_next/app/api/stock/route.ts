import { NextRequest, NextResponse } from 'next/server';
import { ensureInit } from '@/lib/init';
import * as menuService from '@/lib/services/menu.service';
import { Ingredient } from '@/lib/types';

ensureInit();

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  try {
    const merchantId = req.nextUrl.searchParams.get('merchantId') ?? 'merchant-001';
    const data = await menuService.getIngredientsByMerchant(merchantId);
    return NextResponse.json({ success: true, data });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json() as Omit<Ingredient, 'id'>;
    const ingredient = await menuService.upsertIngredient(body);
    return NextResponse.json({ success: true, data: ingredient }, { status: 201 });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}
