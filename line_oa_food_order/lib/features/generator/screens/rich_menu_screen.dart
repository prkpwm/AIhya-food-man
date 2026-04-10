import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_oa_food_order/features/generator/providers/rich_menu_provider.dart';

class RichMenuScreen extends ConsumerStatefulWidget {
  const RichMenuScreen({super.key});

  @override
  ConsumerState<RichMenuScreen> createState() => _RichMenuScreenState();
}

class _RichMenuScreenState extends ConsumerState<RichMenuScreen> {
  final _shopNameCtrl = TextEditingController(text: 'ร้านข้าวผัดแม่มาลี');
  String? _imageBase64;
  String? _imagePath;
  bool _isCustomer = true;

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null) return;
    final bytes = await File(file.path).readAsBytes();
    setState(() {
      _imageBase64 = base64Encode(bytes);
      _imagePath = file.path;
    });
  }

  Future<void> _deploy() async {
    if (_imageBase64 == null) {
      _showSnack('กรุณาเลือกรูปภาพก่อน');
      return;
    }
    final notifier = ref.read(richMenuProvider.notifier);
    final id = _isCustomer
        ? await notifier.deployCustomer(_shopNameCtrl.text.trim(), _imageBase64!)
        : await notifier.deployMerchant(_shopNameCtrl.text.trim(), _imageBase64!);

    if (id != null && mounted) {
      _showSnack('Deploy สำเร็จ! ID: $id');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

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
                    // config card
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
                          const Text('ตั้งค่า', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _shopNameCtrl,
                            decoration: InputDecoration(
                              labelText: 'ชื่อร้าน',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: const Color(0xFFF5F5F5),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // type toggle
                          Row(
                            children: [
                              const Text('ประเภท', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 12),
                              _TypeChip(label: 'ลูกค้า', selected: _isCustomer, onTap: () => setState(() => _isCustomer = true)),
                              const SizedBox(width: 8),
                              _TypeChip(label: 'เจ้าของร้าน', selected: !_isCustomer, onTap: () => setState(() => _isCustomer = false)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // image picker
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: double.infinity,
                              height: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: _imagePath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                                    )
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image_outlined, size: 36, color: Color(0xFF9E9E9E)),
                                        SizedBox(height: 8),
                                        Text('เลือกรูป Rich Menu (2500×843)', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: richMenuState.isLoading ? null : _deploy,
                              child: richMenuState.isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text('Deploy ${_isCustomer ? 'ลูกค้า' : 'เจ้าของร้าน'} Rich Menu'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // layout preview
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
                          Text(
                            'Layout Preview — ${_isCustomer ? 'ลูกค้า' : 'เจ้าของร้าน'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          _isCustomer ? const _CustomerLayoutPreview() : const _MerchantLayoutPreview(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // deployed list
                    const Text('Rich Menu ที่ Deploy แล้ว', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            richMenuState.when(
              loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('$e', style: const TextStyle(color: Colors.red)),
                ),
              ),
              data: (menus) => menus.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('ยังไม่มี Rich Menu', style: TextStyle(color: Color(0xFF9E9E9E)))),
                      ),
                    )
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

// ─── Layout Previews ──────────────────────────────────────────────────────────

class _CustomerLayoutPreview extends StatelessWidget {
  const _CustomerLayoutPreview();

  @override
  Widget build(BuildContext context) {
    return _PreviewGrid(buttons: const ['ดูเมนู', 'ออเดอร์ของฉัน', 'โปรโมชั่น']);
  }
}

class _MerchantLayoutPreview extends StatelessWidget {
  const _MerchantLayoutPreview();

  @override
  Widget build(BuildContext context) {
    return _PreviewGrid(buttons: const ['ออเดอร์', 'สต๊อก', 'รายได้', 'เพิ่มเมนู']);
  }
}

class _PreviewGrid extends StatelessWidget {
  final List<String> buttons;
  const _PreviewGrid({required this.buttons});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: buttons.asMap().entries.map((e) {
          final isLast = e.key == buttons.length - 1;
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(right: isLast ? BorderSide.none : const BorderSide(color: Colors.white24)),
              ),
              child: Center(
                child: Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 11), textAlign: TextAlign.center),
              ),
            ),
          );
        }).toList(),
      ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(id, style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('ลบ Rich Menu'),
                  content: Text('ต้องการลบ "$name" ไหม?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ')),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(richMenuProvider.notifier).delete(id);
              }
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

// ─── Type Chip ────────────────────────────────────────────────────────────────

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
