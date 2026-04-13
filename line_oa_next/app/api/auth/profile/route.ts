import { NextResponse } from 'next/server';
import bcrypt from 'bcryptjs';
import { connectDB } from '@/lib/db/mongoose';
import { UserModel } from '@/lib/db/models';
import { getTokenFromRequest, verifyToken } from '@/lib/auth';

// PATCH /api/auth/profile — update name
export async function PATCH(req: Request) {
  try {
    const token = getTokenFromRequest(req);
    if (!token) return NextResponse.json({ code: '401', en: 'Unauthorized', th: 'กรุณาเข้าสู่ระบบ' }, { status: 401 });
    const payload = verifyToken(token);
    if (!payload) return NextResponse.json({ code: '401', en: 'Invalid token', th: 'Token ไม่ถูกต้อง' }, { status: 401 });

    const { name } = await req.json() as { name: string };
    if (!name?.trim()) return NextResponse.json({ code: '400', en: 'Name required', th: 'กรุณากรอกชื่อ' }, { status: 400 });

    await connectDB();
    await UserModel.findByIdAndUpdate(payload.userId, { name: name.trim() });
    return NextResponse.json({ success: true });
  } catch (e) {
    console.error(e);
    return NextResponse.json({ code: '500', en: 'Server error', th: 'เกิดข้อผิดพลาด' }, { status: 500 });
  }
}

// PUT /api/auth/profile — change password
export async function PUT(req: Request) {
  try {
    const token = getTokenFromRequest(req);
    if (!token) return NextResponse.json({ code: '401', en: 'Unauthorized', th: 'กรุณาเข้าสู่ระบบ' }, { status: 401 });
    const payload = verifyToken(token);
    if (!payload) return NextResponse.json({ code: '401', en: 'Invalid token', th: 'Token ไม่ถูกต้อง' }, { status: 401 });

    const { currentPassword, newPassword } = await req.json() as { currentPassword: string; newPassword: string };
    if (!currentPassword || !newPassword) return NextResponse.json({ code: '400', en: 'Missing fields', th: 'กรุณากรอกข้อมูลให้ครบ' }, { status: 400 });
    if (newPassword.length < 6) return NextResponse.json({ code: '400', en: 'Password too short', th: 'รหัสผ่านต้องมีอย่างน้อย 6 ตัว' }, { status: 400 });

    await connectDB();
    const user = await UserModel.findById(payload.userId);
    if (!user) return NextResponse.json({ code: '404', en: 'User not found', th: 'ไม่พบผู้ใช้' }, { status: 404 });

    const valid = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!valid) return NextResponse.json({ code: '401', en: 'Wrong current password', th: 'รหัสผ่านปัจจุบันไม่ถูกต้อง' }, { status: 401 });

    user.passwordHash = await bcrypt.hash(newPassword, 10);
    await user.save();
    return NextResponse.json({ success: true });
  } catch (e) {
    console.error(e);
    return NextResponse.json({ code: '500', en: 'Server error', th: 'เกิดข้อผิดพลาด' }, { status: 500 });
  }
}
