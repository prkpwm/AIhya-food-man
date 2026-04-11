import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_oa_food_order/features/generator/providers/rich_menu_provider.dart';

// ─── Preset definitions (no user customisation) ───────────────────────────────

class _Preset {
  final String id;
  final String label;
  final String emoji;
  final String subtitle;
  final Color accent;
  final Color bg;
  final bool isCustomer;
  final bool isLarge;
  final List<_Btn> buttons;

  const _Preset({
    required this.id,
    required this.label,
    required this.emoji,
    required this.subtitle,
    required this.accent,
    required this.bg,
    required this.isCustomer,
    required this.buttons,
    this.isLarge = false,
  });
}

class _Btn {
  final String icon;
  final String label;
  final Color color;
  const _Btn(this.icon, this.label, this.color);
}

const _presets = [
  _Preset(
    id: 'customer-orange',
    label: 'ลูกค้า — Orange Glow',
    emoji: '🍊',
    subtitle: 'สั่งอาหาร · ติดตาม · โปรโมชั่น',
    accent: Color(0xFFFF6B00),
    bg: Color(0xFF1C1C1E),
    isCustomer: true,
    buttons: [
      _Btn('🛒', 'สั่งอาหาร', Color(0xFFFF6B00)),
      _Btn('📦', 'ติดตามสถานะ', Color(0xFF2C2C2E)),
      _Btn('🎁', 'โปรโมชั่น', Color(0xFF06C755)),
    ],
  ),
  _Preset(
    id: 'customer-full',
    label: 'ลูกค้า — Full Grid',
    emoji: '🍽️',
    subtitle: '6 ปุ่ม เต็มหน้าจอ',
    accent: Color(0xFFFF6B00),
    bg: Color(0xFF1C1C1E),
    isCustomer: true,
    isLarge: true,
    buttons: [
      _Btn('🛒', 'สั่งอาหาร', Color(0xFFFF6B00)),
      _Btn('📦', 'ติดตามสถานะ', Color(0xFF2C2C2E)),
      _Btn('🎁', 'โปรโมชั่น', Color(0xFF06C755)),
      _Btn('❤️', 'เมนูโปรด', Color(0xFF9C27B0)),
      _Btn('🛍️', 'ดูตะกร้า', Color(0xFF2196F3)),
      _Btn('📞', 'ติดต่อร้าน', Color(0xFF607D8B)),
    ],
  ),
  _Preset(
    id: 'merchant-dark',
    label: 'เจ้าของร้าน — Dark Pro',
    emoji: '👨‍🍳',
    subtitle: 'ออเดอร์ · สต๊อก · รายได้ · เมนู',
    accent: Color(0xFFFF9800),
    bg: Color(0xFF0D0D0D),
    isCustomer: false,
    buttons: [
      _Btn('📋', 'ออเดอร์', Color(0xFF1C1C1E)),
      _Btn('📦', 'สต๊อก', Color(0xFFFF9800)),
      _Btn('💰', 'รายได้', Color(0xFF06C755)),
      _Btn('➕', 'เพิ่มเมนู', Color(0xFF2196F3)),
    ],
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class RichMenuScreen extends ConsumerStatefulWidget {
  const RichMenuScreen({super.key});

  @override
  ConsumerState<RichMenuScreen> createState() => _RichMenuScreenState();
}

class _RichMenuScreenState extends ConsumerState<RichMenuScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  _Preset get _preset => _presets[_selectedIndex];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _selectPreset(int i) {
    if (i == _selectedIndex) return;
    _animCtrl.reset();
    setState(() => _selectedIndex = i);
    _animCtrl.forward();
  }

  Future<void> _deploy() async {
    final imageBytes = await _generatePreviewImage(_preset);
    final notifier = ref.read(richMenuProvider.notifier);
    final shopName = _preset.label; // use preset label as shop name
    final id = _preset.isCustomer
        ? await notifier.deployCustomer(shopName, imageBytes, large: _preset.isLarge)
        : await notifier.deployMerchant(shopName, imageBytes, large: _preset.isLarge);
    if (id != null && mounted) _showSnack('✅ Deploy สำเร็จ! ID: $id');
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1C1C1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final richMenuState = ref.watch(richMenuProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _preset.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.grid_view_rounded, color: _preset.accent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rich Menu', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('เลือก preset แล้ว deploy ได้เลย', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // ── Preset chips ─────────────────────────────────────────
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _presets.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final p = _presets[i];
                          final active = i == _selectedIndex;
                          return GestureDetector(
                            onTap: () => _selectPreset(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: active ? p.accent : const Color(0xFF1C1C1E),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: active ? p.accent : const Color(0xFF2C2C2E),
                                ),
                              ),
                              child: Text(
                                '${p.emoji} ${p.label}',
                                style: TextStyle(
                                  color: active ? Colors.white : const Color(0xFF8E8E93),
                                  fontSize: 12,
                                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Preview card ─────────────────────────────────────────
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: _PreviewCard(preset: _preset),
                    ),
                    const SizedBox(height: 16),

                    // ── Deploy button ────────────────────────────────────────
                    richMenuState.when(
                      loading: () => _DeployBtn(accent: _preset.accent, loading: true, onTap: null),
                      error: (_, __) => _DeployBtn(accent: _preset.accent, loading: false, onTap: _deploy),
                      data: (_) => _DeployBtn(accent: _preset.accent, loading: false, onTap: _deploy),
                    ),
                    const SizedBox(height: 28),

                    // ── Deployed list header ─────────────────────────────────
                    const Text('Deployed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // ── Deployed list ────────────────────────────────────────────────
            richMenuState.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFFFF6B00)))),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('$e', style: const TextStyle(color: Color(0xFFF44336))),
                ),
              ),
              data: (menus) => menus.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.inbox_outlined, color: Color(0xFF3A3A3C), size: 40),
                            SizedBox(height: 8),
                            Text('ยังไม่มี Rich Menu', style: TextStyle(color: Color(0xFF8E8E93))),
                          ]),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => _MenuTile(menu: menus[i] as Map<String, dynamic>),
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

