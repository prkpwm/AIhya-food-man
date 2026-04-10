import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_oa_food_order/features/generator/providers/rich_menu_provider.dart';

// ─── Template definitions ─────────────────────────────────────────────────────

class _RichMenuTemplate {
  final String id;
  final String name;
  final String description;
  final List<_BtnDef> buttons;
  final bool isCustomer;

  const _RichMenuTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.buttons,
    required this.isCustomer,
  });
}

class _BtnDef {
  final String label;
  final Color color;
  final Color textColor;
  const _BtnDef(this.label, {this.color = const Color(0xFF1A1A1A), this.textColor = Colors.white});
}

final _templates = [
  _RichMenuTemplate(
    id: 'customer-basic',
    name: 'ลูกค้า — พื้นฐาน',
    description: '3 ปุ่ม: ดูเมนู / ออเดอร์ / โปรโมชั่น',
    isCustomer: true,
    buttons: [
      _BtnDef('ดูเมนู', color: const Color(0xFF06C755)),
      _BtnDef('ออเดอร์', color: const Color(0xFF1A1A1A)),
      _BtnDef('โปรโมชั่น', color: const Color(0xFFFF6B00)),
    ],
  ),
  _RichMenuTemplate(
    id: 'customer-dark',
    name: 'ลูกค้า — Dark',
    description: '3 ปุ่ม สไตล์มืด',
    isCustomer: true,
    buttons: [
      _BtnDef('🍽️ เมนู', color: const Color(0xFF2C2C2C)),
      _BtnDef('📦 ออเดอร์', color: const Color(0xFF2C2C2C)),
      _BtnDef('🎁 โปร', color: const Color(0xFF2C2C2C)),
    ],
  ),
  _RichMenuTemplate(
    id: 'customer-mint',
    name: 'ลูกค้า — Mint',
    description: '3 ปุ่ม สไตล์ mint',
    isCustomer: true,
    buttons: [
      _BtnDef('เมนู', color: const Color(0xFF7ECEC4)),
      _BtnDef('ออเดอร์', color: const Color(0xFF7ECEC4)),
      _BtnDef('โปรโมชั่น', color: const Color(0xFF7ECEC4)),
    ],
  ),
  _RichMenuTemplate(
    id: 'merchant-basic',
    name: 'เจ้าของร้าน — พื้นฐาน',
    description: '4 ปุ่ม: ออเดอร์ / สต๊อก / รายได้ / เพิ่มเมนู',
    isCustomer: false,
    buttons: [
      _BtnDef('ออเดอร์', color: const Color(0xFF1A1A1A)),
      _BtnDef('สต๊อก', color: const Color(0xFFFF9800)),
      _BtnDef('รายได้', color: const Color(0xFF06C755)),
      _BtnDef('เพิ่มเมนู', color: const Color(0xFF2196F3)),
    ],
  ),
  _RichMenuTemplate(
    id: 'merchant-dark',
    name: 'เจ้าของร้าน — Dark',
    description: '4 ปุ่ม สไตล์มืด',
    isCustomer: false,
    buttons: [
      _BtnDef('📋 ออเดอร์', color: const Color(0xFF2C2C2C)),
      _BtnDef('📦 สต๊อก', color: const Color(0xFF2C2C2C)),
      _BtnDef('💰 รายได้', color: const Color(0xFF2C2C2C)),
      _BtnDef('➕ เมนู', color: const Color(0xFF2C2C2C)),
    ],
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class RichMenuScreen extends ConsumerStatefulWidget {
  const RichMenuScreen({super.key});

  @override
  ConsumerState<RichMenuScreen> createState() => _RichMenuScreenState();
}

class _RichMenuScreenState extends ConsumerState<RichMenuScreen> {
  final _shopNameCtrl = TextEditingController(text: 'ร้านข้าวผัดแม่มาลี');
  Uint8List? _imageBytes;
  _RichMenuTemplate _selected = _templates.first;

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _imageBytes = bytes);
  }

  Future<void> _deploy() async {
    if (_imageBytes == null) {
      _showSnack('กรุณาเลือกรูป background ก่อน');
      return;
    }
    final notifier = ref.read(richMenuProvider.notifier);
    final id = _selected.isCustomer
        ? await notifier.deployCustomer(_shopNameCtrl.text.trim(), _imageBytes!)
        : await notifier.deployMerchant(_shopNameCtrl.text.trim(), _imageBytes!);
    if (id != null && mounted) _showSnack('Deploy สำเร็จ! ID: $id');
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final richMenuState = ref.watch(richMenuProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rich Menu', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // ── config card ──────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _shopNameCtrl,
                            decoration: InputDecoration(
                              labelText: 'ชื่อร้าน',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true, fillColor: const Color(0xFFF5F5F5),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // template dropdown
                          DropdownButtonFormField<_RichMenuTemplate>(
                            value: _selected,
                            decoration: InputDecoration(
                              labelText: 'เลือก Template',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true, fillColor: const Color(0xFFF5F5F5),
                            ),
                            items: _templates.map((t) => DropdownMenuItem(
                              value: t,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  Text(t.description, style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                                ],
                              ),
                            )).toList(),
                            onChanged: (v) => setState(() => _selected = v ?? _selected),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: richMenuState.isLoading ? null : _deploy,
                              child: richMenuState.isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text('Deploy ${_selected.name}'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── preview ──────────────────────────────────────────────
                    const Text('Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickImage,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AspectRatio(
                          aspectRatio: 2500 / 843,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // bg
                              _imageBytes != null
                                  ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                                  : Container(
                                      color: const Color(0xFF2C2C2C),
                                      child: const Center(
                                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                                          Icon(Icons.add_photo_alternate_outlined, color: Colors.white38, size: 28),
                                          SizedBox(height: 6),
                                          Text('แตะเพื่อเลือกรูป background', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                        ]),
                                      ),
                                    ),
                              // button overlay (fixed, not editable)
                              _TemplateOverlay(template: _selected),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'แตะ preview เพื่อเปลี่ยนรูป bg • ปุ่มตาม template ที่เลือก',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 20),
                    const Text('Rich Menu ที่ Deploy แล้ว', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            richMenuState.when(
              loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))),
              error: (e, _) => SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(20), child: Text('$e', style: const TextStyle(color: Colors.red)))),
              data: (menus) => menus.isEmpty
                  ? const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20), child: Center(child: Text('ยังไม่มี Rich Menu', style: TextStyle(color: Color(0xFF9E9E9E))))))
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _RichMenuTile(menu: menus[i] as Map<String, dynamic>),
                          childCount: menus.length,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Template Overlay ─────────────────────────────────────────────────────────

