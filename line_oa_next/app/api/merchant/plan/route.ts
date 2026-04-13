import { NextResponse } from 'next/server';
import { connectDB } from '@/lib/db/mongoose';
import { MerchantModel } from '@/lib/db/models';
import { getTokenFromRequest, verifyToken } from '@/lib/auth';
import type { PlanTier } from '@/lib/types';

const PLANS: Record<PlanTier, { label: string; price: number; features: string[] }> = {
  free:     { label: 'Free',     price: 0,    features: ['รับออเดอร์', 'จัดการเมนู', 'สต็อก'] },
  silver:   { label: 'Silver',   price: 299,  features: ['ทุกอย่างใน Free', 'Rich Menu', 'รายงานยอดขาย'] },
  gold:     { label: 'Gold',     price: 599,  features: ['ทุกอย่างใน Silver', 'ส่ง Flex Message', 'แจ้งเตือน LINE'] },
  platinum: { label: 'Platinum', price: 999,  features: ['ทุกอย่างใน Gold', 'Broadcast ไม่จำกัด', 'Priority Support'] },
};

export async function GET(req: Request) {
  try {
    const token = getTokenFromRequest(req);
    if (!token) return NextResponse.json({ code: '401', en: 'Unauthorized', th: 'กรุณาเข้าสู่ระบบ' }, { status: 401 });
    const payload = verifyToken(token);
    if (!payload?.merchantId) return NextResponse.json({ code: '401', en: 'No merchant', th: 'ไม่พบร้านค้า' }, { status: 401 });

    await connectDB();
    const merchant = await MerchantModel.findById(payload.merchantId).select('plan planExpiresAt name');
    if (!merchant) return NextResponse.json({ code: '404', en: 'Merchant not found', th: 'ไม่พบร้านค้า' }, { status: 404 });

    const plan = (merchant.plan ?? 'free') as PlanTier;
    return NextResponse.json({
      success: true,
      data: {
        plan,
        planExpiresAt: merchant.planExpiresAt,
        planInfo: PLANS[plan],
        allPlans: PLANS,
      },
    });
  } catch (e) {
    console.error(e);
    return NextResponse.json({ code: '500', en: 'Server error', th: 'เกิดข้อผิดพลาด' }, { status: 500 });
  }
}

export async function PATCH(req: Request) {
  try {
    const token = getTokenFromRequest(req);
    if (!token) return NextResponse.json({ code: '401', en: 'Unauthorized', th: 'กรุณาเข้าสู่ระบบ' }, { status: 401 });
    const payload = verifyToken(token);
    if (!payload?.merchantId) return NextResponse.json({ code: '401', en: 'No merchant', th: 'ไม่พบร้านค้า' }, { status: 401 });

    const { plan } = await req.json() as { plan: PlanTier };
    if (!PLANS[plan]) return NextResponse.json({ code: '400', en: 'Invalid plan', th: 'แพ็กเกจไม่ถูกต้อง' }, { status: 400 });

    await connectDB();
    // set expiry 30 days from now
    const planExpiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    await MerchantModel.findByIdAndUpdate(payload.merchantId, { plan, planExpiresAt });

    return NextResponse.json({ success: true, plan, planExpiresAt });
  } catch (e) {
    console.error(e);
    return NextResponse.json({ code: '500', en: 'Server error', th: 'เกิดข้อผิดพลาด' }, { status: 500 });
  }
}
