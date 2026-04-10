import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_oa_food_order/core/models/ingredient_model.dart';
import 'package:line_oa_food_order/core/services/api_service.dart';

final _api = ApiService();

final ingredientListProvider = AsyncNotifierProvider<IngredientNotifier, List<IngredientModel>>(IngredientNotifier.new);

class IngredientNotifier extends AsyncNotifier<List<IngredientModel>> {
  @override
  Future<List<IngredientModel>> build() async {
    final data = await _api.getStock();
    return data.map((e) => IngredientModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateQuantity(String id, double quantity) async {
    await _api.updateStock(id, quantity);
    ref.invalidateSelf();
  }
}

final outOfStockProvider = Provider<List<IngredientModel>>((ref) {
  return (ref.watch(ingredientListProvider).valueOrNull ?? []).where((i) => !i.isAvailable).toList();
});

final lowStockProvider = Provider<List<IngredientModel>>((ref) {
  return (ref.watch(ingredientListProvider).valueOrNull ?? []).where((i) => i.isLowStock).toList();
});
