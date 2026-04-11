import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_oa_food_order/core/models/order_model.dart';
import 'package:line_oa_food_order/core/services/api_service.dart';
import 'package:line_oa_food_order/features/order/providers/order_provider.dart';
import 'dart:convert';

class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(orderListProvider);
    final groupedAsync = ref.watch(groupedMenuOrdersProvider);
    final grouped = groupedAsync.valueOrNull ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (orders) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ออเดอร์', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
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
                    (_, i) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _OrderCard(order: orders[i])),
                    childCount: orders.length,
                  ),
                ),
              ),
            ],
          ),
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
                    Text('#${order.id.split('-').last}', style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
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

    final flex = {
      'type': 'flex',
      'altText': '$label #$shortId',
      'contents': {
        'type': 'bubble',
        'header': {
          'type': 'box', 'layout': 'vertical', 'backgroundColor': color, 'paddingAll': '16px',
          'contents': [
            {'type': 'text', 'text': label, 'weight': 'bold', 'size': 'lg', 'color': '#ffffff'},
            {'type': 'text', 'text': '#$shortId', 'size': 'sm', 'color': 'rgba(255,255,255,0.8)'},
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
          ],
        },
        'footer': {
          'type': 'box', 'layout': 'vertical', 'spacing': 'sm',
          'contents': [
            {'type': 'button', 'style': 'secondary', 'action': {'type': 'message', 'label': '📦 ดูสถานะ', 'text': 'สถานะ #$shortId'}},
          ],
        },
      },
    };

    // fire and forget
    ApiService().pushFlex(order.customerId, jsonEncode(flex));
  }
}
