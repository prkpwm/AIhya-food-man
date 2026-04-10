import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิก')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TextField(decoration: const InputDecoration(labelText: 'ชื่อร้าน', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(decoration: const InputDecoration(labelText: 'อีเมล', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(decoration: const InputDecoration(labelText: 'รหัสผ่าน', border: OutlineInputBorder()), obscureText: true),
              const SizedBox(height: 16),
              TextField(decoration: const InputDecoration(labelText: 'LINE Channel ID', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(decoration: const InputDecoration(labelText: 'LINE Channel Secret', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/menu'),
                  child: const Text('สมัครสมาชิก'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
