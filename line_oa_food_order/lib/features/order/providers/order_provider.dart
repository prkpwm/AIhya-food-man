import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_oa_food_order/core/models/order_model.dart';
import 'package:line_oa_food_order/core/services/api_service.dart';

final _api = ApiService();

final orderListProvider = AsyncNotifierProvider<OrderNotifier, List<OrderModel>>(OrderNotifier.new);

class OrderNotifier extends AsyncNotifier<List<OrderModel>> {
  @override
  Future<List<OrderModel>> build() async {
    final data = await _api.getOrders();
    return data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateStatus(String id, OrderStatus status) async {
    await _api.updateOrderStatus(id, status.name);
    ref.invalidateSelf();
  }
}

final activeOrdersProvider = Provider<List<OrderModel>>((ref) {
  final activeStatuses = {OrderStatus.pending, OrderStatus.confirmed, OrderStatus.preparing, OrderStatus.ready};
  return (ref.watch(orderListProvider).valueOrNull ?? []).where((o) => activeStatuses.contains(o.status)).toList();
});

final groupedMenuOrdersProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return _api.getGroupedOrders();
});
