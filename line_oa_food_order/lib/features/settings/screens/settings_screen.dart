import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:line_oa_food_order/core/services/api_service.dart';
import 'package:line_oa_food_order/core/services/auth_storage.dart';

// ─── Main settings menu ───────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      _MenuItem(icon: Icons.person_outline, label: 'โปรไฟล์', sub: 'ชื่อ, อีเมล', page: const _ProfilePage()),
      _MenuItem(icon: Icons.lock_outline, label: 'เปลี่ยนรหัสผ่าน', sub: 'อัปเดตรหัสผ่านของคุณ', page: const _ChangePasswordPage()),
      _MenuItem(icon: Icons.store_outlined, label: 'ข้อมูลร้าน', sub: 'ชื่อร้าน, ภาษี', page: const _ShopInfoPage()),
      _MenuItem(icon: Icons.payment_outlined, label: 'วิธีชำระเงิน', sub: 'เงินสด, โอน, QR', page: const _PaymentPage()),
      _MenuItem(icon: Icons.logout, label: 'ออกจากระบบ', sub: '', page: null, danger: true),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Text('ตั้งค่า', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return _MenuTile(
                    item: item,
                    onTap: () async {
                      if (item.page == null) {
                        // logout
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('ออกจากระบบ'),
                            content: const Text('ต้องการออกจากระบบใช่ไหม?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ออกจากระบบ', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await AuthStorage.clear();
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ออกจากระบบแล้ว'), behavior: SnackBarBehavior.floating));
                        }
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => item.page!));
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String sub;
  final Widget? page;
  final bool danger;
  const _MenuItem({required this.icon, required this.label, required this.sub, required this.page, this.danger = false});
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  final VoidCallback onTap;
  const _MenuTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = item.danger ? Colors.red : const Color(0xFF202124);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: item.danger ? Colors.red.shade50 : const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
                    if (item.sub.isNotEmpty)
                      Text(item.sub, style: const TextStyle(fontSize: 12, color: Color(0xFF5f6368))),
                  ],
                ),
              ),
              if (item.page != null)
                const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Profile page ─────────────────────────────────────────────────────────────

class _ProfilePage extends StatefulWidget {
  const _ProfilePage();
  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  final _nameCtrl = TextEditingController();
  String? _email;
  String? _token;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    AuthStorage.getAll().then((d) => setState(() {
      _nameCtrl.text = d['name'] ?? '';
      _email = d['email'];
      _token = d['token'];
    }));
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_token == null) return;
    setState(() => _saving = true);
    try {
      await ApiService().updateProfile(_token!, _nameCtrl.text.trim());
      final d = await AuthStorage.getAll();
      await AuthStorage.save(token: _token!, name: _nameCtrl.text.trim(), email: _email ?? '', merchantId: d['merchantId'] ?? '');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('อัปเดตชื่อแล้ว'), behavior: SnackBarBehavior.floating));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาด'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _SubPage(
    title: 'โปรไฟล์',
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_email != null) ...[
        const Text('อีเมล', style: TextStyle(fontSize: 12, color: Color(0xFF5f6368), fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFFF1F3F4), borderRadius: BorderRadius.circular(12)),
          child: Text(_email!, style: const TextStyle(fontSize: 15)),
        ),
        const SizedBox(height: 20),
      ],
      const Text('ชื่อ', style: TextStyle(fontSize: 12, color: Color(0xFF5f6368), fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      _Field(ctrl: _nameCtrl, label: 'ชื่อของคุณ'),
      const SizedBox(height: 20),
      _SaveBtn(onPressed: _save, saving: _saving, label: 'บันทึกชื่อ'),
    ]),
  );
}

// ─── Change password page ─────────────────────────────────────────────────────

class _ChangePasswordPage extends StatefulWidget {
  const _ChangePasswordPage();
  @override
  State<_ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<_ChangePasswordPage> {
  final _curCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  String? _token;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    AuthStorage.getToken().then((t) => setState(() => _token = t));
  }

