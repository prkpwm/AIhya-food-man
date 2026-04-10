import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:line_oa_food_order/core/models/menu_model.dart';
import 'package:line_oa_food_order/core/services/api_service.dart';
import 'package:line_oa_food_order/core/services/flex_message_generator.dart';
import 'package:line_oa_food_order/features/menu/providers/menu_provider.dart';

class MenuListScreen extends ConsumerStatefulWidget {
  const MenuListScreen({super.key});

  @override
  ConsumerState<MenuListScreen> createState() => _MenuListScreenState();
}

class _MenuListScreenState extends ConsumerState<MenuListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuAsync = ref.watch(menuListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: menuAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (menus) {
            // filter by search query
            final filtered = _query.isEmpty
                ? menus
                : menus.where((m) => m.name.toLowerCase().contains(_query.toLowerCase()) || m.category.toLowerCase().contains(_query.toLowerCase())).toList();

            final byCategory = <String, List<MenuModel>>{};
            for (final m in filtered) {
              byCategory.putIfAbsent(m.category, () => []).add(m);
            }

            return CustomScrollView(
              slivers: [
                // ── header ──────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('จัดการเมนู', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            GestureDetector(
                              onTap: () => _showAddMenuSheet(context, ref),
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
                        const SizedBox(height: 16),
                        // ── search bar ───────────────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _query = v),
                            decoration: InputDecoration(
                              hintText: 'ค้นหาเมนู...',
                              hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF9E9E9E)),
                              suffixIcon: _query.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close, color: Color(0xFF9E9E9E), size: 18),
                                      onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // ── mint banner ──────────────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: const Color(0xFF7ECEC4), borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('เมนูทั้งหมด', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                    Text('${menus.length} รายการ',
                                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 10),
                                    GestureDetector(
                                      onTap: () => _showAddMenuSheet(context, ref),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(50)),
                                        child: const Text('เพิ่มเมนูใหม่', style: TextStyle(color: Colors.white, fontSize: 13)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.restaurant_menu, size: 80, color: Colors.white24),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                // ── no result ────────────────────────────────────────────────
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(children: [
                        const Icon(Icons.search_off, size: 48, color: Color(0xFFE0E0E0)),
                        const SizedBox(height: 12),
                        Text('ไม่พบเมนู "$_query"', style: const TextStyle(color: Color(0xFF9E9E9E))),
                      ]),
                    ),
                  ),
                // ── categories ───────────────────────────────────────────────
                ...byCategory.entries.map((entry) => SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                                Text('ดูทั้งหมด', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 210,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: entry.value.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (_, i) => _MenuCard(menu: entry.value[i], onAdd: () => _showMenuDetail(context, entry.value[i])),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showMenuDetail(BuildContext context, MenuModel menu) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _MenuDetailSheet(menu: menu, ref: ref),
    );
  }

  void _showAddMenuSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddMenuSheet(ref: ref),
    );
  }
}

