import 'dart:convert';
import 'package:line_oa_food_order/core/models/menu_model.dart';
import 'package:line_oa_food_order/core/models/order_model.dart';

class FlexMessageGenerator {
  static const String _defaultImage = 'https://images.openai.com/static-rsc-4/b4C5IE7Tpv_Ep7wnqXD7HypX6DpTnb3pEI1EBW9KQgV_kR-gKYq7y8gzTU3pwsIpVi127pZ2XEtfkLNaWTk4_0AXBcPjUCLeyc99iGMV8zvD-QINZjo1uOAdsubyYvYzI4aVsfp92u9k99GAl07KHHbLbEHuS0mY8rp1lpIc7c9mvCXF51G01BWaOlM1AEI8?purpose=inline';
  static const String _accentColor = '#FF6B00';

  // ─── Menu Card ────────────────────────────────────────────────────────────

  static Map<String, dynamic> menuCard(MenuModel menu, {int quantity = 1}) {
    final total = menu.price * quantity;
    final spiceLabel = _spiceLabel(menu.maxSpiceLevel);
    final subtitle = [
      if (spiceLabel.isNotEmpty) spiceLabel,
      if (!menu.isAvailable) 'หมดชั่วคราว',
    ].join(' • ');

    return {
      'type': 'flex',
      'altText': menu.name,
      'contents': {
        'type': 'bubble',
        'hero': _heroImage(menu.imageUrl ?? _defaultImage),
        'body': {
          'type': 'box',
          'layout': 'vertical',
          'spacing': 'md',
          'contents': [
            _textBold(menu.name, size: 'xl'),
            _textColored('฿${menu.price.toStringAsFixed(0)}', color: _accentColor, size: 'lg', weight: 'bold'),
            if (subtitle.isNotEmpty)
              _textSub(subtitle),
            {'type': 'separator'},
            {
              'type': 'box',
              'layout': 'vertical',
              'margin': 'sm',
              'contents': [
                _rowBaseline('จำนวน', '$quantity'),
                _rowBaseline('รวม', '฿${total.toStringAsFixed(0)}', valueColor: '#000000'),
              ],
            },
          ],
        },
        'footer': _menuFooter(menu.name),
      },
    };
  }

  // ─── Order Confirmation ───────────────────────────────────────────────────

  static Map<String, dynamic> orderConfirmation(OrderModel order) {
    final itemRows = order.items.map((item) {
      final spice = item.spiceLevel > 0 ? ' (เผ็ด ${item.spiceLevel})' : '';
      final note = item.customNote != null ? ' · ${item.customNote}' : '';
      return _rowBaseline(
        '${item.menuName}$spice$note ×${item.quantity}',
        '฿${item.totalPrice.toStringAsFixed(0)}',
      );
    }).toList();

    return {
      'type': 'flex',
      'altText': 'ยืนยันออเดอร์ #${order.id.split('-').last}',
      'contents': {
        'type': 'bubble',
        'body': {
          'type': 'box',
          'layout': 'vertical',
          'spacing': 'md',
          'contents': [
            _textBold('ยืนยันออเดอร์', size: 'xl'),
            _textSub('#${order.id.split('-').last} · ${order.customerName}'),
            {'type': 'separator'},
            {
              'type': 'box',
              'layout': 'vertical',
              'margin': 'sm',
              'contents': [
                ...itemRows,
                {'type': 'separator', 'margin': 'sm'},
                _rowBaseline('ยอดรวม', '฿${order.totalPrice.toStringAsFixed(0)}',
                    valueColor: '#000000', valueBold: true),
              ],
            },
            if (order.estimatedWaitMinutes > 0)
              _textSub('เวลารอประมาณ ${order.estimatedWaitMinutes} นาที'),
          ],
        },
        'footer': _orderFooter(order.id.split('-').last),
      },
    };
  }

  // ─── Order Status ─────────────────────────────────────────────────────────

  static Map<String, dynamic> orderStatus(OrderModel order) {
    final statusColor = _statusColor(order.status);

    return {
      'type': 'flex',
      'altText': 'สถานะออเดอร์: ${order.status.displayName}',
      'contents': {
        'type': 'bubble',
        'body': {
          'type': 'box',
          'layout': 'vertical',
          'spacing': 'md',
          'contents': [
            _textBold('สถานะออเดอร์', size: 'lg'),
            _textSub('#${order.id.split('-').last} · ${order.customerName}'),
            {'type': 'separator'},
            {
              'type': 'box',
              'layout': 'horizontal',
              'margin': 'md',
              'contents': [
                {
                  'type': 'box',
                  'layout': 'vertical',
                  'contents': [
                    {
                      'type': 'text',
                      'text': order.status.displayName,
                      'color': statusColor,
                      'weight': 'bold',
                      'size': 'xl',
                    },
                    if (order.estimatedWaitMinutes > 0)
                      _textSub('รออีก ~${order.estimatedWaitMinutes} นาที'),
                  ],
                },
              ],
            },
          ],
        },
        'footer': {
          'type': 'box',
          'layout': 'vertical',
          'contents': [
            {
              'type': 'button',
              'style': 'secondary',
              'action': {'type': 'message', 'label': 'ดูตะกร้า', 'text': 'ดูตะกร้า'},
            },
          ],
        },
      },
    };
  }

