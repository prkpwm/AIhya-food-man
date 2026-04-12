var MENUS = window.__MENUS__ || [];
var cart = [];
var userId = null;
var currentMenu = null;
var sheetQty = 1;
var sheetSpice = -1;
var sheetAddons = {};
var sheetPortion = null;
var sheetNote = '';
var currentCat = 'all';
var hideSoldOut = false;

// ─── LIFF init ────────────────────────────────────────────────────────────────

// ─── Category filter ──────────────────────────────────────────────────────────

function filterCat(btn) {
  document.querySelectorAll('.cat-tab').forEach(function(t) { t.classList.remove('active'); });
  btn.classList.add('active');
  currentCat = btn.dataset.cat;
  applyFilter(document.getElementById('search-input').value);
}

function searchMenus(q) {
  applyFilter(q);
}

function applyFilter(q) {
  var query = (q || '').toLowerCase().trim();
  document.querySelectorAll('.menu-card').forEach(function(card) {
    var cat = card.dataset.category;
    var available = card.dataset.available === 'true';
    var name = card.querySelector('.menu-name').textContent.toLowerCase();
    var desc = card.querySelector('.menu-desc').textContent.toLowerCase();
    var catMatch = currentCat === 'all' || cat === currentCat;
    var searchMatch = !query || name.includes(query) || desc.includes(query);
    var soldOutHidden = hideSoldOut && !available;
    card.style.display = (catMatch && searchMatch && !soldOutHidden) ? '' : 'none';
  });
}

// ─── Menu detail sheet ────────────────────────────────────────────────────────

function openDetail(menuId) {
  currentMenu = MENUS.find(function(m) { return m.id === menuId; });
  if (!currentMenu) return;
  if (!currentMenu.isAvailable) return;
  sheetQty = 1;
  sheetSpice = currentMenu.maxSpiceLevel > 0 ? -1 : 0;
  sheetAddons = {};
  sheetPortion = (currentMenu.portionOptions && currentMenu.portionOptions.length > 0) ? null : 'none';
  sheetNote = '';
  renderSheet();
  document.getElementById('overlay').classList.add('show');
  document.getElementById('sheet').classList.add('show');
}

function closeSheet() {
  document.getElementById('overlay').classList.remove('show');
  document.getElementById('sheet').classList.remove('show');
}

