import { Router, Request, Response } from 'express';
import * as menuService from '../services/menu.service';
import * as orderService from '../services/order.service';
import { env } from '../config/env';
import { OrderItem } from '../types';

const router = Router();
const merchantId = 'merchant-001';

router.get('/', (_req: Request, res: Response): void => {
  const menus = menuService.getMenusByMerchant(merchantId).filter((m) => m.isAvailable);
  const menusJson = JSON.stringify(menus.map((m) => ({
    id: m.id, name: m.name, description: m.description,
    price: m.price, imageUrl: m.imageUrl, maxSpiceLevel: m.maxSpiceLevel,
  })));

  const menuCards = menus.map((m) => `
    <div class="menu-card" onclick="openDetail('${m.id}')">
      ${m.imageUrl
        ? `<img src="${m.imageUrl}" alt="${m.name}" loading="lazy"/>`
        : '<div class="no-img">🍽️</div>'}
      <div class="menu-info">
        <div class="menu-name">${m.name}</div>
        <div class="menu-desc">${m.description}</div>
        <div class="menu-price">฿${m.price.toFixed(0)}</div>
      </div>
      <div class="add-btn" onclick="event.stopPropagation();openDetail('${m.id}')">+</div>
    </div>`).join('');

  res.send(`<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1.0"/>
  <title>สั่งอาหาร</title>
  <script src="https://static.line-scdn.net/liff/edge/2/sdk.js"></script>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;background:#f5f5f5;padding-bottom:90px}
    .header{background:#fff;padding:16px 20px;border-bottom:1px solid #eee;position:sticky;top:0;z-index:10}
    .header h1{font-size:20px;font-weight:700}
    .header p{font-size:13px;color:#999;margin-top:2px}
    .menu-list{padding:12px 16px;display:flex;flex-direction:column;gap:10px}
    .menu-card{background:#fff;border-radius:16px;display:flex;align-items:center;gap:12px;padding:12px;box-shadow:0 2px 8px rgba(0,0,0,.06);cursor:pointer}
    .menu-card img,.no-img{width:72px;height:72px;border-radius:12px;object-fit:cover;flex-shrink:0;background:#f0f0f0;display:flex;align-items:center;justify-content:center;font-size:28px}
    .menu-info{flex:1;min-width:0}
    .menu-name{font-weight:600;font-size:15px}
    .menu-desc{font-size:12px;color:#999;margin-top:2px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
    .menu-price{font-size:15px;font-weight:700;color:#FF6B00;margin-top:4px}
    .add-btn{width:32px;height:32px;border-radius:50%;background:#FF6B00;color:#fff;font-size:20px;display:flex;align-items:center;justify-content:center;flex-shrink:0;cursor:pointer}
    /* bottom bar */
    .footer{position:fixed;bottom:0;left:0;right:0;background:#fff;padding:12px 16px;border-top:1px solid #eee;display:flex;align-items:center;gap:12px}
    .cart-summary{flex:1;font-size:14px;color:#555}
    .cart-count{font-weight:700;color:#FF6B00}
    .checkout-btn{padding:12px 24px;background:#FF6B00;color:#fff;border:none;border-radius:50px;font-size:15px;font-weight:700;cursor:pointer}
    .checkout-btn:disabled{background:#ccc}
    /* overlay */
    .overlay{position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:50;opacity:0;pointer-events:none;transition:opacity .25s}
    .overlay.show{opacity:1;pointer-events:all}
    /* bottom sheet */
    .sheet{position:fixed;bottom:0;left:0;right:0;background:#fff;border-radius:20px 20px 0 0;z-index:51;transform:translateY(100%);transition:transform .3s ease;max-height:90vh;overflow-y:auto}
    .sheet.show{transform:translateY(0)}
    .sheet-hero{width:100%;height:200px;object-fit:cover;border-radius:20px 20px 0 0}
    .sheet-hero-placeholder{width:100%;height:200px;background:#f0f0f0;border-radius:20px 20px 0 0;display:flex;align-items:center;justify-content:center;font-size:60px}
    .sheet-body{padding:20px}
    .sheet-name{font-size:20px;font-weight:700}
    .sheet-desc{font-size:13px;color:#999;margin-top:4px}
    .sheet-price{font-size:20px;font-weight:700;color:#FF6B00;margin-top:8px}
    .section{margin-top:20px}
    .section-title{font-size:15px;font-weight:700;margin-bottom:4px}
    .section-sub{font-size:12px;color:#999;margin-bottom:10px}
    .option-row{display:flex;align-items:center;justify-content:space-between;padding:12px 0;border-bottom:1px solid #f5f5f5;cursor:pointer}
    .option-label{font-size:14px}
    .option-price{font-size:13px;color:#999}
    .option-left{display:flex;align-items:center;gap:10px}
    .radio,.checkbox{width:20px;height:20px;border-radius:50%;border:2px solid #ddd;flex-shrink:0;display:flex;align-items:center;justify-content:center}
    .checkbox{border-radius:5px}
    .radio.sel,.checkbox.sel{border-color:#FF6B00;background:#FF6B00}
    .radio.sel::after,.checkbox.sel::after{content:'';width:8px;height:8px;background:#fff;border-radius:50%}
    .checkbox.sel::after{border-radius:2px}
    /* qty row */
    .qty-row{display:flex;align-items:center;justify-content:space-between;padding:16px 0}
    .qty-ctrl{display:flex;align-items:center;gap:16px}
    .qty-btn{width:36px;height:36px;border-radius:50%;border:1.5px solid #ddd;background:#fff;font-size:20px;cursor:pointer;display:flex;align-items:center;justify-content:center}
    .qty-num{font-size:18px;font-weight:700;min-width:24px;text-align:center}
    .add-cart-btn{width:100%;padding:16px;background:#06C755;color:#fff;border:none;border-radius:50px;font-size:16px;font-weight:700;cursor:pointer;margin-top:8px;margin-bottom:8px}
    /* toast */
    .toast{position:fixed;top:20px;left:50%;transform:translateX(-50%);background:#1A1A1A;color:#fff;padding:10px 20px;border-radius:50px;font-size:14px;opacity:0;transition:opacity .3s;z-index:100;white-space:nowrap}
    .toast.show{opacity:1}
  </style>
</head>
<body>
  <div class="header">
    <h1>🍽️ สั่งอาหาร</h1>
    <p>แตะเมนูเพื่อเลือกและปรับแต่ง</p>
  </div>
  <div class="menu-list">${menuCards}</div>
  <div class="footer">
    <div class="cart-summary">ตะกร้า: <span class="cart-count" id="cart-count">0</span> รายการ · <span id="cart-total">฿0</span></div>
    <button class="checkout-btn" id="checkout-btn" disabled onclick="checkout()">สั่งอาหาร</button>
  </div>

  <!-- overlay + sheet -->
  <div class="overlay" id="overlay" onclick="closeSheet()"></div>
  <div class="sheet" id="sheet">
    <div id="sheet-content"></div>
  </div>

  <div class="toast" id="toast"></div>

  <script>
    const MENUS = ${menusJson};
    const cart = []; // { menuId, menuName, quantity, unitPrice, spiceLevel, customNote, addons }
    let userId = null;
    let currentMenu = null;
    let sheetQty = 1;
    let sheetSpice = -1; // -1 = not selected
    let sheetAddons = new Set();

    async function initLiff() {
      try {
        await liff.init({ liffId: '2009771520-R2Vrj84v' });
        if (liff.isLoggedIn()) {
          const p = await liff.getProfile();
          userId = p.userId;
        } else { liff.login(); }
      } catch(e) {}
    }

    function openDetail(menuId) {
      currentMenu = MENUS.find(m => m.id === menuId);
      if (!currentMenu) return;
      sheetQty = 1;
      sheetSpice = currentMenu.maxSpiceLevel > 0 ? -1 : 0;
      sheetAddons = new Set();
      renderSheet();
      document.getElementById('overlay').classList.add('show');
      document.getElementById('sheet').classList.add('show');
    }

    function closeSheet() {
      document.getElementById('overlay').classList.remove('show');
      document.getElementById('sheet').classList.remove('show');
    }

    function renderSheet() {
      const m = currentMenu;
      const total = (m.price * sheetQty).toFixed(0);
      const spiceLabels = ['ไม่เผ็ด','เผ็ดน้อย','เผ็ดกลาง','เผ็ดมาก','เผ็ดมากกก'];

      let spiceHtml = '';
      if (m.maxSpiceLevel > 0) {
        let rows = '';
        for (let i = 0; i <= m.maxSpiceLevel; i++) {
          const sel = sheetSpice === i ? 'sel' : '';
          rows += '<div class="option-row" onclick="selectSpice(' + i + ')">'
            + '<div class="option-left">'
            + '<div class="radio ' + sel + '" id="spice-' + i + '"></div>'
            + '<span class="option-label">' + (spiceLabels[i] || 'เผ็ด ' + i) + '</span>'
            + '</div><span class="option-price">฿0</span></div>';
        }
        spiceHtml = '<div class="section"><div class="section-title">ระดับความเผ็ด</div>'
          + '<div class="section-sub">กรุณาเลือก 1 ข้อ · ต้องระบุ</div>' + rows + '</div>';
      }

      const heroHtml = m.imageUrl
        ? '<img class="sheet-hero" src="' + m.imageUrl + '" alt="' + m.name + '"/>'
        : '<div class="sheet-hero-placeholder">🍽️</div>';

      document.getElementById('sheet-content').innerHTML = heroHtml
        + '<div class="sheet-body">'
        + '<div class="sheet-name">' + m.name + '</div>'
        + '<div class="sheet-desc">' + m.description + '</div>'
        + '<div class="sheet-price">฿' + m.price.toFixed(0) + '</div>'
        + spiceHtml
        + '<div class="section"><div class="qty-row">'
        + '<span class="section-title">จำนวน</span>'
        + '<div class="qty-ctrl">'
        + '<button class="qty-btn" onclick="changeSheetQty(-1)">−</button>'
        + '<span class="qty-num" id="sheet-qty">' + sheetQty + '</span>'
        + '<button class="qty-btn" onclick="changeSheetQty(1)">+</button>'
        + '</div></div></div>'
        + '<button class="add-cart-btn" id="add-cart-btn" onclick="addToCart()">ใส่ตะกร้า · ฿' + total + '</button>'
        + '</div>';
      updateAddCartBtn();
    }

    function selectSpice(level) {
      sheetSpice = level;
      renderSheet();
    }

    function changeSheetQty(delta) {
      sheetQty = Math.max(1, sheetQty + delta);
      document.getElementById('sheet-qty').textContent = sheetQty;
      updateAddCartBtn();
    }

    function updateAddCartBtn() {
      const m = currentMenu;
      if (!m) return;
      const needSpice = m.maxSpiceLevel > 0 && sheetSpice < 0;
      const btn = document.getElementById('add-cart-btn');
      if (!btn) return;
      const total = (m.price * sheetQty).toFixed(0);
      btn.textContent = needSpice ? 'กรุณาเลือกระดับความเผ็ด' : 'ใส่ตะกร้า · ฿' + total;
      btn.disabled = needSpice;
      btn.style.background = needSpice ? '#ccc' : '#06C755';
    }

    function addToCart() {
      const m = currentMenu;
      if (!m) return;
      if (m.maxSpiceLevel > 0 && sheetSpice < 0) return;

      const existing = cart.find(i => i.menuId === m.id && i.spiceLevel === sheetSpice);
      if (existing) {
        existing.quantity += sheetQty;
      } else {
        cart.push({ menuId: m.id, menuName: m.name, quantity: sheetQty, unitPrice: m.price, spiceLevel: sheetSpice, customNote: null });
      }

      closeSheet();
      updateCartBar();
      showToast('✅ เพิ่ม ' + m.name + ' ×' + sheetQty + ' แล้ว');
    }

    function updateCartBar() {
      const count = cart.reduce((s, i) => s + i.quantity, 0);
      const total = cart.reduce((s, i) => s + i.unitPrice * i.quantity, 0);
      document.getElementById('cart-count').textContent = count;
      document.getElementById('cart-total').textContent = '฿' + total.toFixed(0);
      document.getElementById('checkout-btn').disabled = count === 0;
    }

    async function checkout() {
      if (cart.length === 0) return;
      const btn = document.getElementById('checkout-btn');
      btn.disabled = true;
      btn.textContent = 'กำลังส่ง...';

      try {
        const res = await fetch('/order-web/confirm', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ userId, items: cart, merchantId: '${merchantId}' }),
        });
        const data = await res.json();
        if (!data.success) throw new Error('failed');

        const { shortId, totalPrice, estimatedWaitMinutes, paymentUrl } = data.data;

        const itemRows = cart.map(i => ({
          type: 'box', layout: 'baseline',
          contents: [
            { type: 'text', text: i.menuName + ' ×' + i.quantity + (i.spiceLevel > 0 ? ' (เผ็ด '+i.spiceLevel+')' : ''), size: 'sm', color: '#555555', flex: 4 },
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
        btn.textContent = 'สั่งอาหาร';
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

// ─── POST /order-web/confirm ──────────────────────────────────────────────────

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
