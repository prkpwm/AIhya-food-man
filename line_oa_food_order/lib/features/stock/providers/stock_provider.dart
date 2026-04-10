import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_oa_food_order/core/data/mock_data.dart';
import 'package:line_oa_food_order/core/models/ingredient_model.dart';

final ingredientListProvider = StateProvider<List<IngredientModel>>((ref) => mockIngredients);

final outOfStockProvider = Provider<List<IngredientModel>>((ref) {
  return ref.watch(ingredientListProvider).where((i) => !i.isAvailable).toList();
});

final lowStockProvider = Provider<List<IngredientModel>>((ref) {
  return ref.watch(ingredientListProvider).where((i) => i.isLowStock).toList();
});
