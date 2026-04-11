import { NextRequest, NextResponse } from 'next/server';
import { env } from '@/lib/config/env';
import * as lineService from '@/lib/services/line.service';

export async function POST(req: NextRequest) {
  const { flexJson } = await req.json() as { flexJson: string };
  if (!flexJson) return NextResponse.json({ code: '400', en: 'flexJson required', th: 'ข้อมูลไม่ครบ' }, { status: 400 });
  await lineService.broadcastFlex(env.line.channelAccessToken, JSON.parse(flexJson));
  return NextResponse.json({ success: true });
}
