import { NextResponse } from 'next/server';
import { connectDB } from '@/lib/db/mongoose';
import { UserModel } from '@/lib/db/models';
import { getTokenFromRequest, verifyToken } from '@/lib/auth';

export async function GET(req: Request) {
  try {
    const token = getTokenFromRequest(req);
    if (!token) return NextResponse.json({ code: '401', en: 'Unauthorized', th: 'กรุณาเข้าสู่ระบบ' }, { status: 401 });

    const payload = verifyToken(token);
    if (!payload) return NextResponse.json({ code: '401', en: 'Invalid token', th: 'Token ไม่ถูกต้อง' }, { status: 401 });

    await connectDB();
    const user = await UserModel.findById(payload.userId).select('-passwordHash');
    if (!user) return NextResponse.json({ code: '404', en: 'User not found', th: 'ไม่พบผู้ใช้' }, { status: 404 });

    return NextResponse.json({ success: true, user: { id: user._id, email: user.email, name: user.name, merchantId: user.merchantId } });
  } catch (e) {
    console.error(e);
    return NextResponse.json({ code: '500', en: 'Server error', th: 'เกิดข้อผิดพลาด' }, { status: 500 });
  }
}
