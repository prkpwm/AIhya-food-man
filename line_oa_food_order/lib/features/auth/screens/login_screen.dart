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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
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
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF7ECEC4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.restaurant, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 24),
              const Text('ยินดีต้อนรับ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('เข้าสู่ระบบสำหรับผู้ประกอบการ',
                  style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 15)),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20)],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'อีเมล',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'รหัสผ่าน',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    if (authState.hasError) ...[
                      const SizedBox(height: 12),
                      Text(authState.error.toString(),
                          style: const TextStyle(color: Color(0xFFF44336), fontSize: 13)),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _login,
                        child: authState.isLoading
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('เข้าสู่ระบบ'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('ยังไม่มีบัญชี? สมัครสมาชิก',
                      style: TextStyle(color: Color(0xFF1A1A1A))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
