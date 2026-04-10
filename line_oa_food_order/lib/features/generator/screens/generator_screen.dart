import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_oa_food_order/core/models/menu_model.dart';
import 'package:line_oa_food_order/core/models/order_model.dart';
import 'package:line_oa_food_order/core/services/api_service.dart';
import 'package:line_oa_food_order/core/services/flex_message_generator.dart';
import 'package:line_oa_food_order/features/generator/screens/rich_menu_screen.dart';
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
    _tab = TabController(length: 4, vsync: this);
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
                  Tab(text: 'Rich Menu'),
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
                  RichMenuScreen(),
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
    final menus = ref.watch(menuListProvider).valueOrNull ?? [];

    final flexData = _selected != null
        ? FlexMessageGenerator.menuCard(_selected!, quantity: _qty)
        : null;
    final json = flexData != null ? FlexMessageGenerator.toJsonString(flexData) : null;

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
      flexData: flexData,
    );
  }
}

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
    final orders = ref.watch(orderListProvider).valueOrNull ?? [];

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
      flexData: flex,
    );
  }
}

// ─── Summary Flex Tab ─────────────────────────────────────────────────────────

class _SummaryFlexTab extends ConsumerWidget {
  const _SummaryFlexTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderListProvider).valueOrNull ?? [];
    final completed = orders.where((o) => o.status == OrderStatus.completed).toList();
    final revenue = completed.fold(0.0, (s, o) => s + o.totalPrice);

    final menuCount = <String, int>{};
    for (final o in completed) {
      for (final item in o.items) {
        menuCount[item.menuName] = (menuCount[item.menuName] ?? 0) + item.quantity as int;
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
      flexData: flex,
    );
  }
}

// ─── Shared Layout ────────────────────────────────────────────────────────────

class _FlexLayout extends StatefulWidget {
  final Widget controls;
  final String? json;
  final Map<String, dynamic>? flexData;

  const _FlexLayout({required this.controls, this.json, this.flexData});

  @override
  State<_FlexLayout> createState() => _FlexLayoutState();
}

class _FlexLayoutState extends State<_FlexLayout> {
  bool _showPreview = true;
  bool _launching = false;

  Future<void> _launch() async {
    if (widget.json == null) return;
    setState(() => _launching = true);
    try {
      await ApiService().broadcastFlex(widget.json!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ส่ง Flex Message แล้ว'),
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
      if (mounted) setState(() => _launching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // controls card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
            ),
            child: widget.controls,
          ),
          const SizedBox(height: 16),

          if (widget.json != null) ...[
            // ── toolbar ──────────────────────────────────────────────────────
            Row(
              children: [
                // toggle preview / json
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    _ToggleBtn(label: 'Preview', selected: _showPreview, onTap: () => setState(() => _showPreview = true)),
                    _ToggleBtn(label: 'JSON', selected: !_showPreview, onTap: () => setState(() => _showPreview = false)),
                  ]),
                ),
                const Spacer(),
                // copy
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.json!));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('คัดลอก JSON แล้ว'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: const Row(children: [
                      Icon(Icons.copy, size: 14, color: Color(0xFF1A1A1A)),
                      SizedBox(width: 4),
                      Text('คัดลอก', style: TextStyle(fontSize: 12)),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                // launch
                GestureDetector(
                  onTap: _launching ? null : _launch,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06C755),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _launching
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Row(children: [
                            Icon(Icons.send, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Launch', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                          ]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── preview or json ───────────────────────────────────────────────
            if (_showPreview && widget.flexData != null)
              _FlexPreview(flexData: widget.flexData!)
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
                child: SelectableText(
                  widget.json!,
                  style: const TextStyle(color: Color(0xFF7ECEC4), fontFamily: 'monospace', fontSize: 11, height: 1.6),
                ),
              ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const Column(children: [
                Icon(Icons.code, size: 48, color: Color(0xFFE0E0E0)),
                SizedBox(height: 12),
                Text('เลือกข้อมูลเพื่อ generate JSON', style: TextStyle(color: Color(0xFF9E9E9E))),
              ]),
            ),
        ],
      ),
    );
  }
}

// ─── Flex Preview ─────────────────────────────────────────────────────────────

class _FlexPreview extends StatelessWidget {
  final Map<String, dynamic> flexData;
  const _FlexPreview({required this.flexData});

  @override
  Widget build(BuildContext context) {
    final contents = flexData['contents'] as Map<String, dynamic>?;
    final hero = contents?['hero'] as Map<String, dynamic>?;
    final body = contents?['body'] as Map<String, dynamic>?;
    final footer = contents?['footer'] as Map<String, dynamic>?;
    final bodyContents = body?['contents'] as List<dynamic>? ?? [];
    final footerContents = footer?['contents'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // hero image
          if (hero != null && hero['url'] != null)
            AspectRatio(
              aspectRatio: 20 / 13,
              child: Image.network(hero['url'] as String, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF0F0F0),
                      child: const Center(child: Icon(Icons.image, size: 40, color: Color(0xFFE0E0E0))))),
            ),
          // body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: bodyContents.map((item) => _renderItem(item as Map<String, dynamic>)).toList(),
            ),
          ),
          // footer buttons
          if (footerContents.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: footerContents.map((btn) {
                  final b = btn as Map<String, dynamic>;
                  final isPrimary = b['style'] == 'primary';
                  final label = (b['action'] as Map<String, dynamic>?)?['label'] as String? ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPrimary
                              ? Color(int.parse('0xFF${(b['color'] as String? ?? '#FF6B00').replaceFirst('#', '')}'))
                              : const Color(0xFFF5F5F5),
                          foregroundColor: isPrimary ? Colors.white : const Color(0xFF1A1A1A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(label),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _renderItem(Map<String, dynamic> item) {
    final type = item['type'] as String?;
    if (type == 'text') {
      final text = item['text'] as String? ?? '';
      final weight = item['weight'] as String?;
      final size = item['size'] as String?;
      final color = item['color'] as String?;
      final wrap = item['wrap'] as bool? ?? false;
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          maxLines: wrap ? null : 1,
          overflow: wrap ? null : TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: weight == 'bold' ? FontWeight.bold : FontWeight.normal,
            fontSize: size == 'xl' ? 18 : size == 'lg' ? 16 : size == 'sm' ? 12 : 14,
            color: color != null ? Color(int.parse('0xFF${color.replaceFirst('#', '')}')) : const Color(0xFF1A1A1A),
          ),
        ),
      );
    }
    if (type == 'separator') return const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Color(0xFFF0F0F0)));
    if (type == 'box') {
      final children = (item['contents'] as List<dynamic>? ?? []).map((c) => _renderItem(c as Map<String, dynamic>)).toList();
      final layout = item['layout'] as String?;
      if (layout == 'baseline' || layout == 'horizontal') {
        return Row(children: children.map((c) => Expanded(child: c)).toList());
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
    }
    return const SizedBox.shrink();
  }
}

// ─── Small widgets ────────────────────────────────────────────────────────────

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A1A1A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? Colors.white : const Color(0xFF9E9E9E),
            )),
      ),
    );
  }
}

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
