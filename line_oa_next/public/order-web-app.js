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

async function initLiff() {
  try {
    await liff.init({ liffId: '2009771520-R2Vrj84v' });
    if (liff.isLoggedIn()) {
      var p = await liff.getProfile();
      userId = p.userId;
    } else { liff.login(); }
  } catch(e) {}
}

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

initLiff();
