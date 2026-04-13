import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_oa_food_order/features/auth/providers/auth_provider.dart';

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
    await ref.read(authProvider.notifier).login(
      _emailCtrl.text.trim(), _passCtrl.text.trim(),
    );
    final s = ref.read(authProvider);
    if (s.hasValue && s.value != null && mounted) context.go('/menu');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // logo
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF7ECEC4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.restaurant, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 24),
              const Text('ยินดีต้อนรับ',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('เข้าสู่ระบบสำหรับผู้ประกอบการ',
                  style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 15)),
              const SizedBox(height: 40),

              // form card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20)],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(children: [

                  // email field
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() => _emailErr = null),
                    decoration: InputDecoration(
                      labelText: 'อีเมล',
                      prefixIcon: const Icon(Icons.email_outlined),
                      errorText: _emailErr,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // password field with show/hide
                  TextField(
                    controller: _passCtrl,
                    obscureText: !_showPass,
                    onChanged: (_) => setState(() => _passErr = null),
                    decoration: InputDecoration(
                      labelText: 'รหัสผ่าน',
                      prefixIcon: const Icon(Icons.lock_outline),
                      errorText: _passErr,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                          color: const Color(0xFF9E9E9E),
                        ),
                        onPressed: () => setState(() => _showPass = !_showPass),
                      ),
                    ),
                  ),

                  // api error banner
                  if (authState.hasError) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: Color(0xFFE53935), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.error.toString().replaceAll('Exception: ', ''),
                            style: const TextStyle(color: Color(0xFFE53935), fontSize: 13),
                          ),
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // login button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _login,
                      child: authState.isLoading
                          ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('เข้าสู่ระบบ'),
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // register link
              Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('ยังไม่มีบัญชี?',
                      style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14)),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('สมัครสมาชิก',
                        style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