  @override
  void dispose() { _curCtrl.dispose(); _newCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_token == null) return;
    if (_curCtrl.text.isEmpty || _newCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกรหัสผ่านให้ครบ'), behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService().changePassword(_token!, _curCtrl.text.trim(), _newCtrl.text.trim());
      _curCtrl.clear(); _newCtrl.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เปลี่ยนรหัสผ่านแล้ว'), behavior: SnackBarBehavior.floating));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('รหัสผ่านปัจจุบันไม่ถูกต้อง'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _SubPage(
    title: 'เปลี่ยนรหัสผ่าน',
    child: Column(children: [
      _Field(ctrl: _curCtrl, label: 'รหัสผ่านปัจจุบัน', obscure: true),
      const SizedBox(height: 14),
      _Field(ctrl: _newCtrl, label: 'รหัสผ่านใหม่', obscure: true),
      const SizedBox(height: 20),
      _SaveBtn(onPressed: _save, saving: _saving, label: 'เปลี่ยนรหัสผ่าน'),
    ]),
  );
}

// ─── Shop info page ───────────────────────────────────────────────────────────

class _ShopInfoPage extends StatefulWidget {
  const _ShopInfoPage();
  @override
  State<_ShopInfoPage> createState() => _ShopInfoPageState();
}

