var MENUS = window.__MENUS__ || [];
var cart = [];
var userId = null;
var currentMenu = null;
var sheetQty = 1;
var sheetSpice = -1;
var sheetAddons = {};
var sheetPortion = null;
var sheetNote = '';

async function initLiff() {
  try {
    await liff.init({ liffId: '2009771520-R2Vrj84v' });
    if (liff.isLoggedIn()) {
      var p = await liff.getProfile();
      userId = p.userId;
    } else { liff.login(); }
  } catch(e) {}
}

function openDetail(menuId) {
  currentMenu = MENUS.find(function(m) { return m.id === menuId; });
  if (!currentMenu) return;
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
    spiceHtml = '<div class="section"><div class="section-title">ระดับความเผ็ด</div>'
      + '<div class="section-sub">กรุณาเลือก 1 ข้อ · ต้องระบุ</div>' + rows + '</div>';
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
    addonsHtml = '<div class="section"><div class="section-title">เลือก</div>'
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
    portionHtml = '<div class="section"><div class="section-title">ธรรมดา/พิเศษ</div>'
      + '<div class="section-sub">กรุณาเลือก 1 ข้อ</div>' + prows + '</div>';
  }
  var heroHtml = m.imageUrl
    ? '<img class="sheet-hero" src="' + m.imageUrl + '" alt="' + m.name + '"/>'
    : '<div class="sheet-hero-placeholder">🍽️</div>';
  var total = calcTotal().toFixed(0);
  document.getElementById('sheet-content').innerHTML = heroHtml
    + '<div class="sheet-body">'
    + '<div class="sheet-name">' + m.name + '</div>'
    + '<div class="sheet-desc">' + m.description + '</div>'
    + '<div class="sheet-price">฿' + m.price.toFixed(0) + '</div>'
    + spiceHtml + addonsHtml + portionHtml
    + '<div class="section"><div class="section-title">หมายเหตุ</div>'
    + '<input class="note-input" id="sheet-note" type="text" placeholder="เพิ่มหมายเหตุ..." oninput="sheetNote=this.value"/>'
    + '</div>'
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
  if (needSpice) btn.textContent = 'กรุณาเลือกระดับความเผ็ด';
  else if (needPortion) btn.textContent = 'กรุณาเลือกธรรมดา/พิเศษ';
  else btn.textContent = 'ใส่ตะกร้า · ฿' + total;
  btn.disabled = needSpice || needPortion;
  btn.style.background = (needSpice || needPortion) ? '#ccc' : '#06C755';
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
  cart.push({ menuId: m.id, menuName: m.name, quantity: sheetQty, unitPrice: unitPrice, spiceLevel: sheetSpice, customNote: note });
  closeSheet();
  updateCartBar();
  showToast('เพิ่ม ' + m.name + ' x' + sheetQty + ' แล้ว');
}

function updateCartBar() {
  var count = cart.reduce(function(s, i) { return s + i.quantity; }, 0);
  var total = cart.reduce(function(s, i) { return s + i.unitPrice * i.quantity; }, 0);
  document.getElementById('cart-count').textContent = count;
  document.getElementById('cart-total').textContent = '฿' + total.toFixed(0);
  document.getElementById('checkout-btn').disabled = count === 0;
}

async function checkout() {
  if (cart.length === 0) return;
  var btn = document.getElementById('checkout-btn');
  btn.disabled = true;
  btn.textContent = 'กำลังส่ง...';
  try {
    var res = await fetch('/api/order-web/confirm', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userId: userId, items: cart, merchantId: 'merchant-001' }),
    });
    var data = await res.json();
    if (!data.success) throw new Error('failed');
    var d = data.data;
    var itemRows = cart.map(function(i) {
      var label = i.menuName + ' x' + i.quantity + (i.spiceLevel > 0 ? ' (เผ็ด ' + i.spiceLevel + ')' : '') + (i.customNote ? ' [' + i.customNote + ']' : '');
      return { type: 'box', layout: 'baseline', contents: [
        { type: 'text', text: label, size: 'sm', color: '#555555', flex: 4 },
        { type: 'text', text: '฿' + (i.unitPrice * i.quantity).toFixed(0), align: 'end', size: 'sm', flex: 2 },
      ]};
    });
    var waitText = d.estimatedWaitMinutes > 0 ? [{ type: 'text', text: '⏱ รอประมาณ ' + d.estimatedWaitMinutes + ' นาที', size: 'sm', color: '#999999' }] : [];
    var flex = {
      type: 'flex', altText: 'ยืนยันออเดอร์ #' + d.shortId + ' — ฿' + d.totalPrice.toFixed(0),
      contents: {
        type: 'bubble',
        header: { type: 'box', layout: 'vertical', backgroundColor: '#FF6B00', paddingAll: '16px', contents: [
          { type: 'text', text: 'ยืนยันออเดอร์แล้ว', weight: 'bold', size: 'lg', color: '#ffffff' },
          { type: 'text', text: '#' + d.shortId, size: 'sm', color: 'rgba(255,255,255,0.8)' },
        ]},
        body: { type: 'box', layout: 'vertical', spacing: 'md', contents: itemRows.concat([
          { type: 'separator', margin: 'sm' },
          { type: 'box', layout: 'baseline', contents: [
            { type: 'text', text: 'ยอดรวม', size: 'sm', color: '#555555', flex: 4 },
            { type: 'text', text: '฿' + d.totalPrice.toFixed(0), align: 'end', size: 'lg', weight: 'bold', color: '#FF6B00', flex: 2 },
          ]},
        ].concat(waitText))},
        footer: { type: 'box', layout: 'vertical', spacing: 'sm', contents: [
          { type: 'button', style: 'primary', color: '#FF6B00', action: { type: 'uri', label: 'ชำระเงิน', uri: d.paymentUrl } },
          { type: 'button', style: 'secondary', action: { type: 'message', label: 'ติดตามสถานะ', text: 'สถานะ #' + d.shortId } },
        ]},
      },
    };
    await fetch('/api/broadcast/push', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userId: userId, flexJson: JSON.stringify(flex) }),
    });
    showToast('สั่งอาหารสำเร็จ!');
    setTimeout(function() { liff.closeWindow(); }, 1500);
  } catch(e) {
    showToast('เกิดข้อผิดพลาด กรุณาลองใหม่');
    btn.disabled = false;
    btn.textContent = 'สั่งอาหาร';
  }
}

function showToast(msg) {
  var t = document.getElementById('toast');
  t.textContent = msg;
  t.classList.add('show');
  setTimeout(function() { t.classList.remove('show'); }, 2500);
}

initLiff();
