import { NextRequest, NextResponse } from 'next/server';
import { getStoreSettings, upsertStoreSettings } from '@/lib/services/store_settings.service';

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
    let qrBase64: string | null = null;

    if (contentType.includes('multipart/form-data')) {
      const form = await req.formData();
      body = Object.fromEntries(form.entries()) as Record<string, unknown>;
      const file = form.get('qrImage') as File | null;
      if (file && file.size > 0) {
        const buf = Buffer.from(await file.arrayBuffer());
        const mime = file.type || 'image/jpeg';
        qrBase64 = `data:${mime};base64,${buf.toString('base64')}`;
      }
    } else {
      body = await req.json();
    }

    const merchantId = (body.merchantId as string) ?? 'merchant-001';
    const data = await upsertStoreSettings({
      merchantId,
      shopName: (body.shopName as string) ?? '',
      acceptCash: body.acceptCash === true || body.acceptCash === 'true',
      acceptBankTransfer: body.acceptBankTransfer === true || body.acceptBankTransfer === 'true',
      acceptPromptPay: body.acceptPromptPay === true || body.acceptPromptPay === 'true',
      acceptQrCode: body.acceptQrCode === true || body.acceptQrCode === 'true',
      bankName: (body.bankName as string) ?? '',
      bankAccount: (body.bankAccount as string) ?? '',
      accountName: (body.accountName as string) ?? '',
      promptPayNumber: (body.promptPayNumber as string) ?? '',
      vatEnabled: body.vatEnabled === true || body.vatEnabled === 'true',
      ...(qrBase64 !== null ? { qrCodeImageBase64: qrBase64, qrCodeImageUrl: null } : {}),
    });
    return NextResponse.json({ success: true, data });
  } catch (err) {
    return NextResponse.json({ code: '500', en: String(err), th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}
