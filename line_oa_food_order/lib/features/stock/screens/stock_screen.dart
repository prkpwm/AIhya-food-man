import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_oa_food_order/core/models/ingredient_model.dart';
import 'package:line_oa_food_order/core/services/api_service.dart';
import 'package:line_oa_food_order/features/stock/providers/stock_provider.dart';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  String _query = '';
  // null = all, false = available, true = out/low
  String _filter = 'all'; // 'all' | 'ok' | 'low' | 'out'

  @override
  Widget build(BuildContext context) {
    final ingredientsAsync = ref.watch(ingredientListProvider);
    final outOfStock = ref.watch(outOfStockProvider);
    final lowStock = ref.watch(lowStockProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: ingredientsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (ingredients) {
            final filtered = ingredients.where((ing) {
              final matchQuery = _query.isEmpty || ing.name.toLowerCase().contains(_query.toLowerCase());
              final matchFilter = switch (_filter) {
                'out' => !ing.isAvailable,
                'low' => ing.isLowStock,
                'ok'  => ing.isAvailable && !ing.isLowStock,
                _     => true,
              };
              return matchQuery && matchFilter;
            }).toList();

            return CustomScrollView(
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
                          GestureDetector(
                            onTap: () => _showAddSheet(context, ref),
                            child: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
                              ),
                              child: const Icon(Icons.add, color: Color(0xFF1A1A1A)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        _StatCard(label: 'ทั้งหมด', value: '${ingredients.length}', color: const Color(0xFF1A1A1A)),
                        const SizedBox(width: 10),
                        _StatCard(label: 'ใกล้หมด', value: '${lowStock.length}', color: const Color(0xFFFF9800)),
                        const SizedBox(width: 10),
                        _StatCard(label: 'หมดแล้ว', value: '${outOfStock.length}', color: const Color(0xFFF44336)),
                      ]),
                      const SizedBox(height: 12),
                      // ── search + filter ──────────────────────────────────
                      Row(children: [
                        Expanded(
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                            ),
                            child: TextField(
                              onChanged: (v) => setState(() => _query = v),
                              decoration: const InputDecoration(
                                hintText: 'ค้นหาวัตถุดิบ...',
                                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                                prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF9E9E9E)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _filter,
                              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                              style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('ทั้งหมด')),
                                DropdownMenuItem(value: 'ok',  child: Text('ปกติ')),
                                DropdownMenuItem(value: 'low', child: Text('ใกล้หมด')),
                                DropdownMenuItem(value: 'out', child: Text('หมดแล้ว')),
                              ],
                              onChanged: (v) => setState(() => _filter = v ?? 'all'),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 4),
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
                      child: _IngredientTile(ingredient: filtered[i]),
                    ),
                    childCount: filtered.length,
                  ),
                ),
              ),
            ],
          );
          },
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddIngredientSheet(ref: ref),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

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
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ),
    );
  }
}

// ─── Ingredient Tile ──────────────────────────────────────────────────────────

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
        leading: GestureDetector(
          onTap: () => _toggleSoldOut(context, ref, isOut),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isOut ? Icons.close_rounded : Icons.check_rounded,
              color: statusColor, size: 20,
            ),
          ),
        ),
        title: Text(ingredient.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isOut ? const Color(0xFFAAAAAA) : const Color(0xFF1A1A1A),
              decoration: isOut ? TextDecoration.lineThrough : null,
            )),
        subtitle: Text(
          isOut
              ? 'หมดแล้ว — แตะ ✓ เพื่อเปิดขาย'
              : isLow
                  ? 'ใกล้หมด · ${ingredient.quantity} ${ingredient.unit}'
                  : '${ingredient.quantity} ${ingredient.unit}',
          style: TextStyle(color: statusColor, fontSize: 12),
        ),
        trailing: GestureDetector(
          onTap: () => _showEditSheet(context, ref),
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

  Future<void> _toggleSoldOut(BuildContext context, WidgetRef ref, bool isOut) async {
    final newQty = isOut ? ingredient.lowStockThreshold + 0.1 : 0.0;
    await ref.read(ingredientListProvider.notifier).updateQuantity(ingredient.id, newQty);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isOut ? '${ingredient.name} เปิดขายแล้ว' : '${ingredient.name} ตั้งเป็นหมดแล้ว'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    final qtyCtrl = TextEditingController(text: ingredient.quantity.toString());
    final threshCtrl = TextEditingController(text: ingredient.lowStockThreshold.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          bool saving = false;
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('แก้ไข ${ingredient.name}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  // quick set buttons
                  Row(children: [
                    _QuickBtn(label: 'หมด', onTap: () => qtyCtrl.text = '0'),
                    const SizedBox(width: 8),
                    _QuickBtn(label: '+1', onTap: () {
                      final v = double.tryParse(qtyCtrl.text) ?? 0;
                      qtyCtrl.text = (v + 1).toString();
                    }),
                    const SizedBox(width: 8),
                    _QuickBtn(label: '+5', onTap: () {
                      final v = double.tryParse(qtyCtrl.text) ?? 0;
                      qtyCtrl.text = (v + 5).toString();
                    }),
                  ]),
                ]),
                const SizedBox(height: 16),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'จำนวนคงเหลือ (${ingredient.unit})',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: const Color(0xFFF5F5F5),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: threshCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'แจ้งเตือนเมื่อเหลือ (${ingredient.unit})',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: const Color(0xFFF5F5F5),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      setState(() => saving = true);
                      final newQty = double.tryParse(qtyCtrl.text) ?? ingredient.quantity;
                      await ref.read(ingredientListProvider.notifier).updateQuantity(ingredient.id, newQty);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('บันทึก'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Add Ingredient Sheet ─────────────────────────────────────────────────────

class _AddIngredientSheet extends StatefulWidget {
  final WidgetRef ref;
  const _AddIngredientSheet({required this.ref});

  @override
  State<_AddIngredientSheet> createState() => _AddIngredientSheetState();
}

class _AddIngredientSheetState extends State<_AddIngredientSheet> {
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '0');
  final _threshCtrl = TextEditingController(text: '0.5');
  String _unit = 'กก.';
  bool _loading = false;

  final _units = ['กก.', 'กรัม', 'ลิตร', 'มล.', 'ฟอง', 'ชิ้น', 'ถุง', 'กล่อง'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _threshCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ApiService().addIngredient({
        'merchantId': 'merchant-001',
        'name': _nameCtrl.text.trim(),
        'quantity': double.tryParse(_qtyCtrl.text) ?? 0,
        'unit': _unit,
        'lowStockThreshold': double.tryParse(_threshCtrl.text) ?? 0.5,
      });
      widget.ref.invalidate(ingredientListProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('เพิ่มวัตถุดิบแล้ว'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('เพิ่มวัตถุดิบ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _StockField(ctrl: _nameCtrl, label: 'ชื่อวัตถุดิบ'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _StockField(ctrl: _qtyCtrl, label: 'จำนวน', type: const TextInputType.numberWithOptions(decimal: true))),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _unit,
                  decoration: InputDecoration(
                    labelText: 'หน่วย',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: const Color(0xFFF5F5F5),
                  ),
                  items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) => setState(() => _unit = v ?? _unit),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            _StockField(ctrl: _threshCtrl, label: 'แจ้งเตือนเมื่อเหลือ', type: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('บันทึก'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small widgets ────────────────────────────────────────────────────────────

class _QuickBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _StockField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType type;
  const _StockField({required this.ctrl, required this.label, this.type = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true, fillColor: const Color(0xFFF5F5F5),
      ),
    );
  }
}
