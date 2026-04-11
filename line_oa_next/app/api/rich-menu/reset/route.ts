import { NextResponse } from 'next/server';
import * as richMenuService from '@/lib/services/rich_menu.service';
import sharp from 'sharp';

// DELETE all existing menus then redeploy customer menu with a generated image
export async function POST() {
  try {
    // delete all existing menus
    const existing = await richMenuService.listRichMenus();
    await Promise.all(existing.map((m) => richMenuService.deleteRichMenu(m.richMenuId)));

    // generate a simple solid-color image (2500x843)
    const W = 2500;
    const H = 843;
    const imgBuf = await sharp({
      create: { width: W, height: H, channels: 3, background: { r: 28, g: 28, b: 30 } },
    })
      .jpeg({ quality: 85 })
      .toBuffer();

    const richMenuId = await richMenuService.deployCustomerMenu('Alhya Food', imgBuf, false);
    return NextResponse.json({ success: true, data: { richMenuId } });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}
