import { NextRequest, NextResponse } from 'next/server';
import { ensureInit } from '@/lib/init';
import * as menuService from '@/lib/services/menu.service';
import { Ingredient } from '@/lib/types';

ensureInit();

export function GET(req: NextRequest) {
  const merchantId = req.nextUrl.searchParams.get('merchantId') ?? 'merchant-001';
  return NextResponse.json({ success: true, data: menuService.getIngredientsByMerchant(merchantId) });
}

export async function POST(req: NextRequest) {
  const body = await req.json() as Omit<Ingredient, 'id'>;
  const ingredient = menuService.upsertIngredient(body);
  return NextResponse.json({ success: true, data: ingredient }, { status: 201 });
}
