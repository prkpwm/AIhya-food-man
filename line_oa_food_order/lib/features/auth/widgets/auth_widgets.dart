import 'package:flutter/material.dart';

class AuthField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool obscure;
  final String? error;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  const AuthField({
    super.key,
    required this.ctrl, required this.label, required this.icon,
    this.obscure = false, this.error, this.keyboardType, this.onChanged, this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF9E9E9E)),
          suffixIcon: suffix,
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAED))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: error != null ? Colors.red.shade300 : const Color(0xFFE8EAED))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: error != null ? Colors.red : const Color(0xFF1A73E8), width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
      if (error != null) ...[
        const SizedBox(height: 5),
        Row(children: [
          const Icon(Icons.error_outline, size: 13, color: Colors.red),
          const SizedBox(width: 4),
          Text(error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
        ]),
      ],
    ]);
  }
}

class PrimaryBtn extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  final Color color;
  const PrimaryBtn({super.key, required this.label, required this.loading, required this.onPressed, this.color = const Color(0xFF1A73E8)});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: loading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    ),
  );
}

class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner(this.message, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
    child: Row(children: [
      Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(message.replaceAll('Exception: ', ''), style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
    ]),
  );
}
