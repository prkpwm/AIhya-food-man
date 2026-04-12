import { NextRequest, NextResponse } from 'next/server';
import { getStoreSettings } from '@/lib/services/store_settings.service';

export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  const merchantId = req.nextUrl.searchParams.get('merchantId') ?? 'merchant-001';
  const settings = await getStoreSettings(merchantId);
  const b64 = settings.qrCodeImageBase64;
  if (!b64) return new NextResponse('Not found', { status: 404 });

  // parse data URI
  const match = b64.match(/^data:([^;]+);base64,(.+)$/);
  if (!match) return new NextResponse('Invalid image', { status: 400 });

  const mime = match[1];
  const buf = Buffer.from(match[2], 'base64');
  return new NextResponse(buf, {
    headers: {
      'Content-Type': mime,
      'Cache-Control': 'public, max-age=3600',
    },
  });
}
