import { NextRequest, NextResponse } from 'next/server';
import * as richMenuService from '@/lib/services/rich_menu.service';

export async function DELETE(_req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  try {
    await richMenuService.deleteRichMenu(id);
    return NextResponse.json({ success: true });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}
