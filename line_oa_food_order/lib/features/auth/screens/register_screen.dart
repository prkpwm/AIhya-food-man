import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:line_oa_food_order/core/services/api_service.dart';
import 'package:line_oa_food_order/core/services/auth_storage.dart';
import 'package:line_oa_food_order/features/auth/widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _shopCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showPass = false;
  bool _showConfirm = false;
  bool _loading = false;

  String? _nameErr, _shopErr, _emailErr, _passErr, _confirmErr;

  @override
  void dispose() {
    _nameCtrl.dispose(); _shopCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    String? nErr, sErr, eErr, pErr, cErr;
    if (_nameCtrl.text.trim().isEmpty) nErr = 'กรุณากรอกชื่อ';
    if (_shopCtrl.text.trim().isEmpty) sErr = 'กรุณากรอกชื่อร้าน';
    if (_emailCtrl.text.trim().isEmpty) eErr = 'กรุณากรอกอีเมล';
    if (_passCtrl.text.length < 6) pErr = 'รหัสผ่านต้องมีอย่างน้อย 6 ตัว';
    if (_confirmCtrl.text != _passCtrl.text) cErr = 'รหัสผ่านไม่ตรงกัน';
    setState(() { _nameErr = nErr; _shopErr = sErr; _emailErr = eErr; _passErr = pErr; _confirmErr = cErr; });
    return nErr == null && sErr == null && eErr == null && pErr == null && cErr == null;
  }

  Future<void> _register() async {
    if (!_validate()) return;
    setState(() => _loading = true);
    try {
      final data = await ApiService().register(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
        _nameCtrl.text.trim(),
        _shopCtrl.text.trim(),
      );
      await AuthStorage.save(
        token: data['token'] as String,
        name: data['name'] as String,
        email: _emailCtrl.text.trim(),
        merchantId: data['merchantId'] as String,
      );
      if (mounted) context.go('/menu');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), behavior: SnackBarBehavior.floating, backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F4),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Hero header ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 48, 28, 36),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF34A853), Color(0xFF1B5E20)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(.2), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.store_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 20),
                  const Text('สร้างบัญชีใหม่', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  const Text('เริ่มต้นธุรกิจอาหารของคุณ', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ]),
              ),

              // ── Form card ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 4))],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    // section: personal
                    _SectionLabel('ข้อมูลส่วนตัว'),
                    const SizedBox(height: 10),
                    AuthField(ctrl: _nameCtrl, label: 'ชื่อ-นามสกุล', icon: Icons.person_outline, error: _nameErr, onChanged: (_) => setState(() => _nameErr = null)),
                    const SizedBox(height: 12),
                    AuthField(ctrl: _emailCtrl, label: 'อีเมล', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, error: _emailErr, onChanged: (_) => setState(() => _emailErr = null)),

                    const SizedBox(height: 20),
                    _SectionLabel('ข้อมูลร้านอาหาร'),
                    const SizedBox(height: 10),
                    AuthField(ctrl: _shopCtrl, label: 'ชื่อร้าน', icon: Icons.storefront_outlined, error: _shopErr, onChanged: (_) => setState(() => _shopErr = null)),

                    const SizedBox(height: 20),
                    _SectionLabel('รหัสผ่าน'),
                    const SizedBox(height: 10),
                    AuthField(
                      ctrl: _passCtrl, label: 'รหัสผ่าน', icon: Icons.lock_outline,
                      obscure: !_showPass, error: _passErr,
                      onChanged: (_) => setState(() => _passErr = null),
                      suffix: IconButton(
                        icon: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF9E9E9E)),
                        onPressed: () => setState(() => _showPass = !_showPass),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AuthField(
                      ctrl: _confirmCtrl, label: 'ยืนยันรหัสผ่าน', icon: Icons.lock_outline,
                      obscure: !_showConfirm, error: _confirmErr,
                      onChanged: (_) => setState(() => _confirmErr = null),
                      suffix: IconButton(
                        icon: Icon(_showConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF9E9E9E)),
                        onPressed: () => setState(() => _showConfirm = !_showConfirm),
                      ),
                    ),

                    const SizedBox(height: 24),
                    PrimaryBtn(label: 'สมัครสมาชิก', loading: _loading, onPressed: _register, color: const Color(0xFF34A853)),
                  ]),
                ),
              ),

              // ── Login link ───────────────────────────────────────────────
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('มีบัญชีแล้ว?', style: TextStyle(color: Color(0xFF5f6368), fontSize: 14)),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('เข้าสู่ระบบ', style: TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ]),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF5f6368), letterSpacing: .4));
}