// ─── Preview Card ─────────────────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  final _Preset preset;
  const _PreviewCard({required this.preset});

  @override
  Widget build(BuildContext context) {
    final aspectRatio = preset.isLarge ? 2500 / 1686 : 2500 / 843;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: preset.accent.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: _RichMenuCanvas(preset: preset),
        ),
      ),
    );
  }
}

// ─── Canvas (renders the actual rich menu look) ───────────────────────────────

class _RichMenuCanvas extends StatelessWidget {
  final _Preset preset;
  const _RichMenuCanvas({required this.preset});

  @override
  Widget build(BuildContext context) {
    final btns = preset.buttons;
    final isLarge = preset.isLarge;

    Widget buildBtn(_Btn btn) => Expanded(
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: btn.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(btn.icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(
                  btn.label,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );

    Widget buildRow(List<_Btn> row) => Expanded(
          child: Row(children: row.map(buildBtn).toList()),
        );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [preset.bg, Color.lerp(preset.bg, preset.accent, 0.12)!],
        ),
      ),
      child: Stack(
        children: [
          // subtle grid pattern
          CustomPaint(painter: _GridPainter(preset.accent), size: Size.infinite),
          Padding(
            padding: const EdgeInsets.all(8),
            child: isLarge
                ? Column(children: [
                    buildRow(btns.sublist(0, (btns.length / 2).ceil())),
                    buildRow(btns.sublist((btns.length / 2).ceil())),
                  ])
                : Row(children: btns.map(buildBtn).toList()),
          ),
        ],
      ),
    );
  }
}

// ─── Subtle grid background painter ──────────────────────────────────────────

class _GridPainter extends CustomPainter {
  final Color accent;
  const _GridPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withOpacity(0.04)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.accent != accent;
}

