import { NextResponse } from 'next/server';
import bcrypt from 'bcryptjs';
import { v4 as uuid } from 'uuid';
import { connectDB } from '@/lib/db/mongoose';
import { UserModel, MerchantModel, StoreSettingsModel } from '@/lib/db/models';
import { signToken } from '@/lib/auth';

export async function POST(req: Request) {
  try {
    await connectDB();
    const { email, password, name, shopName } = await req.json() as {
      email: string; password: string; name: string; shopName: string;
    };

    if (!email || !password || !name || !shopName) {
      return NextResponse.json({ code: '400', en: 'Missing fields', th: 'กรุณากรอกข้อมูลให้ครบ' }, { status: 400 });
    }

    const existing = await UserModel.findOne({ email: email.toLowerCase() });
    if (existing) {
      return NextResponse.json({ code: '409', en: 'Email already used', th: 'อีเมลนี้ถูกใช้แล้ว' }, { status: 409 });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const userId = uuid();
    const merchantId = uuid();

    await UserModel.create({ _id: userId, email: email.toLowerCase(), passwordHash, name, merchantId });
    await MerchantModel.create({ _id: merchantId, ownerId: userId, name: shopName });
    await StoreSettingsModel.findOneAndUpdate(
      { _id: merchantId },
      { $setOnInsert: { _id: merchantId, shopName } },
      { upsert: true, new: true }
    );

    const token = signToken({ userId, email: email.toLowerCase(), merchantId });
    const res = NextResponse.json({ success: true, token, merchantId, name });
    res.cookies.set('token', token, { httpOnly: true, maxAge: 60 * 60 * 24 * 7, path: '/' });
    return res;
  } catch (e) {
    console.error(e);
    return NextResponse.json({ code: '500', en: 'Server error', th: 'เกิดข้อผิดพลาด' }, { status: 500 });
  }
}
