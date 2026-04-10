import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_oa_food_order/core/data/mock_data.dart';
import 'package:line_oa_food_order/core/models/order_model.dart';

final orderListProvider = StateProvider<List<OrderModel>>((ref) => mockOrders);

final activeOrdersProvider = Provider<List<OrderModel>>((ref) {
  final activeStatuses = {
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.ready,
  };
  return ref.watch(orderListProvider).where((o) => activeStatuses.contains(o.status)).toList();
});

final groupedMenuOrdersProvider = Provider<Map<String, int>>((ref) {
  final active = ref.watch(activeOrdersProvider);
  final map = <String, int>{};
  for (final order in active) {
    for (final item in order.items) {
      map[item.menuName] = (map[item.menuName] ?? 0) + item.quantity;
    }
  }
  return map;
});
