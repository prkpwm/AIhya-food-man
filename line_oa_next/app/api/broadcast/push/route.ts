import { NextRequest, NextResponse } from 'next/server';
import { env } from '@/lib/config/env';
import * as lineService from '@/lib/services/line.service';

export async function POST(req: NextRequest) {
  const { userId, flexJson } = await req.json() as { userId: string; flexJson: string };
  if (!userId || !flexJson) return NextResponse.json({ code: '400', en: 'userId and flexJson required', th: 'ข้อมูลไม่ครบ' }, { status: 400 });
  await lineService.pushFlex(env.line.channelAccessToken, userId, JSON.parse(flexJson));
  return NextResponse.json({ success: true });
}
