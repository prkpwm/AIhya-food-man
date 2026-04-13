import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:line_oa_food_order/core/services/api_service.dart';
import 'package:line_oa_food_order/core/services/auth_storage.dart';
import 'package:line_oa_food_order/features/auth/providers/auth_provider.dart';

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
      _MenuItem(icon: Icons.workspace_premium_outlined, label: 'แพ็กเกจ', sub: 'Free / Silver / Gold / Platinum', page: const _PlanPage()),
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
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) context.go('/login');
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
  final _confirmCtrl = TextEditingController();
  String? _token;
  bool _saving = false;
  bool _showCur = false;
  bool _showNew = false;
  bool _showConfirm = false;

  // validation state
  String? _curError;
  String? _newError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    AuthStorage.getToken().then((t) => setState(() => _token = t));
  }

  @override
  void dispose() {
    _curCtrl.dispose(); _newCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    String? curErr, newErr, confirmErr;
    if (_curCtrl.text.isEmpty) curErr = 'กรุณากรอกรหัสผ่านปัจจุบัน';
    if (_newCtrl.text.length < 6) newErr = 'รหัสผ่านใหม่ต้องมีอย่างน้อย 6 ตัวอักษร';
    if (_confirmCtrl.text != _newCtrl.text) confirmErr = 'รหัสผ่านไม่ตรงกัน';
    setState(() { _curError = curErr; _newError = newErr; _confirmError = confirmErr; });
    return curErr == null && newErr == null && confirmErr == null;
  }

  Future<void> _save() async {
    if (!_validate() || _token == null) return;
    setState(() => _saving = true);
    try {
      await ApiService().changePassword(_token!, _curCtrl.text.trim(), _newCtrl.text.trim());
      _curCtrl.clear(); _newCtrl.clear(); _confirmCtrl.clear();
      setState(() { _curError = null; _newError = null; _confirmError = null; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ เปลี่ยนรหัสผ่านสำเร็จ'), behavior: SnackBarBehavior.floating, backgroundColor: Color(0xFF34A853)),
        );
      }
    } catch (_) {
      setState(() => _curError = 'รหัสผ่านปัจจุบันไม่ถูกต้อง');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _SubPage(
    title: 'เปลี่ยนรหัสผ่าน',
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // info banner
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [
          Icon(Icons.info_outline, color: Color(0xFF1A73E8), size: 18),
          SizedBox(width: 10),
          Expanded(child: Text('รหัสผ่านใหม่ต้องมีอย่างน้อย 6 ตัวอักษร', style: TextStyle(fontSize: 13, color: Color(0xFF1A73E8)))),
        ]),
      ),
      const SizedBox(height: 24),

      // current password
      const _Label('รหัสผ่านปัจจุบัน'),
      const SizedBox(height: 6),
      _PasswordField(
        ctrl: _curCtrl,
        hint: 'กรอกรหัสผ่านปัจจุบัน',
        show: _showCur,
        onToggle: () => setState(() => _showCur = !_showCur),
        error: _curError,
        onChanged: (_) => setState(() => _curError = null),
      ),
      const SizedBox(height: 20),

      // new password
      const _Label('รหัสผ่านใหม่'),
      const SizedBox(height: 6),
      _PasswordField(
        ctrl: _newCtrl,
        hint: 'กรอกรหัสผ่านใหม่',
        show: _showNew,
        onToggle: () => setState(() => _showNew = !_showNew),
        error: _newError,
        onChanged: (_) => setState(() => _newError = null),
      ),
      const SizedBox(height: 20),

      // confirm password
      const _Label('ยืนยันรหัสผ่านใหม่'),
      const SizedBox(height: 6),
      _PasswordField(
        ctrl: _confirmCtrl,
        hint: 'กรอกรหัสผ่านอีกครั้ง',
        show: _showConfirm,
        onToggle: () => setState(() => _showConfirm = !_showConfirm),
        error: _confirmError,
        onChanged: (_) => setState(() => _confirmError = null),
      ),
      const SizedBox(height: 28),

      _SaveBtn(onPressed: _save, saving: _saving, label: 'เปลี่ยนรหัสผ่าน'),
    ]),
  );
}

// ─── Password field with show/hide toggle ─────────────────────────────────────

