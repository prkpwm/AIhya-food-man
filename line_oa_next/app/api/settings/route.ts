import { NextRequest, NextResponse } from 'next/server';
import { getStoreSettings, upsertStoreSettings } from '@/lib/services/store_settings.service';
import { env } from '@/lib/config/env';
import * as path from 'node:path';
import * as fs from 'node:fs';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  try {
    const merchantId = req.nextUrl.searchParams.get('merchantId') ?? 'merchant-001';
    const data = await getStoreSettings(merchantId);
    return NextResponse.json({ success: true, data });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  try {
    const contentType = req.headers.get('content-type') ?? '';
    let body: Record<string, unknown> = {};
    let qrCodeImageUrl: string | null = null;

    if (contentType.includes('multipart/form-data')) {
      const form = await req.formData();
      body = Object.fromEntries(form.entries()) as Record<string, unknown>;
      const file = form.get('qrImage') as File | null;
      if (file) {
        const buf = Buffer.from(await file.arrayBuffer());
        const ext = path.extname(file.name) || '.jpg';
        const filename = `qr-${Date.now()}${ext}`;
        const dir = path.join(process.cwd(), 'public', 'images', 'qr');
        fs.mkdirSync(dir, { recursive: true });
        fs.writeFileSync(path.join(dir, filename), buf);
        qrCodeImageUrl = `${env.renderExternalUrl || 'http://localhost:3000'}/images/qr/${filename}`;
      }
    } else {
      body = await req.json();
    }

    const merchantId = (body.merchantId as string) ?? 'merchant-001';
    const data = await upsertStoreSettings({
      merchantId,
      shopName: body.shopName as string,
      acceptCash: body.acceptCash === true || body.acceptCash === 'true',
      acceptBankTransfer: body.acceptBankTransfer === true || body.acceptBankTransfer === 'true',
      acceptPromptPay: body.acceptPromptPay === true || body.acceptPromptPay === 'true',
      acceptQrCode: body.acceptQrCode === true || body.acceptQrCode === 'true',
      bankName: body.bankName as string,
      bankAccount: body.bankAccount as string,
      accountName: body.accountName as string,
      promptPayNumber: body.promptPayNumber as string,
      ...(qrCodeImageUrl !== null ? { qrCodeImageUrl } : {}),
    });
    return NextResponse.json({ success: true, data });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}