// ─── Menu Card ────────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final MenuModel menu;
  final VoidCallback onAdd;
  const _MenuCard({required this.menu, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: 155,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                width: double.infinity, height: 105,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    menu.imageUrl != null
                        ? Image.network(menu.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF0F0F0),
                                child: const Center(child: Icon(Icons.restaurant, size: 40, color: Color(0xFFE0E0E0)))))
                        : Container(color: const Color(0xFFF0F0F0),
                            child: const Center(child: Icon(Icons.restaurant, size: 40, color: Color(0xFFE0E0E0)))),
                    if (!menu.isAvailable)
                      Container(
                        color: Colors.black54,
                        child: const Center(child: Text('หมด', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                      ),
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.star, size: 10, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text('4.5', style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(menu.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.local_fire_department, size: 11, color: Colors.orange),
                  Text(' x${menu.maxSpiceLevel}', style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
                ]),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('฿${menu.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: menu.isAvailable ? const Color(0xFF1A1A1A) : Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add, color: menu.isAvailable ? Colors.white : Colors.grey, size: 16),
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Menu Detail Sheet ────────────────────────────────────────────────────────

class _MenuDetailSheet extends ConsumerStatefulWidget {
  final MenuModel menu;
  final WidgetRef ref;
  const _MenuDetailSheet({required this.menu, required this.ref});

  @override
  ConsumerState<_MenuDetailSheet> createState() => _MenuDetailSheetState();
}

class _MenuDetailSheetState extends ConsumerState<_MenuDetailSheet> {
  int _spice = 2;
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final m = widget.menu;
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // image
          if (m.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.network(m.imageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 200, child: Center(child: Icon(Icons.restaurant, size: 60, color: Color(0xFFE0E0E0))))),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(m.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                Text('฿${m.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF6B00))),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                      builder: (_) => _EditMenuSheet(menu: m, ref: widget.ref),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF1A1A1A)),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Text(m.description, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
              const SizedBox(height: 16),
              // spice level
              if (m.maxSpiceLevel > 0) ...[
                const Text('ระดับความเผ็ด', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(m.maxSpiceLevel, (i) => GestureDetector(
                    onTap: () => setState(() => _spice = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.local_fire_department, size: 28,
                          color: i < _spice ? Colors.orange : Colors.grey.shade300),
                    ),
                  )),
                ),
                const SizedBox(height: 16),
              ],
              // qty
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('จำนวน', style: TextStyle(fontWeight: FontWeight.w600)),
                Row(children: [
                  _QtyBtn(icon: Icons.remove, onTap: () => setState(() => _qty = (_qty - 1).clamp(1, 99))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('$_qty', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  _QtyBtn(icon: Icons.add, onTap: () => setState(() => _qty++)),
                ]),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: m.isAvailable ? () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('เพิ่ม ${m.name} ×$_qty แล้ว'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ));
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  child: Text(
                    m.isAvailable ? 'เพิ่มลงตะกร้า — ฿${(m.price * _qty).toStringAsFixed(0)}' : 'หมดชั่วคราว',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Edit Menu Sheet ──────────────────────────────────────────────────────────

class _EditMenuSheet extends StatefulWidget {
  final MenuModel menu;
  final WidgetRef ref;
  const _EditMenuSheet({required this.menu, required this.ref});

  @override
  State<_EditMenuSheet> createState() => _EditMenuSheetState();
}

class _EditMenuSheetState extends State<_EditMenuSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  late String _category;
  late bool _available;
  bool _loading = false;
  Uint8List? _imageBytes;
  String _imageName = '';

  @override
  void initState() {
    super.initState();
    final m = widget.menu;
    _nameCtrl = TextEditingController(text: m.name);
    _priceCtrl = TextEditingController(text: m.price.toStringAsFixed(0));
    _descCtrl = TextEditingController(text: m.description);
    _category = m.category;
    _available = m.isAvailable;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() { _imageBytes = bytes; _imageName = file.name; });
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final api = ApiService();
      final res = await api.updateMenu(
        id: widget.menu.id,
        data: {
          'merchantId': widget.menu.merchantId,
          'name': _nameCtrl.text.trim(),
          'price': _priceCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'category': _category,
          'shopType': widget.menu.shopType.name,
          'maxSpiceLevel': widget.menu.maxSpiceLevel.toString(),
          'ingredientIds': '[]',
          'isAvailable': _available.toString(),
          if (_imageBytes == null && widget.menu.imageUrl != null)
            'imageUrl': widget.menu.imageUrl!,
        },
        imageBytes: _imageBytes,
        imageName: _imageName.isNotEmpty ? _imageName : 'menu.jpg',
      );

      // build updated model from response and broadcast flex to LINE
      final updated = MenuModel.fromJson(res['data'] as Map<String, dynamic>);
      final flex = FlexMessageGenerator.menuCard(updated);
      await api.broadcastFlex(FlexMessageGenerator.toJsonString(flex));

      widget.ref.invalidate(menuListProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('อัปเดตเมนูและส่ง Flex แล้ว'),
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
    final existingImage = widget.menu.imageUrl;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('แก้ไขเมนู', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity, height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _imageBytes != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover))
                    : existingImage != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(12),
                            child: Image.network(existingImage, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Color(0xFF9E9E9E))))
                        : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 32, color: Color(0xFF9E9E9E)),
                            SizedBox(height: 6),
                            Text('เปลี่ยนรูปเมนู', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
                          ]),
              ),
            ),
            const SizedBox(height: 12),
            _Field(ctrl: _nameCtrl, label: 'ชื่อเมนู'),
            const SizedBox(height: 12),
            _Field(ctrl: _priceCtrl, label: 'ราคา (บาท)', type: TextInputType.number),
            const SizedBox(height: 12),
            _Field(ctrl: _descCtrl, label: 'คำอธิบาย'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                labelText: 'หมวดหมู่',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: const Color(0xFFF5F5F5),
              ),
              items: ['กระเพรา', 'ผัดไทย', 'ต้มยำ', 'แกง', 'ยำ', 'ราดหน้า', 'ปิ้งย่าง', 'ของหวาน', 'อื่นๆ']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('พร้อมขาย', style: TextStyle(fontWeight: FontWeight.w600)),
              Switch(value: _available, onChanged: (v) => setState(() => _available = v),
                  activeColor: const Color(0xFF1A1A1A)),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('บันทึก & ส่ง Flex'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Menu Sheet ───────────────────────────────────────────────────────────

class _AddMenuSheet extends StatefulWidget {
  final WidgetRef ref;
  const _AddMenuSheet({required this.ref});

  @override
  State<_AddMenuSheet> createState() => _AddMenuSheetState();
}

class _AddMenuSheetState extends State<_AddMenuSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'กระเพรา';
  bool _available = true;
  bool _loading = false;
  Uint8List? _imageBytes;
  String _imageName = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _imageName = file.name;
    });
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ApiService().createMenu(
        data: {
          'merchantId': 'merchant-001',
          'name': _nameCtrl.text.trim(),
          'price': _priceCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'category': _category,
          'shopType': 'streetFood',
          'maxSpiceLevel': '3',
          'ingredientIds': '[]',
          'isAvailable': _available.toString(),
        },
        imageBytes: _imageBytes,
        imageName: _imageName,
      );
      widget.ref.invalidate(menuListProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('เพิ่มเมนูแล้ว'),
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
            const Text('เพิ่มเมนูใหม่', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity, height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      )
                    : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 32, color: Color(0xFF9E9E9E)),
                        SizedBox(height: 6),
                        Text('เลือกรูปเมนู (ไม่บังคับ)', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12)),
                      ]),
              ),
            ),
            const SizedBox(height: 12),
            _Field(ctrl: _nameCtrl, label: 'ชื่อเมนู'),
            const SizedBox(height: 12),
            _Field(ctrl: _priceCtrl, label: 'ราคา (บาท)', type: TextInputType.number),
            const SizedBox(height: 12),
            _Field(ctrl: _descCtrl, label: 'คำอธิบาย'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                labelText: 'หมวดหมู่',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: const Color(0xFFF5F5F5),
              ),
              items: ['กระเพรา', 'ผัดไทย', 'ต้มยำ', 'แกง', 'ยำ', 'ราดหน้า', 'ปิ้งย่าง', 'ของหวาน', 'อื่นๆ']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('พร้อมขาย', style: TextStyle(fontWeight: FontWeight.w600)),
              Switch(value: _available, onChanged: (v) => setState(() => _available = v),
                  activeColor: const Color(0xFF1A1A1A)),
            ]),
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

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: const Color(0xFF1A1A1A)),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType type;
  const _Field({required this.ctrl, required this.label, this.type = TextInputType.text});

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
