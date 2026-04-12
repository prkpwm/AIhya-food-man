import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/menu')) return 0;
    if (path.startsWith('/orders')) return 1;
    if (path.startsWith('/stock')) return 2;
    if (path.startsWith('/generator')) return 3;
    if (path.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20)],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'เมนู', index: 0, selected: selected, onTap: () => context.go('/menu')),
                _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'ออเดอร์', index: 1, selected: selected, onTap: () => context.go('/orders')),
                _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'สต๊อก', index: 2, selected: selected, onTap: () => context.go('/stock')),
                _NavItem(icon: Icons.code_outlined, activeIcon: Icons.code, label: 'Generator', index: 3, selected: selected, onTap: () => context.go('/generator')),
                _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'ตั้งค่า', index: 4, selected: selected, onTap: () => context.go('/settings')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selected;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1A1A1A) : Colors.transparent,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? const Color(0xFF1A1A1A) : const Color(0xFF9E9E9E),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