class _TemplateOverlay extends StatelessWidget {
  final _RichMenuTemplate template;
  const _TemplateOverlay({required this.template});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: template.buttons.asMap().entries.map((e) {
        final isLast = e.key == template.buttons.length - 1;
        final btn = e.value;
        return Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: isLast ? BorderSide.none : const BorderSide(color: Colors.white24, width: 1)),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: btn.color,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                ),
                child: Text(
                  btn.label,
                  style: TextStyle(color: btn.textColor, fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Rich Menu Tile ───────────────────────────────────────────────────────────

class _RichMenuTile extends ConsumerWidget {
  final Map<String, dynamic> menu;
  const _RichMenuTile({required this.menu});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = menu['name'] as String? ?? '-';
    final id = menu['richMenuId'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const Icon(Icons.grid_view, color: Color(0xFF7ECEC4), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(id, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
            ]),
          ),
          GestureDetector(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('ลบ Rich Menu'),
                  content: Text('ต้องการลบ "$name" ไหม?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(dialogCtx).pop(false), child: const Text('ยกเลิก')),
                    ElevatedButton(onPressed: () => Navigator.of(dialogCtx).pop(true), child: const Text('ลบ')),
                  ],
                ),
              );
              if (confirm == true) await ref.read(richMenuProvider.notifier).delete(id);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFF44336)),
            ),
          ),
        ],
      ),
    );
  }
}
