import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_oa_food_order/core/models/menu_model.dart';
import 'package:line_oa_food_order/core/models/order_model.dart';
import 'package:line_oa_food_order/core/services/flex_message_generator.dart';
import 'package:line_oa_food_order/features/menu/providers/menu_provider.dart';
import 'package:line_oa_food_order/features/order/providers/order_provider.dart';

class GeneratorScreen extends ConsumerStatefulWidget {
  const GeneratorScreen({super.key});

  @override
  ConsumerState<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends ConsumerState<GeneratorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: const Text('LINE OA Generator',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tab,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF9E9E9E),
                indicator: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'เมนู'),
                  Tab(text: 'ออเดอร์'),
                  Tab(text: 'สรุป'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: const [
                  _MenuFlexTab(),
                  _OrderFlexTab(),
                  _SummaryFlexTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Menu Flex Tab ────────────────────────────────────────────────────────────

class _MenuFlexTab extends ConsumerStatefulWidget {
  const _MenuFlexTab();

  @override
  ConsumerState<_MenuFlexTab> createState() => _MenuFlexTabState();
}

class _MenuFlexTabState extends ConsumerState<_MenuFlexTab> {
  MenuModel? _selected;
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final menus = ref.watch(menuListProvider);

    final json = _selected != null
        ? FlexMessageGenerator.toJsonString(
            FlexMessageGenerator.menuCard(_selected!, quantity: _qty))
        : null;

    return _FlexLayout(
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('เลือกเมนู', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<MenuModel>(
            value: _selected,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: Colors.white,
            ),
            hint: const Text('เลือกเมนู'),
            items: menus
                .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                .toList(),
            onChanged: (v) => setState(() => _selected = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('จำนวน', style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              _QtyButton(
                onTap: () => setState(() => _qty = (_qty - 1).clamp(1, 99)),
                icon: Icons.remove,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$_qty',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              _QtyButton(
                onTap: () => setState(() => _qty++),
                icon: Icons.add,
              ),
            ],
          ),
        ],
      ),
      json: json,
    );
  }
}

// ─── Order Flex Tab ───────────────────────────────────────────────────────────

class _OrderFlexTab extends ConsumerStatefulWidget {
  const _OrderFlexTab();

  @override
  ConsumerState<_OrderFlexTab> createState() => _OrderFlexTabState();
}

class _OrderFlexTabState extends ConsumerState<_OrderFlexTab> {
  OrderModel? _selected;
  bool _isStatus = false;

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(orderListProvider);

    Map<String, dynamic>? flex;
    if (_selected != null) {
      flex = _isStatus
          ? FlexMessageGenerator.orderStatus(_selected!)
          : FlexMessageGenerator.orderConfirmation(_selected!);
    }
    final json = flex != null ? FlexMessageGenerator.toJsonString(flex) : null;

    return _FlexLayout(
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('เลือกออเดอร์', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<OrderModel>(
            value: _selected,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: Colors.white,
            ),
            hint: const Text('เลือกออเดอร์'),
            items: orders
                .map((o) => DropdownMenuItem(
                    value: o,
                    child: Text('${o.customerName} · ${o.status.displayName}')))
                .toList(),
            onChanged: (v) => setState(() => _selected = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('ประเภท', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              _TypeChip(label: 'ยืนยัน', selected: !_isStatus, onTap: () => setState(() => _isStatus = false)),
              const SizedBox(width: 8),
              _TypeChip(label: 'สถานะ', selected: _isStatus, onTap: () => setState(() => _isStatus = true)),
            ],
          ),
        ],
      ),
      json: json,
    );
  }
}

// ─── Summary Flex Tab ─────────────────────────────────────────────────────────

class _SummaryFlexTab extends ConsumerWidget {
  const _SummaryFlexTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderListProvider);
    final completed = orders.where((o) => o.status == OrderStatus.completed).toList();
    final revenue = completed.fold(0.0, (s, o) => s + o.totalPrice);

    final menuCount = <String, int>{};
    for (final o in completed) {
      for (final item in o.items) {
        menuCount[item.menuName] = (menuCount[item.menuName] ?? 0) + item.quantity;
      }
    }
    final sorted = Map.fromEntries(
        menuCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));

    final flex = FlexMessageGenerator.dailySummary(
      totalOrders: completed.length,
      totalRevenue: revenue,
      topMenus: sorted,
      date: DateTime.now(),
    );
    final json = FlexMessageGenerator.toJsonString(flex);

    return _FlexLayout(
      controls: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('สรุปรายได้วันนี้', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _InfoRow(label: 'ออเดอร์เสร็จสิ้น', value: '${completed.length} รายการ'),
          _InfoRow(label: 'รายได้รวม', value: '฿${revenue.toStringAsFixed(0)}'),
        ],
      ),
      json: json,
    );
  }
}

// ─── Shared Layout ────────────────────────────────────────────────────────────

class _FlexLayout extends StatelessWidget {
  final Widget controls;
  final String? json;

  const _FlexLayout({required this.controls, this.json});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
            ),
            child: controls,
          ),
          const SizedBox(height: 16),
          if (json != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Flex Message JSON',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: json!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('คัดลอก JSON แล้ว'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.copy, color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text('คัดลอก', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SelectableText(
                json!,
                style: const TextStyle(
                  color: Color(0xFF7ECEC4),
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.6,
                ),
              ),
            ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.code, size: 48, color: Color(0xFFE0E0E0)),
                  SizedBox(height: 12),
                  Text('เลือกข้อมูลเพื่อ generate JSON',
                      style: TextStyle(color: Color(0xFF9E9E9E))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Small widgets ────────────────────────────────────────────────────────────

class _QtyButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  const _QtyButton({required this.onTap, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF1A1A1A)),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF9E9E9E),
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            )),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
