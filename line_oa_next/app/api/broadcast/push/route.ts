import { NextRequest, NextResponse } from 'next/server';
import { env } from '@/lib/config/env';
import * as lineService from '@/lib/services/line.service';

export async function POST(req: NextRequest) {
  try {
    const { userId, flexJson } = await req.json() as { userId: string; flexJson: string };
    if (!userId || !flexJson) {
      return NextResponse.json({ code: '400', en: 'userId and flexJson required', th: 'ข้อมูลไม่ครบ' }, { status: 400 });
    }
    if (!env.line.channelAccessToken) {
      return NextResponse.json({ code: '500', en: 'LINE token not configured', th: 'ไม่มี token' }, { status: 500 });
    }
    await lineService.pushFlex(env.line.channelAccessToken, userId, JSON.parse(flexJson));
    return NextResponse.json({ success: true });
  } catch (e) {
    const msg = e instanceof Error ? e.message : 'unknown error';
    return NextResponse.json({ code: '500', en: msg, th: 'ข้อผิดพลาด' }, { status: 500 });
  }
}
