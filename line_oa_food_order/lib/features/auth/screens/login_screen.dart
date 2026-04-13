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
    final state = ref.read(authProvider);
    if (state.hasValue && state.value != null && mounted) {
      context.go('/menu');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F4),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Hero header ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 52, 28, 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
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
                    child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 20),
                  const Text('ยินดีต้อนรับ', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  const Text('เข้าสู่ระบบสำหรับผู้ประกอบการ', style: TextStyle(color: Colors.white70, fontSize: 14)),
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
                  child: Column(children: [
                    // email
                    AuthField(
                      ctrl: _emailCtrl,
                      label: 'อีเมล',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      error: _emailErr,
                      onChanged: (_) => setState(() => _emailErr = null),
                    ),
                    const SizedBox(height: 16),

                    // password
                    AuthField(
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
                      const SizedBox(height: 12),
                      ErrorBanner(authState.error.toString()),
                    ],

                    const SizedBox(height: 24),
                    PrimaryBtn(
                      label: 'เข้าสู่ระบบ',
                      loading: authState.isLoading,
                      onPressed: _login,
                    ),
                  ]),
                ),
              ),

              // ── Register link ────────────────────────────────────────────
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('ยังไม่มีบัญชี?', style: TextStyle(color: Color(0xFF5f6368), fontSize: 14)),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('สมัครสมาชิก', style: TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