function renderSheet() {
  var m = currentMenu;
  var spiceLabels = ['ไม่เผ็ด','เผ็ดน้อย','เผ็ดกลาง','เผ็ดมาก','เผ็ดมากกก'];

  var spiceHtml = '';
  if (m.maxSpiceLevel > 0) {
    var rows = '';
    for (var i = 0; i <= m.maxSpiceLevel; i++) {
      var sel = sheetSpice === i ? 'sel' : '';
      rows += '<div class="option-row" onclick="selectSpice(' + i + ')">'
        + '<div class="option-left"><div class="radio ' + sel + '"></div>'
        + '<span class="option-label">' + (spiceLabels[i] || 'เผ็ด ' + i) + '</span>'
        + '</div><span class="option-price">฿0</span></div>';
    }
    spiceHtml = '<div class="section">'
      + '<div class="section-header"><span class="section-title">ระดับความเผ็ด</span><span class="section-required">ต้องระบุ</span></div>'
      + '<div class="section-sub">กรุณาเลือก 1 ข้อ</div>' + rows + '</div>';
  }

  var addonsHtml = '';
  if (m.addons && m.addons.length > 0) {
    var arows = '';
    m.addons.forEach(function(a) {
      var asel = sheetAddons[a.id] ? 'sel' : '';
      arows += '<div class="option-row" data-addon="' + a.id + '" onclick="toggleAddon(this.dataset.addon)">'
        + '<div class="option-left"><div class="checkbox ' + asel + '"></div>'
        + '<span class="option-label">' + a.name + '</span>'
        + '</div><span class="option-price">+฿' + a.price + '</span></div>';
    });
    addonsHtml = '<div class="section">'
      + '<div class="section-header"><span class="section-title">เลือกเพิ่ม</span></div>'
      + '<div class="section-sub">เลือกได้หลายข้อ</div>' + arows + '</div>';
  }

  var portionHtml = '';
  if (m.portionOptions && m.portionOptions.length > 0) {
    var prows = '';
    m.portionOptions.forEach(function(p) {
      var psel = sheetPortion === p.id ? 'sel' : '';
      var plabel = p.extraPrice > 0 ? '+฿' + p.extraPrice : '฿0';
      prows += '<div class="option-row" data-portion="' + p.id + '" onclick="selectPortion(this.dataset.portion)">'
        + '<div class="option-left"><div class="radio ' + psel + '"></div>'
        + '<span class="option-label">' + p.name + '</span>'
        + '</div><span class="option-price">' + plabel + '</span></div>';
    });
    portionHtml = '<div class="section">'
      + '<div class="section-header"><span class="section-title">ธรรมดา / พิเศษ</span><span class="section-required">ต้องระบุ</span></div>'
      + '<div class="section-sub">กรุณาเลือก 1 ข้อ</div>' + prows + '</div>';
  }

  var heroHtml = m.imageUrl
    ? '<img class="sheet-hero" src="' + m.imageUrl + '" alt="' + m.name + '"/>'
    : '<div class="sheet-hero-placeholder">🍽️</div>';

  var total = calcTotal().toFixed(0);

  document.getElementById('sheet-content').innerHTML =
    '<div class="sheet-handle"></div>'
    + heroHtml
    + '<div class="sheet-body">'
    + '<div class="sheet-name">' + m.name + '</div>'
    + '<div class="sheet-desc">' + m.description + '</div>'
    + '<div class="sheet-price">฿' + m.price.toFixed(0) + '</div>'
    + spiceHtml + addonsHtml + portionHtml
    + '<div class="note-section"><div class="section-title">หมายเหตุ</div>'
    + '<input class="note-input" id="sheet-note" type="text" placeholder="เช่น ไม่ใส่ผัก, เพิ่มซอส..." oninput="sheetNote=this.value"/>'
    + '</div>'
    + '<div class="qty-section">'
    + '<div class="qty-ctrl">'
    + '<button class="qty-btn minus" onclick="changeSheetQty(-1)">−</button>'
    + '<span class="qty-num" id="sheet-qty">' + sheetQty + '</span>'
    + '<button class="qty-btn plus" onclick="changeSheetQty(1)">+</button>'
    + '</div>'
    + '<button class="add-cart-btn" id="add-cart-btn" onclick="addToCart()" style="width:auto;padding:14px 28px;margin:0">ใส่ตะกร้า · ฿' + total + '</button>'
    + '</div>'
    + '</div>';
  updateAddCartBtn();
}

function calcTotal() {
  var m = currentMenu;
  var price = m.price;
  if (m.portionOptions && sheetPortion) {
    var p = m.portionOptions.find(function(x) { return x.id === sheetPortion; });
    if (p) price += p.extraPrice;
  }
  if (m.addons) m.addons.forEach(function(a) { if (sheetAddons[a.id]) price += a.price; });
  return price * sheetQty;
}

function selectSpice(level) { sheetSpice = level; renderSheet(); }
function selectPortion(id) { sheetPortion = id; renderSheet(); }
function toggleAddon(id) { sheetAddons[id] = !sheetAddons[id]; renderSheet(); }

function changeSheetQty(delta) {
  sheetQty = Math.max(1, sheetQty + delta);
  document.getElementById('sheet-qty').textContent = sheetQty;
  updateAddCartBtn();
}

