import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_oa_food_order/core/models/ingredient_model.dart';
import 'package:line_oa_food_order/features/stock/providers/stock_provider.dart';

class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredients = ref.watch(ingredientListProvider);
    final outOfStock = ref.watch(outOfStockProvider);
    final lowStock = ref.watch(lowStockProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('จัดการสต๊อก',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add, color: Color(0xFF1A1A1A)),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // stat cards
                    Row(
                      children: [
                        _StatCard(label: 'ทั้งหมด', value: '${ingredients.length}', color: const Color(0xFF1A1A1A)),
                        const SizedBox(width: 10),
                        _StatCard(label: 'ใกล้หมด', value: '${lowStock.length}', color: const Color(0xFFFF9800)),
                        const SizedBox(width: 10),
                        _StatCard(label: 'หมดแล้ว', value: '${outOfStock.length}', color: const Color(0xFFF44336)),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _IngredientTile(ingredient: ingredients[i]),
                  ),
                  childCount: ingredients.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _IngredientTile extends ConsumerWidget {
  final IngredientModel ingredient;
  const _IngredientTile({required this.ingredient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOut = !ingredient.isAvailable;
    final isLow = ingredient.isLowStock;
    final statusColor = isOut
        ? const Color(0xFFF44336)
        : isLow
            ? const Color(0xFFFF9800)
            : const Color(0xFF7ECEC4);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isOut ? Icons.close_rounded : Icons.check_rounded,
            color: statusColor,
            size: 20,
          ),
        ),
        title: Text(ingredient.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          isOut
              ? 'หมดแล้ว'
              : isLow
                  ? 'ใกล้หมด · ${ingredient.quantity} ${ingredient.unit}'
                  : '${ingredient.quantity} ${ingredient.unit}',
          style: TextStyle(color: statusColor, fontSize: 12),
        ),
        trailing: GestureDetector(
          onTap: () => _showEditDialog(context, ref),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1A1A1A)),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: ingredient.quantity.toString());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('แก้ไข ${ingredient.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'จำนวน (${ingredient.unit})',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final newQty = double.tryParse(ctrl.text) ?? ingredient.quantity;
                  final list = ref.read(ingredientListProvider);
                  ref.read(ingredientListProvider.notifier).state = list
                      .map((i) => i.id == ingredient.id
                          ? IngredientModel(
                              id: i.id, name: i.name, quantity: newQty,
                              unit: i.unit, lowStockThreshold: i.lowStockThreshold)
                          : i)
                      .toList();
                  Navigator.pop(context);
                },
                child: const Text('บันทึก'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
