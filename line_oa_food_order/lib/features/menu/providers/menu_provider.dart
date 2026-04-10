import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_oa_food_order/core/models/menu_model.dart';
import 'package:line_oa_food_order/core/services/api_service.dart';

final _api = ApiService();

final menuListProvider = FutureProvider<List<MenuModel>>((ref) async {
  final data = await _api.getMenus();
  return data.map((e) => MenuModel.fromJson(e as Map<String, dynamic>)).toList();
});

final menuByCategoryProvider = Provider<Map<String, List<MenuModel>>>((ref) {
  final menus = ref.watch(menuListProvider).valueOrNull ?? [];
  final map = <String, List<MenuModel>>{};
  for (final menu in menus) {
    map.putIfAbsent(menu.category, () => []).add(menu);
  }
  return map;
});