function updateAddCartBtn() {
  var m = currentMenu;
  if (!m) return;
  var needSpice = m.maxSpiceLevel > 0 && sheetSpice < 0;
  var needPortion = m.portionOptions && m.portionOptions.length > 0 && !sheetPortion;
  var btn = document.getElementById('add-cart-btn');
  if (!btn) return;
  var total = calcTotal().toFixed(0);
  if (needSpice) btn.textContent = 'เลือกระดับความเผ็ดก่อน';
  else if (needPortion) btn.textContent = 'เลือกธรรมดา/พิเศษก่อน';
  else btn.textContent = 'ใส่ตะกร้า · ฿' + total;
  btn.disabled = needSpice || needPortion;
}

function addToCart() {
  var m = currentMenu;
  if (!m) return;
  if (m.maxSpiceLevel > 0 && sheetSpice < 0) return;
  if (m.portionOptions && m.portionOptions.length > 0 && !sheetPortion) return;

  var selectedAddons = m.addons ? m.addons.filter(function(a) { return sheetAddons[a.id]; }) : [];
  var portionLabel = '';
  if (m.portionOptions && sheetPortion) {
    var pObj = m.portionOptions.find(function(p) { return p.id === sheetPortion; });
    if (pObj) portionLabel = pObj.name;
  }
  var addonLabel = selectedAddons.map(function(a) { return a.name; }).join(', ');
  var noteParts = [portionLabel, addonLabel, sheetNote.trim()].filter(Boolean);
  var note = noteParts.length > 0 ? noteParts.join(' · ') : null;
  var unitPrice = calcTotal() / sheetQty;

  cart.push({ menuId: m.id, menuName: m.name, quantity: sheetQty, unitPrice: unitPrice,
    spiceLevel: sheetSpice, customNote: note, imageUrl: m.imageUrl });
  closeSheet();
  updateCartBar();
  updateMenuBadges();
  showToast('เพิ่ม ' + m.name + ' ×' + sheetQty);
}

// ─── Cart bar ─────────────────────────────────────────────────────────────────

function updateCartBar() {
  var count = cart.reduce(function(s, i) { return s + i.quantity; }, 0);
  var total = cart.reduce(function(s, i) { return s + i.unitPrice * i.quantity; }, 0);
  document.getElementById('cart-count').textContent = count;
  document.getElementById('cart-total').textContent = '฿' + total.toFixed(0);
  var bar = document.getElementById('cart-bar');
  bar.style.display = count > 0 ? 'flex' : 'none';
}

function updateMenuBadges() {
  var qtyMap = {};
  cart.forEach(function(i) { qtyMap[i.menuId] = (qtyMap[i.menuId] || 0) + i.quantity; });
  MENUS.forEach(function(m) {
    var badge = document.getElementById('badge-' + m.id);
    if (!badge) return;
    var qty = qtyMap[m.id] || 0;
    badge.textContent = qty;
    badge.style.display = qty > 0 ? 'flex' : 'none';
  });
}

// ─── Cart review sheet ────────────────────────────────────────────────────────

function openCartSheet() {
  if (cart.length === 0) return;
  renderCartSheet();
  document.getElementById('cart-overlay').classList.add('show');
  document.getElementById('cart-sheet').classList.add('show');
}

function closeCartSheet() {
  document.getElementById('cart-overlay').classList.remove('show');
  document.getElementById('cart-sheet').classList.remove('show');
}

