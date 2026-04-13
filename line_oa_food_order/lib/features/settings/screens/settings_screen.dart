import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:line_oa_food_order/core/services/api_service.dart';
import 'package:line_oa_food_order/core/services/auth_storage.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _shopNameCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _promptPayCtrl = TextEditingController();

  // profile
  final _nameCtrl = TextEditingController();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  String? _authToken;
  String? _userEmail;

  bool _acceptCash = true;
  bool _acceptBankTransfer = false;
  bool _acceptPromptPay = false;
  bool _acceptQrCode = false;
  bool _vatEnabled = false;

  String? _existingQrUrl;
  Uint8List? _qrImageBytes;
  String _qrImageName = 'qr.jpg';

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadProfile();
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankAccountCtrl.dispose();
    _accountNameCtrl.dispose();
    _promptPayCtrl.dispose();
    _nameCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final data = await AuthStorage.getAll();
    setState(() {
      _authToken = data['token'];
      _userEmail = data['email'];
      _nameCtrl.text = data['name'] ?? '';
    });
  }

  Future<void> _saveProfile() async {
    if (_authToken == null) return;
    try {
      await ApiService().updateProfile(_authToken!, _nameCtrl.text.trim());
      await AuthStorage.save(
        token: _authToken!,
        name: _nameCtrl.text.trim(),
        email: _userEmail ?? '',
        merchantId: (await AuthStorage.getAll())['merchantId'] ?? '',
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('อัปเดตชื่อแล้ว'), behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _changePassword() async {
    if (_authToken == null) return;
    final cur = _currentPassCtrl.text.trim();
    final nw = _newPassCtrl.text.trim();
    if (cur.isEmpty || nw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณากรอกรหัสผ่านให้ครบ'), behavior: SnackBarBehavior.floating));
      return;
    }
    try {
      await ApiService().changePassword(_authToken!, cur, nw);
      _currentPassCtrl.clear();
      _newPassCtrl.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เปลี่ยนรหัสผ่านแล้ว'), behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('รหัสผ่านปัจจุบันไม่ถูกต้อง'), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _logout() async {
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
    if (confirm != true) return;
    await AuthStorage.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ออกจากระบบแล้ว'), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _loadSettings() async {
    try {
      final data = await ApiService().getStoreSettings();
      setState(() {
        _shopNameCtrl.text = data['shopName'] as String? ?? '';
        _bankNameCtrl.text = data['bankName'] as String? ?? '';
        _bankAccountCtrl.text = data['bankAccount'] as String? ?? '';
        _accountNameCtrl.text = data['accountName'] as String? ?? '';
        _promptPayCtrl.text = data['promptPayNumber'] as String? ?? '';
        _acceptCash = data['acceptCash'] as bool? ?? true;
        _acceptBankTransfer = data['acceptBankTransfer'] as bool? ?? false;
        _acceptPromptPay = data['acceptPromptPay'] as bool? ?? false;
        _acceptQrCode = data['acceptQrCode'] as bool? ?? false;
        _vatEnabled = data['vatEnabled'] as bool? ?? false;
        // use QR endpoint if base64 stored, else fallback to url
        final hasBase64 = (data['qrCodeImageBase64'] as String?) != null;
        _existingQrUrl = hasBase64
            ? 'https://aihya-food-man.onrender.com/api/settings/qr?merchantId=merchant-001&t=${DateTime.now().millisecondsSinceEpoch}'
            : (data['qrCodeImageUrl'] as String?);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickQrImage() async {
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
          'shopName': _shopNameCtrl.text.trim(),
          'acceptCash': _acceptCash.toString(),
          'acceptBankTransfer': _acceptBankTransfer.toString(),
          'acceptPromptPay': _acceptPromptPay.toString(),
          'acceptQrCode': _acceptQrCode.toString(),
          'vatEnabled': _vatEnabled.toString(),
          'bankName': _bankNameCtrl.text.trim(),
          'bankAccount': _bankAccountCtrl.text.trim(),
          'accountName': _accountNameCtrl.text.trim(),
          'promptPayNumber': _promptPayCtrl.text.trim(),
        },
        qrImageBytes: _qrImageBytes,
        qrImageName: _qrImageName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('บันทึกการตั้งค่าแล้ว'),
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: const Text('ตั้งค่าร้าน', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Profile ──────────────────────────────────────────────
                    _Section(title: '👤 โปรไฟล์', children: [
                      if (_userEmail != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(_userEmail!, style: const TextStyle(fontSize: 13, color: Color(0xFF5f6368))),
                        ),
                      _Field(ctrl: _nameCtrl, label: 'ชื่อของคุณ'),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _saveProfile,
                          style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('บันทึกชื่อ'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _Section(title: '🔒 เปลี่ยนรหัสผ่าน', children: [
                      _Field(ctrl: _currentPassCtrl, label: 'รหัสผ่านปัจจุบัน', obscure: true),
                      const SizedBox(height: 10),
                      _Field(ctrl: _newPassCtrl, label: 'รหัสผ่านใหม่', obscure: true),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _changePassword,
                          style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('เปลี่ยนรหัสผ่าน'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text('ออกจากระบบ', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // ── Shop settings ─────────────────────────────────────────
                    _Section(title: 'ข้อมูลร้าน', children: [
                      _Field(ctrl: _shopNameCtrl, label: 'ชื่อร้าน'),
                    ]),
                    const SizedBox(height: 16),
                    _Section(title: 'วิธีชำระเงิน', children: [
                      _Toggle(label: '💵 เงินสด', value: _acceptCash, onChanged: (v) => setState(() => _acceptCash = v)),
                      _Toggle(label: '🏦 โอนธนาคาร', value: _acceptBankTransfer, onChanged: (v) => setState(() => _acceptBankTransfer = v)),
                      _Toggle(label: '⚡ พร้อมเพย์', value: _acceptPromptPay, onChanged: (v) => setState(() => _acceptPromptPay = v)),
                      _Toggle(label: '📱 QR Code', value: _acceptQrCode, onChanged: (v) => setState(() => _acceptQrCode = v)),
                    ]),
                    const SizedBox(height: 16),
                    _Section(title: 'ภาษี', children: [
                      _Toggle(label: '🧾 เพิ่ม VAT 7%', value: _vatEnabled, onChanged: (v) => setState(() => _vatEnabled = v)),
                    ]),
                    if (_acceptQrCode) ...[
                      const SizedBox(height: 16),
                      _Section(title: 'QR Code ชำระเงิน', children: [
                        GestureDetector(
                          onTap: _pickQrImage,
                          child: Container(
                            width: double.infinity, height: 180,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: _qrImageBytes != null
                                ? ClipRRect(borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(_qrImageBytes!, fit: BoxFit.contain))
                                : _existingQrUrl != null
                                    ? ClipRRect(borderRadius: BorderRadius.circular(12),
                                        child: Image.network(_existingQrUrl!, fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Color(0xFF9E9E9E))))
                                    : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Icon(Icons.qr_code, size: 48, color: Color(0xFF9E9E9E)),
                                        SizedBox(height: 8),
                                        Text('แตะเพื่ออัปโหลด QR Code', style: TextStyle(color: Color(0xFF9E9E9E))),
                                      ]),
                          ),
                        ),
                      ]),
                    ],
                    if (_acceptBankTransfer || _acceptPromptPay) ...[
                      const SizedBox(height: 16),
                      _Section(title: 'ข้อมูลบัญชี', children: [
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
                      ]),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _saving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('บันทึก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF555555))),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 14)),
      Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF1A1A1A)),
    ]);
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool obscure;
  const _Field({required this.ctrl, required this.label, this.obscure = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true, fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
