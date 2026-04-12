import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_oa_food_order/core/models/menu_model.dart';
import 'package:line_oa_food_order/core/services/api_service.dart';

final _api = ApiService();

final menuListProvider = AsyncNotifierProvider<MenuNotifier, List<MenuModel>>(MenuNotifier.new);

class MenuNotifier extends AsyncNotifier<List<MenuModel>> {
  @override
  Future<List<MenuModel>> build() async {
    final data = await _api.getMenus();
    return data.map((e) => MenuModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> toggleAvailable(String id) async {
    final current = state.valueOrNull ?? [];
    final idx = current.indexWhere((m) => m.id == id);
    if (idx == -1) return;

    final menu = current[idx];
    final newAvailable = !menu.isAvailable;

    // optimistic update
    final updated = List<MenuModel>.from(current);
    updated[idx] = MenuModel(
      id: menu.id, merchantId: menu.merchantId, name: menu.name,
      description: menu.description, price: menu.price, imageUrl: menu.imageUrl,
      category: menu.category, shopType: menu.shopType, maxSpiceLevel: menu.maxSpiceLevel,
      ingredientIds: menu.ingredientIds, isAvailable: newAvailable,
      addons: menu.addons, portionOptions: menu.portionOptions,
    );
    state = AsyncData(updated);

    try {
      await _api.toggleMenuAvailable(id, newAvailable);
    } catch (_) {
      // revert on failure
      state = AsyncData(current);
      rethrow;
    }
  }
}

final menuByCategoryProvider = Provider<Map<String, List<MenuModel>>>((ref) {
  final menus = ref.watch(menuListProvider).valueOrNull ?? [];
  final map = <String, List<MenuModel>>{};
  for (final menu in menus) {
    map.putIfAbsent(menu.category, () => []).add(menu);
  }
  return map;
});