  // ─── Daily Summary ────────────────────────────────────────────────────────

  static Map<String, dynamic> dailySummary({
    required int totalOrders,
    required double totalRevenue,
    required Map<String, int> topMenus,
    required DateTime date,
  }) {
    final topRows = topMenus.entries.take(3).map((e) => _rowBaseline(e.key, '×${e.value}')).toList();

    return {
      'type': 'flex',
      'altText': 'สรุปรายได้ประจำวัน',
      'contents': {
        'type': 'bubble',
        'body': {
          'type': 'box',
          'layout': 'vertical',
          'spacing': 'md',
          'contents': [
            _textBold('สรุปรายได้', size: 'xl'),
            _textSub('${date.day}/${date.month}/${date.year}'),
            {'type': 'separator'},
            {
              'type': 'box',
              'layout': 'vertical',
              'margin': 'sm',
              'contents': [
                _rowBaseline('ออเดอร์ทั้งหมด', '$totalOrders รายการ'),
                _rowBaseline('รายได้รวม', '฿${totalRevenue.toStringAsFixed(0)}',
                    valueColor: _accentColor, valueBold: true),
              ],
            },
            if (topRows.isNotEmpty) ...[
              {'type': 'separator'},
              _textBold('เมนูยอดนิยม', size: 'sm'),
              {
                'type': 'box',
                'layout': 'vertical',
                'margin': 'sm',
                'contents': topRows,
              },
            ],
          ],
        },
      },
    };
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static Map<String, dynamic> _heroImage(String url) => {
        'type': 'image',
        'url': url,
        'size': 'full',
        'aspectRatio': '20:13',
        'aspectMode': 'cover',
      };

  static Map<String, dynamic> _textBold(String text, {String size = 'md'}) => {
        'type': 'text',
        'text': text,
        'weight': 'bold',
        'size': size,
      };

  static Map<String, dynamic> _textColored(String text,
          {required String color, String size = 'md', String? weight}) =>
      {
        'type': 'text',
        'text': text,
        'color': color,
        'size': size,
        if (weight != null) 'weight': weight,
      };

  static Map<String, dynamic> _textSub(String text) => {
        'type': 'text',
        'text': text,
        'size': 'sm',
        'color': '#999999',
        'wrap': true,
      };

  static Map<String, dynamic> _rowBaseline(
    String label,
    String value, {
    String? valueColor,
    bool valueBold = false,
  }) =>
      {
        'type': 'box',
        'layout': 'baseline',
        'contents': [
          {'type': 'text', 'text': label, 'size': 'sm', 'color': '#555555', 'flex': 4},
          {
            'type': 'text',
            'text': value,
            'align': 'end',
            'size': 'sm',
            'flex': 2,
            if (valueColor != null) 'color': valueColor,
            if (valueBold) 'weight': 'bold',
          },
        ],
      };

  static Map<String, dynamic> _menuFooter(String menuName) => {
        'type': 'box',
        'layout': 'vertical',
        'spacing': 'sm',
        'contents': [
          {
            'type': 'button',
            'style': 'primary',
            'color': _accentColor,
            'action': {'type': 'message', 'label': 'สั่งเพิ่ม', 'text': 'เพิ่ม $menuName'},
          },
          {
            'type': 'button',
            'style': 'secondary',
            'action': {'type': 'message', 'label': 'ดูตะกร้า', 'text': 'ดูตะกร้า'},
          },
        ],
      };

  static Map<String, dynamic> _orderFooter(String orderId) => {
        'type': 'box',
        'layout': 'vertical',
        'spacing': 'sm',
        'contents': [
          {
            'type': 'button',
            'style': 'primary',
            'color': _accentColor,
            'action': {'type': 'message', 'label': 'ติดตามออเดอร์', 'text': 'สถานะ #$orderId'},
          },
          {
            'type': 'button',
            'style': 'secondary',
            'action': {'type': 'message', 'label': 'ยกเลิก', 'text': 'ยกเลิก #$orderId'},
          },
        ],
      };

  static String _spiceLabel(int level) {
    switch (level) {
      case 0: return '';
      case 1: return 'เผ็ดน้อย';
      case 2: return 'เผ็ดกลาง';
      case 3: return 'เผ็ดมาก';
      default: return 'เผ็ดมากพิเศษ';
    }
  }

  static String _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return '#FF9800';
      case OrderStatus.confirmed: return '#2196F3';
      case OrderStatus.preparing: return '#7ECEC4';
      case OrderStatus.ready: return '#9C27B0';
      case OrderStatus.completed: return '#4CAF50';
      case OrderStatus.cancelled: return '#F44336';
    }
  }

  // ─── To JSON string ───────────────────────────────────────────────────────

  static String toJsonString(Map<String, dynamic> flex) =>
      const JsonEncoder.withIndent('  ').convert(flex);
}
