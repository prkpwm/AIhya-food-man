import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:line_oa_food_order/core/models/order_model.dart';
import 'package:line_oa_food_order/core/services/api_service.dart';
import 'package:line_oa_food_order/core/services/sse_service.dart';
import 'package:line_oa_food_order/features/order/providers/order_provider.dart';
import 'dart:convert';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  StreamSubscription<NewOrderEvent>? _sseSub;
  String _query = '';
  OrderStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSse());
  }

  @override
  void dispose() {
    _sseSub?.cancel();
    super.dispose();
  }

  void _startSse() {
    final svc = ref.read(sseServiceProvider);
    svc.connect();
    _sseSub = svc.stream.listen(_onNewOrder);
  }

  void _onNewOrder(NewOrderEvent event) {
    debugPrint('[SSE] new-order received: ${event.orderId} from ${event.customerName}');
    ref.read(orderListProvider.notifier).refresh().then((_) {
      debugPrint('[SSE] orderListProvider refreshed');
    });
    ref.read(groupedMenuOrdersProvider.notifier).refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: const Color(0xFF1A1A1A),
        leading: const Icon(Icons.notifications_active, color: Color(0xFF7ECEC4)),
        content: Text(
          '🆕 ออเดอร์ใหม่จาก ${event.customerName}  ฿${event.totalPrice.toStringAsFixed(0)}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text('ปิด', style: TextStyle(color: Color(0xFF7ECEC4))),
          ),
        ],
      ),
    );
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderListProvider);
    final groupedAsync = ref.watch(groupedMenuOrdersProvider);
    final grouped = groupedAsync.valueOrNull ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (orders) {
            final filtered = orders.where((o) {
              final matchStatus = _filterStatus == null || o.status == _filterStatus;
              final q = _query.toLowerCase();
              final matchQuery = q.isEmpty ||
                  o.customerName.toLowerCase().contains(q) ||
                  o.items.any((i) => i.menuName.toLowerCase().contains(q));
              return matchStatus && matchQuery;
            }).toList();

            return CustomScrollView(            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ออเดอร์', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      // ── search + filter row ──────────────────────────────
                      Row(children: [
                        Expanded(
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                            ),
                            child: TextField(
                              onChanged: (v) => setState(() => _query = v),
                              decoration: const InputDecoration(
                                hintText: 'ค้นหาชื่อ / เมนู...',
                                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                                prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF9E9E9E)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<OrderStatus?>(
                              value: _filterStatus,
                              hint: const Text('ทั้งหมด', style: TextStyle(fontSize: 13)),
                              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('ทั้งหมด')),
                                ...OrderStatus.values.map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s.displayName),
                                    )),
                              ],
                              onChanged: (v) => setState(() => _filterStatus = v),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      if (grouped.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ทำพร้อมกัน', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8, runSpacing: 6,
                                children: grouped.entries.map((e) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: const Color(0xFF7ECEC4), borderRadius: BorderRadius.circular(50)),
                                      child: Text('${e.key} ×${e.value}',
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                    )).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _OrderCard(order: filtered[i])),
                    childCount: filtered.length,
                  ),
                ),
              ),
            ],
          );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return const Color(0xFFFF9800);
      case OrderStatus.confirmed: return const Color(0xFF2196F3);
      case OrderStatus.preparing: return const Color(0xFF7ECEC4);
      case OrderStatus.ready: return const Color(0xFF9C27B0);
      case OrderStatus.completed: return const Color(0xFF9E9E9E);
      case OrderStatus.cancelled: return const Color(0xFFF44336);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dt = order.createdAt.toLocal();
    final dateStr = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')} '
        '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    final canReject = order.status == OrderStatus.pending || order.status == OrderStatus.confirmed;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFF5F5F5),
                    child: Text(order.customerName[2],
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                  ),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('#${order.id.split('-').last}  ·  $dateStr',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                  ]),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(order.status.displayName,
                      style: TextStyle(color: _statusColor(order.status), fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 10),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF9E9E9E), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${item.menuName} ×${item.quantity}', style: const TextStyle(fontSize: 13))),
                    if (item.spiceLevel > 0)
                      Row(children: List.generate(item.spiceLevel.clamp(0, 3),
                          (_) => const Icon(Icons.local_fire_department, size: 12, color: Colors.orange))),
                    const SizedBox(width: 8),
                    Text('฿${(item.unitPrice * item.quantity).toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
                  ]),
                )),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('ยอดรวม', style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                  Text('฿${order.totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
                Row(children: [
                  if (canReject) ...[
                    GestureDetector(
                      onTap: () => _confirmReject(context, ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF44336).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: const Color(0xFFF44336).withOpacity(0.3)),
                        ),
                        child: const Text('ปฏิเสธ',
                            style: TextStyle(color: Color(0xFFF44336), fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (order.status != OrderStatus.completed && order.status != OrderStatus.cancelled)
                    GestureDetector(
                      onTap: () async {
                        final next = _nextStatus(order.status);
                        if (next == null) return;
                        await ref.read(orderListProvider.notifier).updateStatus(order.id, next);
                        _pushStatusFlex(order, next);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(50)),
                        child: Text(_nextLabel(order.status),
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  OrderStatus? _nextStatus(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return OrderStatus.confirmed;
      case OrderStatus.confirmed: return OrderStatus.preparing;
      case OrderStatus.preparing: return OrderStatus.ready;
      case OrderStatus.ready: return OrderStatus.completed;
      default: return null;
    }
  }

  String _nextLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return 'ยืนยัน';
      case OrderStatus.confirmed: return 'เริ่มทำ';
      case OrderStatus.preparing: return 'พร้อมส่ง';
      case OrderStatus.ready: return 'เสร็จสิ้น';
      default: return '';
    }
  }

  Future<void> _confirmReject(BuildContext context, WidgetRef ref) async {
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _RejectSheet(customerName: order.customerName),
    );
    if (note == null) return; // cancelled
    await ref.read(orderListProvider.notifier).updateStatus(order.id, OrderStatus.cancelled);
    _pushRejectFlex(order, note);
  }

  void _pushStatusFlex(OrderModel order, OrderStatus newStatus) {
    final statusLabel = {
      OrderStatus.confirmed: '✅ ยืนยันออเดอร์แล้ว',
      OrderStatus.preparing: '👨‍🍳 กำลังเตรียมอาหาร',
      OrderStatus.ready: '🛵 อาหารพร้อมแล้ว',
      OrderStatus.completed: '✅ เสร็จสิ้น',
    };
    final headerColor = {
      OrderStatus.confirmed: '#2196F3',
      OrderStatus.preparing: '#FF6B00',
      OrderStatus.ready: '#9C27B0',
      OrderStatus.completed: '#4CAF50',
    };

    final label = statusLabel[newStatus] ?? newStatus.displayName;
    final color = headerColor[newStatus] ?? '#1A1A1A';
    final shortId = order.id.split('-').last;

    final itemRows = order.items.map((i) => {
      'type': 'box', 'layout': 'baseline', 'contents': [
        {'type': 'text', 'text': '${i.menuName} ×${i.quantity}', 'size': 'sm', 'color': '#555555', 'flex': 4},
        {'type': 'text', 'text': '฿${i.totalPrice.toStringAsFixed(0)}', 'align': 'end', 'size': 'sm', 'flex': 2},
      ],
    }).toList();

    if (newStatus == OrderStatus.confirmed) {
      ApiService().getOrderQueueInfo(order.id).then((info) {
        final queuePos = info['queuePosition'] as int? ?? 1;
        final waitMin = info['estimatedWaitMinutes'] as int? ?? order.estimatedWaitMinutes;
        final queueContents = [
          {'type': 'separator', 'margin': 'sm'},
          {'type': 'box', 'layout': 'horizontal', 'margin': 'sm', 'contents': [
            {'type': 'text', 'text': '🔢 คิวของคุณ', 'size': 'sm', 'color': '#555555', 'flex': 4},
            {'type': 'text', 'text': 'คิวที่ $queuePos', 'align': 'end', 'size': 'sm', 'weight': 'bold', 'color': '#2196F3', 'flex': 2},
          ]},
          {'type': 'box', 'layout': 'horizontal', 'contents': [
            {'type': 'text', 'text': '⏱ รอประมาณ', 'size': 'sm', 'color': '#555555', 'flex': 4},
            {'type': 'text', 'text': '$waitMin นาที', 'align': 'end', 'size': 'sm', 'weight': 'bold', 'color': '#FF6B00', 'flex': 2},
          ]},
        ];
        _sendFlex(order, label, color, shortId, itemRows, queueContents);
      }).catchError((_) {
        _sendFlex(order, label, color, shortId, itemRows, []);
      });
    } else if (newStatus == OrderStatus.completed) {
      _pushPaymentFlex(order);
    } else {
      _sendFlex(order, label, color, shortId, itemRows, []);
    }
  }

  void _pushPaymentFlex(OrderModel order) {
    final shortId = order.id.split('-').last;
    final total = order.totalPrice.toStringAsFixed(0);
    final itemRows = order.items.map((i) => {
      'type': 'box', 'layout': 'baseline', 'contents': [
        {'type': 'text', 'text': '${i.menuName} ×${i.quantity}', 'size': 'sm', 'color': '#555555', 'flex': 4},
        {'type': 'text', 'text': '฿${i.totalPrice.toStringAsFixed(0)}', 'align': 'end', 'size': 'sm', 'flex': 2},
      ],
    }).toList();

    final paymentUrl = 'https://liff.line.me/2009771520-R2Vrj84v?page=payment&orderId=${order.id}';

    final flex = {
      'type': 'flex',
      'altText': '✅ เสร็จสิ้น — กรุณาชำระเงิน ฿$total',
      'contents': {
        'type': 'bubble',
        'header': {
          'type': 'box', 'layout': 'vertical', 'backgroundColor': '#4CAF50', 'paddingAll': '16px',
          'contents': [
            {'type': 'text', 'text': '✅ เสร็จสิ้น', 'weight': 'bold', 'size': 'lg', 'color': '#ffffff'},
            {'type': 'text', 'text': '#$shortId', 'size': 'sm', 'color': '#ffffff'},
          ],
        },
        'body': {
          'type': 'box', 'layout': 'vertical', 'spacing': 'md',
          'contents': [
            ...itemRows,
            {'type': 'separator', 'margin': 'sm'},
            {'type': 'box', 'layout': 'baseline', 'contents': [
              {'type': 'text', 'text': 'ยอดรวม', 'size': 'sm', 'color': '#555555', 'flex': 4},
              {'type': 'text', 'text': '฿$total', 'align': 'end', 'size': 'md', 'weight': 'bold', 'color': '#FF6B00', 'flex': 2},
            ]},
          ],
        },
        'footer': {
          'type': 'box', 'layout': 'vertical', 'spacing': 'sm',
          'contents': [
            {'type': 'button', 'style': 'primary', 'color': '#FF6B00', 'action': {'type': 'uri', 'label': '💳 ชำระเงิน', 'uri': paymentUrl}},
            {'type': 'button', 'style': 'secondary', 'action': {'type': 'uri', 'label': '🍽️ สั่งอาหารอีกครั้ง', 'uri': 'https://liff.line.me/2009771520-R2Vrj84v?page=order'}},
          ],
        },
      },
    };
    ApiService().pushFlex(order.customerId, jsonEncode(flex));
  }

  void _sendFlex(OrderModel order, String label, String color, String shortId,
      List<Map<String, dynamic>> itemRows, List<Map<String, dynamic>> extraContents) {
    final flex = {
      'type': 'flex',
      'altText': '$label #$shortId',
      'contents': {
        'type': 'bubble',
        'header': {
          'type': 'box', 'layout': 'vertical', 'backgroundColor': color, 'paddingAll': '16px',
          'contents': [
            {'type': 'text', 'text': label, 'weight': 'bold', 'size': 'lg', 'color': '#ffffff'},
            {'type': 'text', 'text': '#$shortId', 'size': 'sm', 'color': '#FFFFFF'},
          ],
        },
        'body': {
          'type': 'box', 'layout': 'vertical', 'spacing': 'md',
          'contents': [
            ...itemRows,
            {'type': 'separator', 'margin': 'sm'},
            {'type': 'box', 'layout': 'baseline', 'contents': [
              {'type': 'text', 'text': 'ยอดรวม', 'size': 'sm', 'color': '#555555', 'flex': 4},
              {'type': 'text', 'text': '฿${order.totalPrice.toStringAsFixed(0)}', 'align': 'end', 'size': 'md', 'weight': 'bold', 'color': '#FF6B00', 'flex': 2},
            ]},
            ...extraContents,
          ],
        },
        'footer': {
          'type': 'box', 'layout': 'vertical', 'spacing': 'sm',
          'contents': [
            {'type': 'button', 'style': 'primary', 'color': '#FF6B00', 'action': {'type': 'uri', 'label': '📦 ดูสถานะ', 'uri': 'https://liff.line.me/2009771520-R2Vrj84v?page=status'}},
            {'type': 'button', 'style': 'secondary', 'action': {'type': 'uri', 'label': '🍽️ สั่งเพิ่ม', 'uri': 'https://liff.line.me/2009771520-R2Vrj84v?page=order'}},
          ],
        },
      },
    };
    ApiService().pushFlex(order.customerId, jsonEncode(flex));
  }

  void _pushRejectFlex(OrderModel order, String note) {
    final shortId = order.id.split('-').last;
    final reasonContents = note.isNotEmpty
        ? [
            {'type': 'separator', 'margin': 'sm'},
            {'type': 'text', 'text': '📝 เหตุผล: $note', 'size': 'sm', 'color': '#555555', 'wrap': true},
          ]
        : <Map<String, dynamic>>[];

    final flex = {
      'type': 'flex',
      'altText': '❌ ออเดอร์ถูกปฏิเสธ #$shortId',
      'contents': {
        'type': 'bubble',
        'header': {
          'type': 'box', 'layout': 'vertical', 'backgroundColor': '#F44336', 'paddingAll': '16px',
          'contents': [
            {'type': 'text', 'text': '❌ ออเดอร์ถูกปฏิเสธ', 'weight': 'bold', 'size': 'lg', 'color': '#ffffff'},
            {'type': 'text', 'text': '#$shortId', 'size': 'sm', 'color': '#FFFFFF'},
          ],
        },
        'body': {
          'type': 'box', 'layout': 'vertical', 'spacing': 'md',
          'contents': [
            {'type': 'text', 'text': 'ขออภัย ทางร้านไม่สามารถรับออเดอร์นี้ได้', 'size': 'sm', 'color': '#555555', 'wrap': true},
            ...reasonContents,
            {'type': 'text', 'text': 'กรุณาสั่งใหม่อีกครั้ง', 'size': 'sm', 'color': '#999999'},
          ],
        },
      },
    };
    ApiService().pushFlex(order.customerId, jsonEncode(flex));
  }
}

// ─── Reject Sheet ─────────────────────────────────────────────────────────────

class _RejectSheet extends StatefulWidget {
  final String customerName;
  const _RejectSheet({required this.customerName});

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  static const _reasons = [
    'วัตถุดิบหมด',
    'ร้านปิดแล้ว',
    'ยุ่งมาก รับไม่ได้',
    'สั่งผิดเมนู',
    'ราคาไม่ถูกต้อง',
    'อื่นๆ',
  ];
  String? _selected;
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String get _finalNote => _selected == 'อื่นๆ' ? _ctrl.text.trim() : (_selected ?? '');
  bool get _canConfirm => _selected != null && (_selected != 'อื่นๆ' || _ctrl.text.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ปฏิเสธออเดอร์', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('เหตุผลที่จะส่งให้ ${widget.customerName}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E))),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selected,
            hint: const Text('เลือกเหตุผล'),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => setState(() { _selected = v; _ctrl.clear(); }),
          ),
          if (_selected == 'อื่นๆ') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ระบุเหตุผล...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, null),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                child: const Text('ยกเลิก'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _canConfirm ? () => Navigator.pop(context, _finalNote) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF44336),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                child: const Text('ยืนยันปฏิเสธ', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  OrderStatus? _nextStatus(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return OrderStatus.confirmed;
      case OrderStatus.confirmed: return OrderStatus.preparing;
      case OrderStatus.preparing: return OrderStatus.ready;
      case OrderStatus.ready: return OrderStatus.completed;
      default: return null;
    }
  }

  String _nextLabel(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return 'ยืนยัน';
      case OrderStatus.confirmed: return 'เริ่มทำ';
      case OrderStatus.preparing: return 'พร้อมส่ง';
      case OrderStatus.ready: return 'เสร็จสิ้น';
      default: return '';
    }
  }
}