class _ShopInfoPageState extends State<_ShopInfoPage> {
  final _shopNameCtrl = TextEditingController();
  bool _vatEnabled = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    ApiService().getStoreSettings().then((d) => setState(() {
      _shopNameCtrl.text = d['shopName'] as String? ?? '';
      _vatEnabled = d['vatEnabled'] as bool? ?? false;
      _loading = false;
    })).catchError((_) => setState(() => _loading = false));
  }

  @override
  void dispose() { _shopNameCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService().saveStoreSettings(data: {
        'merchantId': 'merchant-001',
        'shopName': _shopNameCtrl.text.trim(),
        'vatEnabled': _vatEnabled.toString(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกแล้ว'), behavior: SnackBarBehavior.floating));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาด'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _SubPage(title: 'ข้อมูลร้าน', child: Center(child: CircularProgressIndicator()));
    return _SubPage(
      title: 'ข้อมูลร้าน',
      child: Column(children: [
        _Field(ctrl: _shopNameCtrl, label: 'ชื่อร้าน'),
        const SizedBox(height: 14),
        _ToggleRow(label: '🧾 เพิ่ม VAT 7%', value: _vatEnabled, onChanged: (v) => setState(() => _vatEnabled = v)),
        const SizedBox(height: 20),
        _SaveBtn(onPressed: _save, saving: _saving, label: 'บันทึก'),
      ]),
    );
  }
}

// ─── Payment page ─────────────────────────────────────────────────────────────

class _PaymentPage extends StatefulWidget {
  const _PaymentPage();
  @override
  State<_PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<_PaymentPage> {
  final _bankNameCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _promptPayCtrl = TextEditingController();
  bool _acceptCash = true;
  bool _acceptBankTransfer = false;
  bool _acceptPromptPay = false;
  bool _acceptQrCode = false;
  String? _existingQrUrl;
  Uint8List? _qrImageBytes;
  String _qrImageName = 'qr.jpg';
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    ApiService().getStoreSettings().then((d) => setState(() {
      _bankNameCtrl.text = d['bankName'] as String? ?? '';
      _bankAccountCtrl.text = d['bankAccount'] as String? ?? '';
      _accountNameCtrl.text = d['accountName'] as String? ?? '';
      _promptPayCtrl.text = d['promptPayNumber'] as String? ?? '';
      _acceptCash = d['acceptCash'] as bool? ?? true;
      _acceptBankTransfer = d['acceptBankTransfer'] as bool? ?? false;
      _acceptPromptPay = d['acceptPromptPay'] as bool? ?? false;
      _acceptQrCode = d['acceptQrCode'] as bool? ?? false;
      final hasBase64 = (d['qrCodeImageBase64'] as String?) != null;
      _existingQrUrl = hasBase64
          ? 'https://aihya-food-man.onrender.com/api/settings/qr?merchantId=merchant-001&t=${DateTime.now().millisecondsSinceEpoch}'
          : (d['qrCodeImageUrl'] as String?);
      _loading = false;
    })).catchError((_) => setState(() => _loading = false));
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose(); _bankAccountCtrl.dispose();
    _accountNameCtrl.dispose(); _promptPayCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickQr() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() { _qrImageBytes = bytes; _qrImageName = file.name; });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService().saveStoreSettings(
        data: {
          'merchantId': 'merchant-001',
          'acceptCash': _acceptCash.toString(),
          'acceptBankTransfer': _acceptBankTransfer.toString(),
          'acceptPromptPay': _acceptPromptPay.toString(),
          'acceptQrCode': _acceptQrCode.toString(),
          'bankName': _bankNameCtrl.text.trim(),
          'bankAccount': _bankAccountCtrl.text.trim(),
          'accountName': _accountNameCtrl.text.trim(),
          'promptPayNumber': _promptPayCtrl.text.trim(),
        },
        qrImageBytes: _qrImageBytes,
        qrImageName: _qrImageName,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกแล้ว'), behavior: SnackBarBehavior.floating));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาด'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _SubPage(title: 'วิธีชำระเงิน', child: Center(child: CircularProgressIndicator()));
    return _SubPage(
      title: 'วิธีชำระเงิน',
      child: Column(children: [
        _ToggleRow(label: '💵 เงินสด', value: _acceptCash, onChanged: (v) => setState(() => _acceptCash = v)),
        _ToggleRow(label: '🏦 โอนธนาคาร', value: _acceptBankTransfer, onChanged: (v) => setState(() => _acceptBankTransfer = v)),
        _ToggleRow(label: '⚡ พร้อมเพย์', value: _acceptPromptPay, onChanged: (v) => setState(() => _acceptPromptPay = v)),
        _ToggleRow(label: '📱 QR Code', value: _acceptQrCode, onChanged: (v) => setState(() => _acceptQrCode = v)),
        if (_acceptQrCode) ...[
          const SizedBox(height: 16),
          const Align(alignment: Alignment.centerLeft, child: Text('QR Code', style: TextStyle(fontSize: 12, color: Color(0xFF5f6368), fontWeight: FontWeight.w600))),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickQr,
            child: Container(
              width: double.infinity, height: 180,
              decoration: BoxDecoration(color: const Color(0xFFF1F3F4), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: _qrImageBytes != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_qrImageBytes!, fit: BoxFit.contain))
                  : _existingQrUrl != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_existingQrUrl!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Color(0xFF9E9E9E))))
                      : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.qr_code, size: 48, color: Color(0xFF9E9E9E)),
                          SizedBox(height: 8),
                          Text('แตะเพื่ออัปโหลด QR Code', style: TextStyle(color: Color(0xFF9E9E9E))),
                        ]),
            ),
          ),
        ],
        if (_acceptBankTransfer || _acceptPromptPay) ...[
          const SizedBox(height: 16),
          const Align(alignment: Alignment.centerLeft, child: Text('ข้อมูลบัญชี', style: TextStyle(fontSize: 12, color: Color(0xFF5f6368), fontWeight: FontWeight.w600))),
          const SizedBox(height: 8),
          if (_acceptBankTransfer) ...[
            _Field(ctrl: _bankNameCtrl, label: 'ชื่อธนาคาร'),
            const SizedBox(height: 10),
            _Field(ctrl: _bankAccountCtrl, label: 'เลขบัญชี'),
            const SizedBox(height: 10),
            _Field(ctrl: _accountNameCtrl, label: 'ชื่อบัญชี'),
          ],
          if (_acceptPromptPay) ...[
            const SizedBox(height: 10),
            _Field(ctrl: _promptPayCtrl, label: 'เบอร์พร้อมเพย์'),
          ],
        ],
        const SizedBox(height: 20),
        _SaveBtn(onPressed: _save, saving: _saving, label: 'บันทึก'),
      ]),
    );
  }
}

// ─── Shared sub-page shell ────────────────────────────────────────────────────

class _SubPage extends StatelessWidget {
  final String title;
  final Widget child;
  const _SubPage({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool obscure;
  const _Field({required this.ctrl, required this.label, this.obscure = false});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    obscureText: obscure,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true, fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 2),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF1A1A1A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
    ),
  );
}

class _SaveBtn extends StatelessWidget {
  final VoidCallback onPressed;
  final bool saving;
  final String label;
  const _SaveBtn({required this.onPressed, required this.saving, required this.label});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: saving ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: saving
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ),
  );
}
