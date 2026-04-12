import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_oa_food_order/core/models/order_model.dart';
import 'package:line_oa_food_order/core/services/api_service.dart';

final _api = ApiService();

const _statusPriority = {
  OrderStatus.pending: 0,
  OrderStatus.confirmed: 1,
  OrderStatus.preparing: 2,
  OrderStatus.ready: 3,
  OrderStatus.completed: 4,
  OrderStatus.cancelled: 5,
};

List<OrderModel> _sorted(List<OrderModel> orders) {
  orders.sort((a, b) {
    final pa = _statusPriority[a.status] ?? 9;
    final pb = _statusPriority[b.status] ?? 9;
    if (pa != pb) return pa.compareTo(pb);
    return b.createdAt.compareTo(a.createdAt);
  });
  return orders;
}

final orderListProvider = AsyncNotifierProvider<OrderNotifier, List<OrderModel>>(OrderNotifier.new);

class OrderNotifier extends AsyncNotifier<List<OrderModel>> {
  @override
  Future<List<OrderModel>> build() => _fetch();

  Future<void> updateStatus(String id, OrderStatus status) async {
    await _api.updateOrderStatus(id, status.name);
    await _reload();
  }

  Future<void> refresh() => _reload();

  Future<void> _reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<List<OrderModel>> _fetch() async {
    final data = await _api.getOrders();
    return _sorted(data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList());
  }
}

final activeOrdersProvider = Provider<List<OrderModel>>((ref) {
  final activeStatuses = {OrderStatus.pending, OrderStatus.confirmed, OrderStatus.preparing, OrderStatus.ready};
  return (ref.watch(orderListProvider).valueOrNull ?? []).where((o) => activeStatuses.contains(o.status)).toList();
});

final groupedMenuOrdersProvider = AsyncNotifierProvider<GroupedOrdersNotifier, Map<String, dynamic>>(GroupedOrdersNotifier.new);

class GroupedOrdersNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() => ApiService().getGroupedOrders();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ApiService().getGroupedOrders());
  }
}
