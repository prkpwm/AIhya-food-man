import { NextResponse } from 'next/server';
import { ensureInit } from '@/lib/init';
import { getMenusByMerchant } from '@/lib/services/menu.service';
import { buildOrderWebHtml } from './html';

ensureInit();

export const dynamic = 'force-dynamic';

export async function GET() {
  const menus = await getMenusByMerchant('merchant-001');
  const html = buildOrderWebHtml(menus);
  return new NextResponse(html, {
    headers: { 'Content-Type': 'text/html; charset=utf-8' },
  });
}
