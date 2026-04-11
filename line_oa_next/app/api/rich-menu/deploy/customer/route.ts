import { NextRequest, NextResponse } from 'next/server';
import * as richMenuService from '@/lib/services/rich_menu.service';

export async function POST(req: NextRequest) {
  try {
    const form = await req.formData();
    const shopName = form.get('shopName') as string;
    const file = form.get('image') as File | null;
    const large = form.get('large') === 'true';

    if (!shopName) return NextResponse.json({ code: '400', en: 'shopName required', th: 'ข้อมูลไม่ครบ' }, { status: 400 });
    if (!file) return NextResponse.json({ code: '400', en: 'image required', th: 'กรุณาแนบรูปภาพ' }, { status: 400 });

    const buf = Buffer.from(await file.arrayBuffer());
    const richMenuId = await richMenuService.deployCustomerMenu(shopName, buf, large);
    return NextResponse.json({ success: true, data: { richMenuId } });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}