class _PasswordField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final bool show;
  final VoidCallback onToggle;
  final String? error;
  final ValueChanged<String>? onChanged;
  const _PasswordField({required this.ctrl, required this.hint, required this.show, required this.onToggle, this.error, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: ctrl,
        obscureText: !show,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: error != null ? Colors.red.shade300 : const Color(0xFFE8EAED))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: error != null ? Colors.red : const Color(0xFF1A73E8), width: 1.5)),
          suffixIcon: IconButton(
            icon: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF9E9E9E), size: 20),
            onPressed: onToggle,
          ),
        ),
      ),
      if (error != null) ...[
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.error_outline, size: 14, color: Colors.red),
          const SizedBox(width: 4),
          Text(error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
        ]),
      ],
    ]);
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF5f6368)));
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ บันทึกแล้ว'), behavior: SnackBarBehavior.floating, backgroundColor: Color(0xFF34A853)),
      );
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาด'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _SubPage(title: 'วิธีชำระเงิน', child: Center(child: CircularProgressIndicator()));

    final hasBank = _acceptBankTransfer || _acceptPromptPay;

    return _SubPage(
      title: 'วิธีชำระเงิน',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Accept methods card ──────────────────────────────────────────────
        _CardSection(
          title: 'รับชำระด้วย',
          icon: Icons.payments_outlined,
          child: Column(children: [
            _PayToggle(
              icon: Icons.money, iconColor: const Color(0xFF34A853),
              label: 'เงินสด', sub: 'รับชำระที่เคาน์เตอร์',
              value: _acceptCash, onChanged: (v) => setState(() => _acceptCash = v),
            ),
            _Divider(),
            _PayToggle(
              icon: Icons.account_balance, iconColor: const Color(0xFF1A73E8),
              label: 'โอนธนาคาร', sub: 'โอนเงินผ่านธนาคาร',
              value: _acceptBankTransfer, onChanged: (v) => setState(() => _acceptBankTransfer = v),
            ),
            _Divider(),
            _PayToggle(
              icon: Icons.bolt, iconColor: const Color(0xFFFF9800),
              label: 'พร้อมเพย์', sub: 'PromptPay',
              value: _acceptPromptPay, onChanged: (v) => setState(() => _acceptPromptPay = v),
            ),
            _Divider(),
            _PayToggle(
              icon: Icons.qr_code_2, iconColor: const Color(0xFF9C27B0),
              label: 'QR Code', sub: 'สแกน QR ชำระเงิน',
              value: _acceptQrCode, onChanged: (v) => setState(() => _acceptQrCode = v),
            ),
          ]),
        ),

        // ── QR image card ────────────────────────────────────────────────────
        if (_acceptQrCode) ...[
          const SizedBox(height: 16),
          _CardSection(
            title: 'QR Code ชำระเงิน',
            icon: Icons.qr_code_2,
            child: Column(children: [
              GestureDetector(
                onTap: _pickQr,
                child: Stack(alignment: Alignment.bottomRight, children: [
                  Container(
                    width: double.infinity, height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8EAED)),
                    ),
                    child: _qrImageBytes != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_qrImageBytes!, fit: BoxFit.contain))
                        : _existingQrUrl != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_existingQrUrl!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Color(0xFF9E9E9E), size: 48)))
                            : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 48, color: Color(0xFFBDBDBD)),
                                SizedBox(height: 8),
                                Text('แตะเพื่ออัปโหลด QR Code', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
                              ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.edit, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('เปลี่ยน', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ],

        // ── Bank / PromptPay details card ────────────────────────────────────
        if (hasBank) ...[
          const SizedBox(height: 16),
          _CardSection(
            title: 'ข้อมูลบัญชี',
            icon: Icons.account_balance_wallet_outlined,
            child: Column(children: [
              if (_acceptBankTransfer) ...[
                _IconField(ctrl: _bankNameCtrl, label: 'ชื่อธนาคาร', icon: Icons.account_balance),
                const SizedBox(height: 12),
                _IconField(ctrl: _bankAccountCtrl, label: 'เลขบัญชี', icon: Icons.credit_card, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _IconField(ctrl: _accountNameCtrl, label: 'ชื่อบัญชี', icon: Icons.person_outline),
              ],
              if (_acceptPromptPay) ...[
                if (_acceptBankTransfer) const SizedBox(height: 12),
                _IconField(ctrl: _promptPayCtrl, label: 'เบอร์พร้อมเพย์', icon: Icons.bolt, keyboardType: TextInputType.phone),
              ],
            ]),
          ),
        ],

        const SizedBox(height: 24),
        _SaveBtn(onPressed: _save, saving: _saving, label: 'บันทึกการตั้งค่า'),
        const SizedBox(height: 8),
      ]),
    );
  }
}

// ─── Card section wrapper ─────────────────────────────────────────────────────

class _CardSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _CardSection({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Icon(icon, size: 16, color: const Color(0xFF5f6368)),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF5f6368), letterSpacing: .3)),
          ]),
        ),
        const SizedBox(height: 10),
        Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: child),
      ]),
    );
  }
}

// ─── Payment method toggle row ────────────────────────────────────────────────

class _PayToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PayToggle({required this.icon, required this.iconColor, required this.label, required this.sub, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: iconColor.withOpacity(.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          Text(sub, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
        ])),
        Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF1A73E8)),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(height: 1, color: Color(0xFFF1F3F4));
}

// ─── Icon-prefixed text field ─────────────────────────────────────────────────

class _IconField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  const _IconField({required this.ctrl, required this.label, required this.icon, this.keyboardType});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: keyboardType,
    style: const TextStyle(fontSize: 15),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF9E9E9E)),
      filled: true, fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );
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

// ─── Plan page ────────────────────────────────────────────────────────────────

