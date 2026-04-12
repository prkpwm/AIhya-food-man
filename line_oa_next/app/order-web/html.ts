import { Menu } from '@/lib/types';

export function buildOrderWebHtml(menus: Menu[]): string {
  const categories = [...new Set(menus.map((m) => m.category))];

  const menusJson = JSON.stringify(menus.map((m) => ({
    id: m.id, name: m.name, description: m.description,
    price: m.price, imageUrl: m.imageUrl, maxSpiceLevel: m.maxSpiceLevel,
    category: m.category, addons: m.addons ?? [], portionOptions: m.portionOptions ?? [],
    isAvailable: m.isAvailable,
  })));

  const menuCards = menus.map((m) => {
    const img = m.imageUrl
      ? `<img src="${m.imageUrl}" alt="${m.name}" loading="lazy"/>`
      : '<div class="no-img">🍽️</div>';
    const soldOutOverlay = !m.isAvailable
      ? '<div class="sold-out-overlay">หมด</div>'
      : '';
    return `<div class="menu-card${!m.isAvailable ? ' sold-out' : ''}" data-menuid="${m.id}" data-category="${m.category}" data-available="${m.isAvailable}" onclick="openDetail(this.dataset.menuid)">
      <div class="menu-card-img-wrap">
        ${img}
        ${soldOutOverlay}
        <div class="menu-badge" id="badge-${m.id}" style="display:none">0</div>
      </div>
      <div class="menu-card-body">
        <div class="menu-name">${m.name}</div>
        <div class="menu-desc">${m.description}</div>
        <div class="menu-card-footer">
          <span class="menu-price">฿${m.price.toFixed(0)}</span>
          <button class="add-btn${!m.isAvailable ? ' add-btn-disabled' : ''}" data-menuid="${m.id}" onclick="event.stopPropagation();openDetail(this.dataset.menuid)" ${!m.isAvailable ? 'disabled' : ''}>+</button>
        </div>
      </div>
    </div>`;
  }).join('');

  const catTabs = categories.map((c, i) =>
    `<button class="cat-tab${i === 0 ? ' active' : ''}" data-cat="${c}" onclick="filterCat(this)">${c}</button>`
  ).join('');

  return `<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1.0"/>
  <meta name="apple-mobile-web-app-capable" content="yes"/>
  <title>สั่งอาหาร</title>
  <script src="https://static.line-scdn.net/liff/edge/2/sdk.js"></script>
  <style>${CSS}</style>
</head>
<body>
  <div id="liff-loading">
    <div class="liff-spinner"></div>
    <div class="liff-loading-text">กำลังโหลด...</div>
  </div>

  <div id="liff-app" style="display:none">
  <div class="header">
    <div class="header-top"><div class="shop-name">🍽️ สั่งอาหาร</div><button class="sold-out-toggle" id="sold-out-toggle" onclick="toggleSoldOut()">ซ่อนหมด</button></div>
    <div class="search-bar">
      <span class="search-icon">🔍</span>
      <input id="search-input" type="text" placeholder="ค้นหาเมนู..."/>
    </div>
    <div class="cat-tabs" id="cat-tabs">${catTabs}</div>
  </div>

  <div class="menu-grid" id="menu-grid">${menuCards}</div>

  <div class="cart-bar" id="cart-bar" style="display:none">
    <div class="cart-bar-left">
      <span class="cart-bar-count" id="cart-count">0</span>
      <span class="cart-bar-label">รายการ</span>
    </div>
    <div class="cart-bar-center" id="cart-total">฿0</div>
    <div class="cart-bar-right">ดูตะกร้า →</div>
  </div>

  <div class="overlay" id="overlay"></div>
  <div class="sheet" id="sheet"><div id="sheet-content"></div></div>
  <div class="overlay" id="cart-overlay"></div>
  <div class="sheet" id="cart-sheet"><div id="cart-content"></div></div>
  <div class="toast" id="toast"></div>
  </div><!-- #liff-app -->

  <script>window.__MENUS__ = ${menusJson};</script>
  <script src="/order-web-app.js"></script>
  <script>
    document.getElementById('overlay').addEventListener('click', closeSheet);
    document.getElementById('cart-overlay').addEventListener('click', closeCartSheet);
    document.getElementById('cart-bar').addEventListener('click', openCartSheet);
    document.getElementById('search-input').addEventListener('input', function() { searchMenus(this.value); });
  </script>
</body>
</html>`;
}

