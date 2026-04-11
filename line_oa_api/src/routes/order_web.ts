import { Router, Request, Response } from 'express';
import * as menuService from '../services/menu.service';
import * as orderService from '../services/order.service';
import { env } from '../config/env';
import { OrderItem } from '../types';

const router = Router();

const merchantId = 'merchant-001';

// ─── GET /order-web — LIFF ordering page ─────────────────────────────────────

router.get('/', (_req: Request, res: Response): void => {
  const menus = menuService.getMenusByMerchant(merchantId).filter((m) => m.isAvailable);

  const menuCards = menus.map((m) => `
    <div class="menu-card" data-id="${m.id}" data-name="${m.name}" data-price="${m.price}">
      ${m.imageUrl ? `<img src="${m.imageUrl}" alt="${m.name}" loading="lazy"/>` : '<div class="no-img">🍽️</div>'}
      <div class="menu-info">
        <div class="menu-name">${m.name}</div>
        <div class="menu-desc">${m.description}</div>
        <div class="menu-price">฿${m.price.toFixed(0)}</div>
      </div>
      <div class="qty-ctrl">
        <button class="qty-btn minus" onclick="changeQty('${m.id}', -1)">−</button>
        <span class="qty-val" id="qty-${m.id}">0</span>
        <button class="qty-btn plus" onclick="changeQty('${m.id}', 1)">+</button>
      </div>
    </div>`).join('');

  const menusJson = JSON.stringify(menus.map((m) => ({ id: m.id, name: m.name, price: m.price })));

  res.send(`<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>สั่งอาหาร</title>
  <script src="https://static.line-scdn.net/liff/edge/2/sdk.js"></script>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;background:#f5f5f5;padding-bottom:100px}
    .header{background:#fff;padding:16px 20px;border-bottom:1px solid #eee;position:sticky;top:0;z-index:10}
    .header h1{font-size:20px;font-weight:700}
    .header p{font-size:13px;color:#999;margin-top:2px}
    .menu-list{padding:12px 16px;display:flex;flex-direction:column;gap:12px}
    .menu-card{background:#fff;border-radius:16px;overflow:hidden;display:flex;align-items:center;gap:12px;padding:12px;box-shadow:0 2px 8px rgba(0,0,0,.06)}
    .menu-card img,.no-img{width:72px;height:72px;border-radius:12px;object-fit:cover;flex-shrink:0;background:#f0f0f0;display:flex;align-items:center;justify-content:center;font-size:28px}
    .menu-info{flex:1;min-width:0}
    .menu-name{font-weight:600;font-size:15px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
    .menu-desc{font-size:12px;color:#999;margin-top:2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
    .menu-price{font-size:15px;font-weight:700;color:#FF6B00;margin-top:4px}
    .qty-ctrl{display:flex;align-items:center;gap:8px;flex-shrink:0}
    .qty-btn{width:32px;height:32px;border-radius:50%;border:none;background:#f0f0f0;font-size:18px;cursor:pointer;display:flex;align-items:center;justify-content:center;font-weight:600}
    .qty-btn.plus{background:#FF6B00;color:#fff}
    .qty-val{font-size:16px;font-weight:700;min-width:20px;text-align:center}
    .footer{position:fixed;bottom:0;left:0;right:0;background:#fff;padding:16px;border-top:1px solid #eee}
    .confirm-btn{width:100%;padding:16px;background:#FF6B00;color:#fff;border:none;border-radius:50px;font-size:16px;font-weight:700;cursor:pointer}
    .confirm-btn:disabled{background:#ccc}
    .total-bar{display:flex;justify-content:space-between;align-items:center;margin-bottom:10px;font-size:14px}
    .total-amount{font-weight:700;font-size:18px;color:#FF6B00}
    .empty{text-align:center;padding:60px 20px;color:#999}
    .toast{position:fixed;top:20px;left:50%;transform:translateX(-50%);background:#1A1A1A;color:#fff;padding:10px 20px;border-radius:50px;font-size:14px;opacity:0;transition:opacity .3s;z-index:100}
    .toast.show{opacity:1}
  </style>
</head>
<body>
  <div class="header">
    <h1>🍽️ สั่งอาหาร</h1>
    <p>เลือกเมนูที่ต้องการ</p>
  </div>
  ${menus.length === 0
    ? '<div class="empty">ขณะนี้ยังไม่มีเมนูที่พร้อมให้บริการ</div>'
    : `<div class="menu-list">${menuCards}</div>`}
  <div class="footer">
    <div class="total-bar">
      <span>ยอดรวม</span>
      <span class="total-amount" id="total-display">฿0</span>
    </div>
    <button class="confirm-btn" id="confirm-btn" disabled onclick="confirmOrder()">ยืนยันการสั่ง</button>
  </div>
  <div class="toast" id="toast"></div>

  <script>
    const MENUS = ${menusJson};
    const qty = {};
    let userId = null;

    async function initLiff() {
      try {
        await liff.init({ liffId: '2009771520-R2Vrj84v' });
        if (liff.isLoggedIn()) {
          const profile = await liff.getProfile();
          userId = profile.userId;
        } else {
          liff.login();
        }
      } catch(e) {
        // LIFF init failed silently
      }
    }

    function changeQty(id, delta) {
      qty[id] = Math.max(0, (qty[id] || 0) + delta);
      document.getElementById('qty-' + id).textContent = qty[id];
      updateTotal();
    }

    function updateTotal() {
      let total = 0;
      for (const m of MENUS) {
        total += (qty[m.id] || 0) * m.price;
      }
      document.getElementById('total-display').textContent = '฿' + total.toFixed(0);
      document.getElementById('confirm-btn').disabled = total === 0;
    }

    async function confirmOrder() {
      const items = MENUS
        .filter(m => (qty[m.id] || 0) > 0)
        .map(m => ({ menuId: m.id, menuName: m.name, quantity: qty[m.id], unitPrice: m.price, spiceLevel: 2, customNote: null }));

      if (items.length === 0) return;

      const btn = document.getElementById('confirm-btn');
      btn.disabled = true;
      btn.textContent = 'กำลังส่ง...';

      try {
        // 1. create order on backend
        const res = await fetch('/order-web/confirm', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ userId, items, merchantId: '${merchantId}' }),
        });
        const data = await res.json();
        if (!data.success) throw new Error('order failed');

        const { shortId, totalPrice, estimatedWaitMinutes, paymentUrl } = data.data;

        // 2. build flex on frontend
        const itemRows = items.map(i => ({
          type: 'box', layout: 'baseline',
          contents: [
            { type: 'text', text: i.menuName + ' ×' + i.quantity, size: 'sm', color: '#555555', flex: 4 },
            { type: 'text', text: '฿' + (i.unitPrice * i.quantity).toFixed(0), align: 'end', size: 'sm', flex: 2 },
          ],
        }));

        const flex = {
          type: 'flex',
          altText: '✅ ยืนยันออเดอร์ #' + shortId + ' — ฿' + totalPrice.toFixed(0),
          contents: {
            type: 'bubble',
            header: {
              type: 'box', layout: 'vertical', backgroundColor: '#FF6B00', paddingAll: '16px',
              contents: [
                { type: 'text', text: '✅ ยืนยันออเดอร์แล้ว', weight: 'bold', size: 'lg', color: '#ffffff' },
                { type: 'text', text: '#' + shortId, size: 'sm', color: 'rgba(255,255,255,0.8)' },
              ],
            },
            body: {
              type: 'box', layout: 'vertical', spacing: 'md',
              contents: [
                { type: 'box', layout: 'vertical', margin: 'sm', contents: itemRows },
                { type: 'separator', margin: 'sm' },
                { type: 'box', layout: 'baseline', contents: [
                  { type: 'text', text: 'ยอดรวม', size: 'sm', color: '#555555', flex: 4 },
                  { type: 'text', text: '฿' + totalPrice.toFixed(0), align: 'end', size: 'lg', weight: 'bold', color: '#FF6B00', flex: 2 },
                ]},
                ...(estimatedWaitMinutes > 0 ? [{ type: 'text', text: '⏱ รอประมาณ ' + estimatedWaitMinutes + ' นาที', size: 'sm', color: '#999999' }] : []),
              ],
            },
            footer: {
              type: 'box', layout: 'vertical', spacing: 'sm',
              contents: [
                { type: 'button', style: 'primary', color: '#FF6B00', action: { type: 'uri', label: '💳 ชำระเงิน', uri: paymentUrl } },
                { type: 'button', style: 'secondary', action: { type: 'message', label: '📦 ติดตามสถานะ', text: 'สถานะ #' + shortId } },
              ],
            },
          },
        };

        // 3. push flex to LINE via backend
        await fetch('/broadcast/push', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ userId, flexJson: JSON.stringify(flex) }),
        });

        showToast('✅ สั่งอาหารสำเร็จ!');
        setTimeout(() => liff.closeWindow(), 1500);
      } catch(e) {
        showToast('เกิดข้อผิดพลาด กรุณาลองใหม่');
        btn.disabled = false;
        btn.textContent = 'ยืนยันการสั่ง';
      }
    }

    function showToast(msg) {
      const t = document.getElementById('toast');
      t.textContent = msg;
      t.classList.add('show');
      setTimeout(() => t.classList.remove('show'), 2500);
    }

    initLiff();
  </script>
</body>
</html>`);
});

// ─── POST /order-web/confirm — create order + let frontend push flex ─────────

router.post('/confirm', async (req: Request, res: Response): Promise<void> => {
  try {
    const { userId, items, merchantId: mid } = req.body as {
      userId: string;
      items: OrderItem[];
      merchantId: string;
    };

    if (!userId || !Array.isArray(items) || items.length === 0) {
      res.status(400).json({ code: '400', en: 'Missing fields', th: 'ข้อมูลไม่ครบ' });
      return;
    }

    const order = orderService.createOrder(mid ?? merchantId, userId, 'ลูกค้า LINE', items);
    const paymentUrl = `${env.renderExternalUrl}/payment?orderId=${order.id}`;

    // return order data + paymentUrl so the LIFF page builds and pushes the flex itself
    res.json({
      success: true,
      data: {
        orderId: order.id,
        shortId: order.id.slice(-6),
        totalPrice: order.totalPrice,
        estimatedWaitMinutes: order.estimatedWaitMinutes,
        items: order.items,
        paymentUrl,
      },
    });
  } catch {
    res.status(500).json({ code: '500', en: 'Internal error', th: 'ข้อผิดพลาด' });
  }
});

export default router;
