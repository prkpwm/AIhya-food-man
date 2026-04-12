import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:line_oa_food_order/core/services/api_service.dart';

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
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankAccountCtrl.dispose();
    _accountNameCtrl.dispose();
    _promptPayCtrl.dispose();
    super.dispose();
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
  const _Field({required this.ctrl, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true, fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
