import { NextResponse } from 'next/server';
import * as richMenuService from '@/lib/services/rich_menu.service';

export async function GET() {
  try {
    const menus = await richMenuService.listRichMenus();
    return NextResponse.json({ success: true, data: menus });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}