function renderCartSheet() {
  var total = cart.reduce(function(s, i) { return s + i.unitPrice * i.quantity; }, 0);
  var rows = cart.map(function(item, idx) {
    var imgHtml = item.imageUrl
      ? '<img class="cart-item-img" src="' + item.imageUrl + '" alt="' + item.menuName + '"/>'
      : '<div class="cart-item-img" style="display:flex;align-items:center;justify-content:center;font-size:24px">🍽️</div>';
    return '<div class="cart-item-row">'
      + imgHtml
      + '<div class="cart-item-info">'
      + '<div class="cart-item-name">' + item.menuName + '</div>'
      + (item.customNote ? '<div class="cart-item-note">' + item.customNote + '</div>' : '')
      + '<div class="cart-item-price">฿' + (item.unitPrice * item.quantity).toFixed(0) + '</div>'
      + '</div>'
      + '<div class="cart-item-qty">'
      + '<button class="cart-qty-btn minus" data-idx="' + idx + '" onclick="cartChangeQty(parseInt(this.dataset.idx),-1)">−</button>'
      + '<span class="cart-qty-num">' + item.quantity + '</span>'
      + '<button class="cart-qty-btn plus" data-idx="' + idx + '" onclick="cartChangeQty(parseInt(this.dataset.idx),1)">+</button>'
      + '</div>'
      + '</div>';
  }).join('');

  document.getElementById('cart-content').innerHTML =
    '<div class="sheet-handle"></div>'
    + '<div class="cart-header">🛒 รายการที่เลือก</div>'
    + rows
    + '<div class="cart-footer">'
    + '<div class="cart-total-row"><span>ยอดรวม</span><span class="cart-total-price">฿' + total.toFixed(0) + '</span></div>'
    + '<button class="cart-checkout-btn" onclick="closeCartSheet();checkout()">ยืนยันสั่งอาหาร · ฿' + total.toFixed(0) + '</button>'
    + '</div>';
}

function cartChangeQty(idx, delta) {
  if (idx < 0 || idx >= cart.length) return;
  cart[idx].quantity = Math.max(0, cart[idx].quantity + delta);
  if (cart[idx].quantity === 0) cart.splice(idx, 1);
  updateCartBar();
  updateMenuBadges();
  if (cart.length === 0) { closeCartSheet(); return; }
  renderCartSheet();
}

// ─── Checkout ─────────────────────────────────────────────────────────────────

async function checkout() {
  if (cart.length === 0) return;
  try {
    var res = await fetch('/api/order-web/confirm', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userId: userId, items: cart, merchantId: 'merchant-001' }),
    });
    var data = await res.json();
    if (!data.success) throw new Error('failed');
    cart = [];
    updateCartBar();
    updateMenuBadges();
    showToast('สั่งอาหารสำเร็จ! 🎉');
    setTimeout(function() { liff.closeWindow(); }, 1800);
  } catch(e) {
    showToast('เกิดข้อผิดพลาด กรุณาลองใหม่');
  }
}

function showToast(msg) {
  var t = document.getElementById('toast');
  t.textContent = msg;
  t.classList.add('show');
  setTimeout(function() { t.classList.remove('show'); }, 2500);
}

function toggleSoldOut() {
  hideSoldOut = !hideSoldOut;
  var btn = document.getElementById('sold-out-toggle');
  if (btn) {
    btn.textContent = hideSoldOut ? 'แสดงทั้งหมด' : 'ซ่อนเมนูหมด';
    if (hideSoldOut) btn.classList.add('hiding');
    else btn.classList.remove('hiding');
  }
  applyFilter(document.getElementById('search-input').value);
}

// ─── Page routing ─────────────────────────────────────────────────────────────

var PAGES = {
  order: renderPageOrder,
  status: renderPageStatus,
  promotion: renderPagePromotion,
  favorites: renderPageFavorites,
  cart: renderPageCart,
  contact: renderPageContact,
  payment: renderPagePayment,
};

function getCurrentPage() {
  var params = new URLSearchParams(window.location.search);
  var page = params.get('page') || 'order';
  return PAGES[page] ? page : 'order';
}

function renderPageOrder() {
  // default page — already rendered in HTML, nothing to do
}

function renderPageStatus() {
  document.body.innerHTML = buildSimplePage('📦', 'ติดตามสถานะ', renderStatusContent());
  loadOrderStatus();
}

function renderPagePromotion() {
  document.body.innerHTML = buildSimplePage('🎁', 'โปรโมชั่น', '<div class="empty-state">ยังไม่มีโปรโมชั่นในขณะนี้</div>');
}

