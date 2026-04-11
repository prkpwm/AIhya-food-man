import { NextResponse } from 'next/server';
import { getLogs } from '@/lib/store/logs';

export function GET() {
  const logs = getLogs();
  return NextResponse.json({ count: logs.length, logs });
}