// ─── Deploy Button ────────────────────────────────────────────────────────────

class _DeployBtn extends StatelessWidget {
  final Color accent;
  final bool loading;
  final VoidCallback? onTap;
  const _DeployBtn({required this.accent, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [accent, Color.lerp(accent, Colors.white, 0.15)!]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: loading
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Deploy Rich Menu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ]),
        ),
      ),
    );
  }
}

// ─── Deployed Menu Tile ───────────────────────────────────────────────────────

class _MenuTile extends ConsumerWidget {
  final Map<String, dynamic> menu;
  const _MenuTile({required this.menu});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = menu['name'] as String? ?? '-';
    final id = menu['richMenuId'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2E)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.grid_view_rounded, color: Color(0xFFFF6B00), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 2),
              Text(id, style: const TextStyle(fontSize: 10, color: Color(0xFF8E8E93)), overflow: TextOverflow.ellipsis),
            ]),
          ),
          GestureDetector(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1C1C1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('ลบ Rich Menu', style: TextStyle(color: Colors.white)),
                  content: Text('ต้องการลบ "$name" ไหม?', style: const TextStyle(color: Color(0xFF8E8E93))),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('ยกเลิก')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF44336)),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('ลบ'),
                    ),
                  ],
                ),
              );
              if (confirm == true) await ref.read(richMenuProvider.notifier).delete(id);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF44336).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFF44336)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Image generator (renders preset to Uint8List for deploy) ─────────────────

Future<Uint8List> _generatePreviewImage(_Preset preset) async {
  const w = 2500.0;
  final h = preset.isLarge ? 1686.0 : 843.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, h));

  // background gradient
  final bgPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [preset.bg, Color.lerp(preset.bg, preset.accent, 0.12)!],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
  canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

  // grid lines
  final gridPaint = Paint()
    ..color = preset.accent.withOpacity(0.04)
    ..strokeWidth = 2;
  for (double x = 0; x < w; x += 160) {
    canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
  }
  for (double y = 0; y < h; y += 160) {
    canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
  }

  final btns = preset.buttons;
  final rows = preset.isLarge ? 2 : 1;
  final cols = preset.isLarge ? (btns.length / 2).ceil() : btns.length;
  final cellW = w / cols;
  final cellH = h / rows;
  const pad = 24.0;
  const radius = 40.0;

  for (var i = 0; i < btns.length; i++) {
    final row = preset.isLarge ? (i < cols ? 0 : 1) : 0;
    final col = preset.isLarge ? (i < cols ? i : i - cols) : i;
    final btn = btns[i];

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(col * cellW + pad, row * cellH + pad, cellW - pad * 2, cellH - pad * 2),
      const Radius.circular(radius),
    );

    // shadow
    canvas.drawRRect(
      rect.shift(const Offset(0, 8)),
      Paint()..color = Colors.black.withOpacity(0.35),
    );

    // button fill
    canvas.drawRRect(rect, Paint()..color = btn.color);

    // emoji
    final emojiPb = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
      ..pushStyle(ui.TextStyle(fontSize: 120, color: Colors.white))
      ..addText(btn.icon);
    final emojiP = emojiPb.build()..layout(ui.ParagraphConstraints(width: cellW - pad * 2));
    canvas.drawParagraph(emojiP, Offset(col * cellW + pad, row * cellH + pad + (cellH - pad * 2) * 0.2));

    // label
    final labelPb = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
      ..pushStyle(ui.TextStyle(fontSize: 80, color: Colors.white, fontWeight: FontWeight.bold))
      ..addText(btn.label);
    final labelP = labelPb.build()..layout(ui.ParagraphConstraints(width: cellW - pad * 2));
    canvas.drawParagraph(labelP, Offset(col * cellW + pad, row * cellH + pad + (cellH - pad * 2) * 0.62));
  }

  final picture = recorder.endRecording();
  final img = await picture.toImage(w.toInt(), h.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