function renderPageFavorites() {
  document.body.innerHTML = buildSimplePage('❤️', 'เมนูโปรด', renderFavoritesContent());
}

function renderPageCart() {
  document.body.innerHTML = buildSimplePage('🛒', 'ตะกร้าสินค้า', '<div class="empty-state">ตะกร้าว่างเปล่า<br/><small>กลับไปสั่งอาหารก่อนนะ</small></div>');
}

function renderPageContact() {
  document.body.innerHTML = buildSimplePage('📞', 'ติดต่อร้าน', renderContactContent());
}

function renderPagePayment() {
  var params = new URLSearchParams(window.location.search);
  var orderId = params.get('orderId') || '';
  document.body.innerHTML = buildSimplePage('💳', 'ชำระเงิน', '<div id="payment-content"><div class="loading">กำลังโหลด...</div></div>');
  loadPaymentInfo(orderId);
}

// for payment page: render immediately before liff.init completes
var _earlyPage = getCurrentPage();
if (_earlyPage === 'payment') {
  renderPagePayment();
}

function buildSimplePage(icon, title, bodyHtml) {
  return '<style>' + PAGE_CSS + '</style>'
    + '<div class="page-header"><span class="page-icon">' + icon + '</span><span class="page-title">' + title + '</span></div>'
    + '<div class="page-body">' + bodyHtml + '</div>'
    + '<div class="toast" id="toast"></div>';
}
function renderStatusContent() {
  return '<div id="status-content"><div class="loading">กำลังโหลด...</div></div>';
}

function renderFavoritesContent() {
  var favIds = JSON.parse(localStorage.getItem('fav_menus') || '[]');
  if (favIds.length === 0) return '<div class="empty-state">ยังไม่มีเมนูโปรด<br/><small>กดหัวใจที่เมนูเพื่อบันทึก</small></div>';
  var favMenus = MENUS.filter(function(m) { return favIds.includes(m.id); });
  if (favMenus.length === 0) return '<div class="empty-state">ยังไม่มีเมนูโปรด</div>';
  return '<div class="fav-grid">' + favMenus.map(function(m) {
    var img = m.imageUrl ? '<img src="' + m.imageUrl + '" alt="' + m.name + '"/>' : '<div class="no-img">🍽️</div>';
    return '<div class="fav-card">'
      + '<div class="fav-img-wrap">' + img + '</div>'
      + '<div class="fav-body"><div class="fav-name">' + m.name + '</div>'
      + '<div class="fav-price">฿' + m.price.toFixed(0) + '</div></div>'
      + '</div>';
  }).join('') + '</div>';
}

function renderContactContent() {
  return '<div class="contact-card">'
    + '<div class="contact-row"><span class="contact-icon">🏪</span><span>Alhya Food</span></div>'
    + '<div class="contact-row"><span class="contact-icon">🕐</span><span>เปิด 10:00 – 21:00 น.</span></div>'
    + '<div class="contact-row"><span class="contact-icon">📍</span><span>กรุณาติดต่อผ่าน LINE</span></div>'
    + '</div>';
}