class _PlanPage extends StatefulWidget {
  const _PlanPage();
  @override
  State<_PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<_PlanPage> {
  String? _token;
  String _currentPlan = 'free';
  DateTime? _expiresAt;
  bool _loading = true;
  bool _saving = false;

  static const _plans = [
    _PlanInfo('free',     'Free',     '฿0 / เดือน',   Color(0xFF9E9E9E), ['รับออเดอร์', 'จัดการเมนู', 'สต็อก']),
    _PlanInfo('silver',   'Silver',   '฿299 / เดือน', Color(0xFF78909C), ['ทุกอย่างใน Free', 'Rich Menu', 'รายงานยอดขาย']),
    _PlanInfo('gold',     'Gold',     '฿599 / เดือน', Color(0xFFFFA000), ['ทุกอย่างใน Silver', '✅ ส่ง Flex Message', '✅ แจ้งเตือน LINE']),
    _PlanInfo('platinum', 'Platinum', '฿999 / เดือน', Color(0xFF7B1FA2), ['ทุกอย่างใน Gold', '✅ Broadcast ไม่จำกัด', '✅ Priority Support']),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await AuthStorage.getToken();
    if (token == null) { setState(() => _loading = false); return; }
    setState(() => _token = token);
    try {
      final res = await ApiService().getMerchantPlan(token);
      final data = res['data'] as Map<String, dynamic>;
      setState(() {
        _currentPlan = data['plan'] as String? ?? 'free';
        final exp = data['planExpiresAt'];
        _expiresAt = exp != null ? DateTime.tryParse(exp.toString()) : null;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _selectPlan(String plan) async {
    if (_token == null || plan == _currentPlan) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('เปลี่ยนแพ็กเกจ'),
        content: Text('ต้องการเปลี่ยนเป็นแพ็กเกจ ${_plans.firstWhere((p) => p.id == plan).name} ใช่ไหม?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ยืนยัน')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _saving = true);
    try {
      await ApiService().updateMerchantPlan(_token!, plan);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ เปลี่ยนแพ็กเกจแล้ว'), behavior: SnackBarBehavior.floating, backgroundColor: Color(0xFF34A853)),
      );
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาด'), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _SubPage(title: 'แพ็กเกจ', child: Center(child: CircularProgressIndicator()));

    final current = _plans.firstWhere((p) => p.id == _currentPlan, orElse: () => _plans.first);

    return _SubPage(
      title: 'แพ็กเกจ',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // current plan banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: current.color.withOpacity(.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: current.color.withOpacity(.4)),
          ),
          child: Row(children: [
            Icon(Icons.workspace_premium, color: current.color, size: 32),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('แพ็กเกจปัจจุบัน: ${current.name}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: current.color)),
              if (_expiresAt != null)
                Text('หมดอายุ: ${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}', style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
            ])),
          ]),
        ),
        const SizedBox(height: 20),

        // flex notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFE082))),
          child: const Row(children: [
            Icon(Icons.info_outline, color: Color(0xFFFFA000), size: 16),
            SizedBox(width: 8),
            Expanded(child: Text('แพ็กเกจ Gold ขึ้นไปจะส่ง Flex Message แจ้งเตือนลูกค้าผ่าน LINE อัตโนมัติ', style: TextStyle(fontSize: 12, color: Color(0xFF795548)))),
          ]),
        ),
        const SizedBox(height: 20),

        // plan cards
        ..._plans.map((plan) => _PlanCard(
          plan: plan,
          isActive: plan.id == _currentPlan,
          saving: _saving,
          onSelect: () => _selectPlan(plan.id),
        )),
      ]),
    );
  }
}

class _PlanInfo {
  final String id;
  final String name;
  final String price;
  final Color color;
  final List<String> features;
  const _PlanInfo(this.id, this.name, this.price, this.color, this.features);
}

class _PlanCard extends StatelessWidget {
  final _PlanInfo plan;
  final bool isActive;
  final bool saving;
  final VoidCallback onSelect;
  const _PlanCard({required this.plan, required this.isActive, required this.saving, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? plan.color : const Color(0xFFE8EAED), width: isActive ? 2 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.workspace_premium, color: plan.color, size: 22),
            const SizedBox(width: 8),
            Text(plan.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: plan.color)),
            const Spacer(),
            Text(plan.price, style: const TextStyle(fontSize: 13, color: Color(0xFF5f6368))),
          ]),
          const SizedBox(height: 10),
          ...plan.features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Icon(Icons.check_circle_outline, size: 14, color: plan.color),
              const SizedBox(width: 6),
              Text(f, style: const TextStyle(fontSize: 13, color: Color(0xFF5f6368))),
            ]),
          )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: isActive
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(side: BorderSide(color: plan.color), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: Text('แพ็กเกจปัจจุบัน', style: TextStyle(color: plan.color)),
                  )
                : ElevatedButton(
                    onPressed: saving ? null : onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: plan.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text('เลือก ${plan.name}'),
                  ),
          ),
        ]),
      ),
    );
  }
}
