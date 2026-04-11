import { ensureInit } from '@/lib/init';
import { getMenusByMerchant } from '@/lib/services/menu.service';

ensureInit();

const CSS = `
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;background:#f5f5f5;padding-bottom:90px}
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
.footer{position:fixed;bottom:0;left:0;right:0;background:#fff;padding:12px 16px;border-top:1px solid #eee;display:flex;align-items:center;gap:12px}
.cart-summary{flex:1;font-size:14px;color:#555}
.cart-count{font-weight:700;color:#FF6B00}
.checkout-btn{padding:12px 24px;background:#FF6B00;color:#fff;border:none;border-radius:50px;font-size:15px;font-weight:700;cursor:pointer}
.checkout-btn:disabled{background:#ccc}
.overlay{position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:50;opacity:0;pointer-events:none;transition:opacity .25s}
.overlay.show{opacity:1;pointer-events:all}
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
.radio.sel::after{content:"";width:8px;height:8px;background:#fff;border-radius:50%}
.checkbox.sel::after{content:"✓";color:#fff;font-size:13px;font-weight:700}
.qty-row{display:flex;align-items:center;justify-content:space-between;padding:16px 0}
.qty-ctrl{display:flex;align-items:center;gap:16px}
.qty-btn{width:36px;height:36px;border-radius:50%;border:1.5px solid #ddd;background:#fff;font-size:20px;cursor:pointer;display:flex;align-items:center;justify-content:center}
.qty-num{font-size:18px;font-weight:700;min-width:24px;text-align:center}
.add-cart-btn{width:100%;padding:16px;background:#06C755;color:#fff;border:none;border-radius:50px;font-size:16px;font-weight:700;cursor:pointer;margin-top:8px;margin-bottom:8px}
.note-input{width:100%;padding:10px 14px;border:1.5px solid #eee;border-radius:12px;font-size:14px;margin-top:8px;outline:none;background:#fafafa}
.note-input:focus{border-color:#FF6B00}
.toast{position:fixed;top:20px;left:50%;transform:translateX(-50%);background:#1A1A1A;color:#fff;padding:10px 20px;border-radius:50px;font-size:14px;opacity:0;transition:opacity .3s;z-index:100;white-space:nowrap}
.toast.show{opacity:1}
`;

export default function OrderWebPage() {
  const menus = getMenusByMerchant('merchant-001').filter((m) => m.isAvailable);
  const menusJson = JSON.stringify(menus.map((m) => ({
    id: m.id, name: m.name, description: m.description,
    price: m.price, imageUrl: m.imageUrl, maxSpiceLevel: m.maxSpiceLevel,
    addons: m.addons ?? [], portionOptions: m.portionOptions ?? [],
  })));

  const menuCards = menus.map((m) => (
    `<div class="menu-card" data-menuid="${m.id}" onclick="openDetail(this.dataset.menuid)">
      ${m.imageUrl ? `<img src="${m.imageUrl}" alt="${m.name}" loading="lazy"/>` : '<div class="no-img">🍽️</div>'}
      <div class="menu-info">
        <div class="menu-name">${m.name}</div>
        <div class="menu-desc">${m.description}</div>
        <div class="menu-price">฿${m.price.toFixed(0)}</div>
      </div>
      <div class="add-btn" data-menuid="${m.id}" onclick="event.stopPropagation();openDetail(this.dataset.menuid)">+</div>
    </div>`
  )).join('');

  return (
    <html lang="th">
      <head>
        <meta charSet="UTF-8" />
        <meta name="viewport" content="width=device-width,initial-scale=1.0" />
        <title>สั่งอาหาร</title>
        {/* eslint-disable-next-line @next/next/no-sync-scripts */}
        <script src="https://static.line-scdn.net/liff/edge/2/sdk.js" />
        <style dangerouslySetInnerHTML={{ __html: CSS }} />
      </head>
      <body>
        <div className="header">
          <h1>🍽️ สั่งอาหาร</h1>
          <p>แตะเมนูเพื่อเลือกและปรับแต่ง</p>
        </div>
        <div className="menu-list" dangerouslySetInnerHTML={{ __html: menuCards }} />
        <div className="footer">
          <div className="cart-summary">
            ตะกร้า: <span className="cart-count" id="cart-count">0</span> รายการ · <span id="cart-total">฿0</span>
          </div>
          <button className="checkout-btn" id="checkout-btn" disabled onClick={() => {}} >สั่งอาหาร</button>
        </div>
        <div className="overlay" id="overlay" onClick={() => {}} />
        <div className="sheet" id="sheet">
          <div id="sheet-content" />
        </div>
        <div className="toast" id="toast" />
        <script dangerouslySetInnerHTML={{ __html: `window.__MENUS__ = ${menusJson};` }} />
        <script src="/order-web-app.js" />
      </body>
    </html>
  );
}