async function loadOrderStatus() {
  if (!userId) {
    document.getElementById('status-content').innerHTML = '<div class="empty-state">กรุณาเข้าสู่ระบบ</div>';
    return;
  }
  try {
    var res = await fetch('/api/order-web/status?userId=' + encodeURIComponent(userId));
    var data = await res.json();
    if (!data.success || !data.orders || data.orders.length === 0) {
      document.getElementById('status-content').innerHTML = '<div class="empty-state">ไม่มีออเดอร์ที่กำลังดำเนินการ</div>';
      return;
    }
    var statusLabel = { confirmed: 'ยืนยันแล้ว', preparing: 'กำลังทำ', ready: 'พร้อมส่ง', completed: 'เสร็จสิ้น', cancelled: 'ยกเลิก' };
    var statusColor = { confirmed: '#2196F3', preparing: '#FF9800', ready: '#4CAF50', completed: '#9E9E9E', cancelled: '#F44336' };
    var html = data.orders.map(function(order) {
      var color = statusColor[order.status] || '#999';
      var label = statusLabel[order.status] || order.status;
      var items = (order.items || []).map(function(i) { return i.menuName + ' ×' + i.quantity; }).join(', ');
      return '<div class="order-card">'
        + '<div class="order-card-top">'
        + '<span class="order-id">#' + order.id.slice(-6) + '</span>'
        + '<span class="order-status" style="background:' + color + '">' + label + '</span>'
        + '</div>'
        + '<div class="order-items">' + items + '</div>'
        + '<div class="order-total">฿' + (order.totalAmount || 0).toFixed(0) + '</div>'
        + (order.estimatedWaitMinutes > 0 ? '<div class="order-wait">รออีก ~' + order.estimatedWaitMinutes + ' นาที</div>' : '')
        + '</div>';
    }).join('');
    document.getElementById('status-content').innerHTML = html;
  } catch(e) {
    document.getElementById('status-content').innerHTML = '<div class="empty-state">เกิดข้อผิดพลาด กรุณาลองใหม่</div>';
  }
}

async function loadPaymentInfo(orderId) {
  try {
    var settingsRes = await fetch('/api/settings?merchantId=merchant-001');
    var settingsData = await settingsRes.json();
    var s = settingsData.data || {};

    var html = '';

    // QR image at top if set
    if (s.acceptQrCode && s.qrCodeImageBase64) {
      html += '<div class="pay-qr"><img src="/api/settings/qr?merchantId=merchant-001" alt="QR Code"/></div>';
    }

    // payment methods row
    var methods = [];
    if (s.acceptQrCode) methods.push('<div class="pay-method"><span>📱</span><span>QR Code</span></div>');
    if (s.acceptCash) methods.push('<div class="pay-method"><span>💵</span><span>เงินสด</span></div>');
    if (s.acceptBankTransfer) methods.push('<div class="pay-method"><span>🏦</span><span>โอนธนาคาร</span></div>');
    if (s.acceptPromptPay) methods.push('<div class="pay-method"><span>⚡</span><span>พร้อมเพย์</span></div>');

    if (methods.length > 0) {
      html += '<div class="pay-section-title">วิธีชำระเงิน</div>';
      html += '<div class="pay-methods">' + methods.join('') + '</div>';
    }

    // bank info
    var info = [];
    if (s.bankName) info.push(['ธนาคาร', s.bankName]);
    if (s.bankAccount) info.push(['เลขบัญชี', s.bankAccount]);
    if (s.promptPayNumber) info.push(['พร้อมเพย์', s.promptPayNumber]);
    if (s.accountName) info.push(['ชื่อบัญชี', s.accountName]);

    if (info.length > 0) {
      html += '<div class="pay-info-card">';
      info.forEach(function(row) {
        html += '<div class="pay-info-row"><span class="pay-info-label">' + row[0] + '</span><span class="pay-info-value">' + row[1] + '</span></div>';
      });
      html += '</div>';
    }

    if (html === '') {
      html = '<div class="empty-state">ยังไม่ได้ตั้งค่าการชำระเงิน</div>';
    }

    document.getElementById('payment-content').innerHTML = html;
  } catch(e) {
    document.getElementById('payment-content').innerHTML = '<div class="empty-state">เกิดข้อผิดพลาด</div>';
  }
}