const CSS = `
*{box-sizing:border-box;margin:0;padding:0;-webkit-tap-highlight-color:transparent}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;background:#f7f7f7;padding-bottom:80px}
#liff-loading{position:fixed;inset:0;background:#fff;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:16px;z-index:999}
.liff-spinner{width:44px;height:44px;border:4px solid #f0f0f0;border-top-color:#FF6B00;border-radius:50%;animation:spin .7s linear infinite}
.liff-loading-text{font-size:14px;color:#999}
@keyframes spin{to{transform:rotate(360deg)}}
.header{background:#fff;position:sticky;top:0;z-index:20;box-shadow:0 1px 4px rgba(0,0,0,.08)}
.header-top{padding:14px 16px 8px;display:flex;align-items:center;gap:10px}
.shop-name{font-size:18px;font-weight:700;flex:1}
.search-bar{margin:0 16px 10px;display:flex;align-items:center;background:#f2f2f2;border-radius:12px;padding:8px 12px;gap:8px}
.search-bar input{border:none;background:transparent;font-size:14px;flex:1;outline:none}
.search-icon{font-size:14px;color:#999}
.cat-tabs{display:flex;gap:6px;padding:0 16px 12px;overflow-x:auto;scrollbar-width:none}
.cat-tabs::-webkit-scrollbar{display:none}
.cat-tab{flex-shrink:0;padding:6px 16px;border-radius:50px;border:1.5px solid #e0e0e0;background:#fff;font-size:13px;font-weight:500;cursor:pointer;color:#555;transition:all .15s}
.cat-tab.active{background:#FF6B00;border-color:#FF6B00;color:#fff;font-weight:700}
.menu-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px;padding:12px}
.menu-card{background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,.06);cursor:pointer;transition:transform .1s}
.menu-card:active{transform:scale(.97)}
.menu-card-img-wrap{position:relative;width:100%;aspect-ratio:4/3}
.menu-card-img-wrap img,.no-img{width:100%;height:100%;object-fit:cover;display:flex;align-items:center;justify-content:center;font-size:40px;background:#f0f0f0}
.menu-badge{position:absolute;top:8px;right:8px;background:#FF6B00;color:#fff;border-radius:50%;width:22px;height:22px;font-size:12px;font-weight:700;display:flex;align-items:center;justify-content:center;box-shadow:0 2px 6px rgba(255,107,0,.4)}
.menu-card-body{padding:10px}
.menu-name{font-weight:600;font-size:14px;line-height:1.3}
.menu-desc{font-size:11px;color:#999;margin-top:3px;overflow:hidden;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical}
.menu-card-footer{display:flex;align-items:center;justify-content:space-between;margin-top:8px}
.menu-price{font-size:15px;font-weight:700;color:#FF6B00}
.add-btn{width:30px;height:30px;border-radius:50%;background:#FF6B00;color:#fff;font-size:20px;border:none;display:flex;align-items:center;justify-content:center;cursor:pointer;flex-shrink:0;line-height:1}
.cart-bar{position:fixed;bottom:16px;left:16px;right:16px;background:#1A1A1A;border-radius:16px;padding:14px 18px;display:flex;align-items:center;z-index:30;cursor:pointer;box-shadow:0 4px 20px rgba(0,0,0,.25)}
.cart-bar-left{display:flex;align-items:center;gap:6px}
.cart-bar-count{background:#FF6B00;color:#fff;border-radius:50%;width:24px;height:24px;font-size:13px;font-weight:700;display:flex;align-items:center;justify-content:center}
.cart-bar-label{color:#fff;font-size:14px}
.cart-bar-center{flex:1;text-align:center;color:#fff;font-size:16px;font-weight:700}
.cart-bar-right{color:#FF6B00;font-size:13px;font-weight:600}
.overlay{position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:50;opacity:0;pointer-events:none;transition:opacity .25s}
.overlay.show{opacity:1;pointer-events:all}
.sheet{position:fixed;bottom:0;left:0;right:0;background:#fff;border-radius:20px 20px 0 0;z-index:51;transform:translateY(100%);transition:transform .3s cubic-bezier(.32,.72,0,1);max-height:92vh;overflow-y:auto}
.sheet.show{transform:translateY(0)}
.sheet-handle{width:36px;height:4px;background:#e0e0e0;border-radius:2px;margin:12px auto 0}
.sheet-hero{width:100%;aspect-ratio:4/3;object-fit:cover}
.sheet-hero-placeholder{width:100%;aspect-ratio:4/3;background:#f0f0f0;display:flex;align-items:center;justify-content:center;font-size:60px}
.sheet-body{padding:16px}
.sheet-name{font-size:20px;font-weight:700}
.sheet-desc{font-size:13px;color:#777;margin-top:4px;line-height:1.5}
.sheet-price{font-size:22px;font-weight:700;color:#FF6B00;margin-top:8px}
.section{margin-top:20px;border-top:1px solid #f0f0f0;padding-top:16px}
.section-header{display:flex;justify-content:space-between;align-items:center;margin-bottom:4px}
.section-title{font-size:15px;font-weight:700}
.section-required{background:#FF6B00;color:#fff;font-size:10px;font-weight:700;padding:2px 8px;border-radius:50px}
.section-sub{font-size:12px;color:#999;margin-bottom:10px}
.option-row{display:flex;align-items:center;justify-content:space-between;padding:12px 0;border-bottom:1px solid #f5f5f5;cursor:pointer}
.option-left{display:flex;align-items:center;gap:12px}
.option-label{font-size:14px}
.option-price{font-size:13px;color:#999}
.radio,.checkbox{width:22px;height:22px;border-radius:50%;border:2px solid #ddd;flex-shrink:0;display:flex;align-items:center;justify-content:center;transition:all .15s}
.checkbox{border-radius:6px}
.radio.sel,.checkbox.sel{border-color:#FF6B00;background:#FF6B00}
.radio.sel::after{content:"";width:8px;height:8px;background:#fff;border-radius:50%}
.checkbox.sel::after{content:"✓";color:#fff;font-size:13px;font-weight:700}
.note-section{margin-top:16px}
.note-input{width:100%;padding:12px 14px;border:1.5px solid #eee;border-radius:12px;font-size:14px;outline:none;background:#fafafa;margin-top:6px}
.note-input:focus{border-color:#FF6B00}
.qty-section{display:flex;align-items:center;justify-content:space-between;margin-top:20px;padding-top:16px;border-top:1px solid #f0f0f0}
.qty-ctrl{display:flex;align-items:center;gap:16px}
.qty-btn{width:36px;height:36px;border-radius:50%;border:1.5px solid #ddd;background:#fff;font-size:20px;cursor:pointer;display:flex;align-items:center;justify-content:center;font-weight:600}
.qty-btn.minus{color:#FF6B00;border-color:#FF6B00}
.qty-btn.plus{background:#FF6B00;color:#fff;border-color:#FF6B00}
.qty-num{font-size:18px;font-weight:700;min-width:28px;text-align:center}
.add-cart-btn{width:100%;padding:16px;background:#FF6B00;color:#fff;border:none;border-radius:14px;font-size:16px;font-weight:700;cursor:pointer;margin-top:16px;margin-bottom:8px;transition:opacity .15s}
.add-cart-btn:disabled{opacity:.4}
.cart-header{padding:16px;border-bottom:1px solid #f0f0f0;font-size:18px;font-weight:700}
.cart-item-row{display:flex;align-items:center;gap:12px;padding:14px 16px;border-bottom:1px solid #f5f5f5}
.cart-item-img{width:56px;height:56px;border-radius:10px;object-fit:cover;background:#f0f0f0;flex-shrink:0}
.cart-item-info{flex:1;min-width:0}
.cart-item-name{font-size:14px;font-weight:600}
.cart-item-note{font-size:12px;color:#999;margin-top:2px}
.cart-item-price{font-size:14px;font-weight:700;color:#FF6B00;margin-top:4px}
.cart-item-qty{display:flex;align-items:center;gap:8px;flex-shrink:0}
.cart-qty-btn{width:28px;height:28px;border-radius:50%;border:1.5px solid #ddd;background:#fff;font-size:16px;cursor:pointer;display:flex;align-items:center;justify-content:center;font-weight:600}
.cart-qty-btn.minus{color:#FF6B00;border-color:#FF6B00}
.cart-qty-btn.plus{background:#FF6B00;color:#fff;border-color:#FF6B00}
.cart-qty-num{font-size:14px;font-weight:700;min-width:20px;text-align:center}
.cart-footer{padding:16px;border-top:2px solid #f0f0f0}
.cart-total-row{display:flex;justify-content:space-between;margin-bottom:14px;font-size:16px;font-weight:700}
.cart-total-price{color:#FF6B00;font-size:20px}
.cart-checkout-btn{width:100%;padding:16px;background:#FF6B00;color:#fff;border:none;border-radius:14px;font-size:16px;font-weight:700;cursor:pointer}
.toast{position:fixed;top:80px;left:50%;transform:translateX(-50%);background:#1A1A1A;color:#fff;padding:10px 20px;border-radius:50px;font-size:14px;opacity:0;transition:opacity .3s;z-index:100;white-space:nowrap;pointer-events:none}
.toast.show{opacity:1}
.sold-out-overlay{position:absolute;inset:0;background:rgba(0,0,0,.55);display:flex;align-items:center;justify-content:center;color:#fff;font-size:16px;font-weight:700;border-radius:0;letter-spacing:.5px}
.menu-card.sold-out{opacity:.75}
.add-btn-disabled{background:#ccc !important;cursor:not-allowed !important}
.sold-out-toggle{font-size:12px;font-weight:600;padding:5px 12px;border-radius:50px;border:1.5px solid #e0e0e0;background:#fff;color:#555;cursor:pointer;flex-shrink:0}
.sold-out-toggle.hiding{background:#1A1A1A;border-color:#1A1A1A;color:#fff}
`;
