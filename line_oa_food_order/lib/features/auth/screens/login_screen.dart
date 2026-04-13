import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_oa_food_order/features/auth/providers/auth_provider.dart';
import 'package:line_oa_food_order/features/auth/widgets/auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'test01@lineoa.com');
  final _passCtrl = TextEditingController(text: '123456');
  bool _showPass = false;
  String? _emailErr;
  String? _passErr;

  static const _teal = Color(0xFF7ECEC4);
  static const _dark = Color(0xFF1A1A1A);
  static const _bg = Color(0xFFF2F2F2);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    String? eErr, pErr;
    if (_emailCtrl.text.trim().isEmpty) eErr = 'กรุณากรอกอีเมล';
    if (_passCtrl.text.isEmpty) pErr = 'กรุณากรอกรหัสผ่าน';
    setState(() { _emailErr = eErr; _passErr = pErr; });
    return eErr == null && pErr == null;
  }

  Future<void> _login() async {
    if (!_validate()) return;
    await ref.read(authProvider.notifier).login(_emailCtrl.text.trim(), _passCtrl.text.trim());
    final s = ref.read(authProvider);
    if (s.hasValue && s.value != null && mounted) context.go('/menu');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Top dark section with logo ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 52, 28, 40),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // logo badge
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 28),
                  const Text('ยินดีต้อนรับ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1)),
                  const SizedBox(height: 8),
                  Text('เข้าสู่ระบบสำหรับผู้ประกอบการ', style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 14)),
                ]),
              ),

              // ── White card ────────────────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('เข้าสู่ระบบ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _dark)),
                  const SizedBox(height: 24),

                  // email
                  _ThemedField(
                    ctrl: _emailCtrl,
                    label: 'อีเมล',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    error: _emailErr,
                    onChanged: (_) => setState(() => _emailErr = null),
                  ),
                  const SizedBox(height: 16),

                  // password
                  _ThemedField(
                    ctrl: _passCtrl,
                    label: 'รหัสผ่าน',
                    icon: Icons.lock_outline,
                    obscure: !_showPass,
                    error: _passErr,
                    onChanged: (_) => setState(() => _passErr = null),
                    suffix: IconButton(
                      icon: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF9E9E9E)),
                      onPressed: () => setState(() => _showPass = !_showPass),
                    ),
                  ),

                  // api error
                  if (authState.hasError) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
                      child: Row(children: [
                        Icon(Icons.error_outline, color: Colors.red.shade400, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(authState.error.toString().replaceAll('Exception: ', ''), style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // login button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _dark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: authState.isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('เข้าสู่ระบบ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // register link
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('ยังไม่มีบัญชี?', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14)),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      style: TextButton.styleFrom(foregroundColor: _teal),
                      child: const Text('สมัครสมาชิก', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ]),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Themed field matching app style ─────────────────────────────────────────

class _ThemedField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool obscure;
  final String? error;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  const _ThemedField({required this.ctrl, required this.label, required this.icon, this.obscure = false, this.error, this.keyboardType, this.onChanged, this.suffix});

  @override
  Widget build(BuildContext context) {
    final hasErr = error != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF9E9E9E)),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: hasErr ? Colors.red.shade300 : Colors.transparent)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: hasErr ? Colors.red : const Color(0xFF7ECEC4), width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      if (hasErr) ...[
        const SizedBox(height: 5),
        Row(children: [
          const SizedBox(width: 4),
          const Icon(Icons.error_outline, size: 13, color: Colors.red),
          const SizedBox(width: 4),
          Text(error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
        ]),
      ],
    ]);
  }
}