var PAGE_CSS = `
*{box-sizing:border-box;margin:0;padding:0;-webkit-tap-highlight-color:transparent}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;background:#f7f7f7;min-height:100vh}
.page-header{background:#fff;padding:16px;display:flex;align-items:center;gap:10px;box-shadow:0 1px 4px rgba(0,0,0,.08);position:sticky;top:0;z-index:10}
.page-icon{font-size:22px}
.page-title{font-size:18px;font-weight:700}
.page-body{padding:16px}
.empty-state{text-align:center;padding:60px 20px;color:#999;font-size:15px;line-height:1.8}
.loading{text-align:center;padding:40px;color:#999}
.order-card{background:#fff;border-radius:14px;padding:14px;margin-bottom:12px;box-shadow:0 2px 8px rgba(0,0,0,.06)}
.order-card-top{display:flex;justify-content:space-between;align-items:center;margin-bottom:8px}
.order-id{font-size:14px;font-weight:700;color:#333}
.order-status{color:#fff;font-size:12px;font-weight:700;padding:3px 10px;border-radius:50px}
.order-items{font-size:13px;color:#666;margin-bottom:6px}
.order-total{font-size:15px;font-weight:700;color:#FF6B00}
.order-wait{font-size:12px;color:#FF9800;margin-top:4px}
.fav-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px}
.fav-card{background:#fff;border-radius:14px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,.06)}
.fav-img-wrap{width:100%;aspect-ratio:4/3}
.fav-img-wrap img,.no-img{width:100%;height:100%;object-fit:cover;display:flex;align-items:center;justify-content:center;font-size:36px;background:#f0f0f0}
.fav-body{padding:10px}
.fav-name{font-size:14px;font-weight:600}
.fav-price{font-size:14px;font-weight:700;color:#FF6B00;margin-top:4px}
.contact-card{background:#fff;border-radius:14px;padding:16px;box-shadow:0 2px 8px rgba(0,0,0,.06)}
.contact-row{display:flex;align-items:center;gap:12px;padding:12px 0;border-bottom:1px solid #f5f5f5;font-size:15px}
.contact-row:last-child{border-bottom:none}
.contact-icon{font-size:20px;width:28px;text-align:center}
.toast{position:fixed;top:80px;left:50%;transform:translateX(-50%);background:#1A1A1A;color:#fff;padding:10px 20px;border-radius:50px;font-size:14px;opacity:0;transition:opacity .3s;z-index:100;white-space:nowrap;pointer-events:none}
.toast.show{opacity:1}
.pay-qr{text-align:center;margin-bottom:16px}.pay-qr img{width:100%;max-width:260px;border-radius:12px;border:1px solid #eee}
.pay-section-title{font-size:13px;font-weight:700;color:#555;margin-bottom:8px}
.pay-methods{display:flex;gap:8px;margin-bottom:16px}
.pay-method{flex:1;background:#fff;border-radius:12px;padding:12px 4px;text-align:center;box-shadow:0 2px 8px rgba(0,0,0,.06);display:flex;flex-direction:column;gap:4px;font-size:11px;color:#555}
.pay-method span:first-child{font-size:24px}
.pay-info-card{background:#fff;border-radius:14px;padding:14px;box-shadow:0 2px 8px rgba(0,0,0,.06);margin-bottom:16px}
.pay-info-row{display:flex;justify-content:space-between;padding:8px 0;border-bottom:1px solid #f5f5f5;font-size:14px}
.pay-info-row:last-child{border-bottom:none}
.pay-info-label{color:#888}
.pay-info-value{font-weight:700}
`;

async function initLiff() {
  try {
    await liff.init({ liffId: '2009771520-R2Vrj84v' });
    if (liff.isLoggedIn()) {
      var p = await liff.getProfile();
      userId = p.userId;
    } else {
      // don't redirect to login on payment page — it's view-only
      var page = getCurrentPage();
      if (page !== 'payment') { liff.login(); }
    }
  } catch(e) {}

  var page = getCurrentPage();
  if (page !== 'order') {
    PAGES[page]();
  }

  // hide loading, show app
  var loadingEl = document.getElementById('liff-loading');
  var appEl = document.getElementById('liff-app');
  if (loadingEl) loadingEl.style.display = 'none';
  if (appEl) appEl.style.display = '';
}

initLiff();
