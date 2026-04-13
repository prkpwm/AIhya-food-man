import { NextResponse } from 'next/server';
import bcrypt from 'bcryptjs';
import { connectDB } from '@/lib/db/mongoose';
import { UserModel } from '@/lib/db/models';
import { signToken } from '@/lib/auth';

export async function POST(req: Request) {
  try {
    await connectDB();
    const { email, password } = await req.json() as { email: string; password: string };

    if (!email || !password) {
      return NextResponse.json({ code: '400', en: 'Missing fields', th: 'กรุณากรอกข้อมูลให้ครบ' }, { status: 400 });
    }

    const user = await UserModel.findOne({ email: email.toLowerCase() });
    if (!user) {
      return NextResponse.json({ code: '401', en: 'Invalid credentials', th: 'อีเมลหรือรหัสผ่านไม่ถูกต้อง' }, { status: 401 });
    }

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      return NextResponse.json({ code: '401', en: 'Invalid credentials', th: 'อีเมลหรือรหัสผ่านไม่ถูกต้อง' }, { status: 401 });
    }

    const token = signToken({ userId: user._id, email: user.email, merchantId: user.merchantId });
    const res = NextResponse.json({ success: true, token, merchantId: user.merchantId, name: user.name });
    res.cookies.set('token', token, { httpOnly: true, maxAge: 60 * 60 * 24 * 7, path: '/' });
    return res;
  } catch (e) {
    console.error(e);
    return NextResponse.json({ code: '500', en: 'Server error', th: 'เกิดข้อผิดพลาด' }, { status: 500 });
  }
}
