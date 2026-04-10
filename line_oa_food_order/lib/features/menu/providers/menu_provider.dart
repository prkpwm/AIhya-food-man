import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_oa_food_order/core/data/mock_data.dart';
import 'package:line_oa_food_order/core/models/menu_model.dart';

final menuListProvider = StateProvider<List<MenuModel>>((ref) => mockMenus);

final menuByCategoryProvider = Provider<Map<String, List<MenuModel>>>((ref) {
  final menus = ref.watch(menuListProvider);
  final map = <String, List<MenuModel>>{};
  for (final menu in menus) {
    map.putIfAbsent(menu.category, () => []).add(menu);
  }
  return map;
});
