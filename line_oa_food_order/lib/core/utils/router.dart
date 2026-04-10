import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:line_oa_food_order/features/auth/screens/login_screen.dart';
import 'package:line_oa_food_order/features/auth/screens/register_screen.dart';
import 'package:line_oa_food_order/features/menu/screens/menu_list_screen.dart';
import 'package:line_oa_food_order/features/order/screens/order_list_screen.dart';
import 'package:line_oa_food_order/features/stock/screens/stock_screen.dart';
import 'package:line_oa_food_order/features/generator/screens/generator_screen.dart';
import 'package:line_oa_food_order/features/subscription/screens/subscription_screen.dart';
import 'package:line_oa_food_order/shared/widgets/main_scaffold.dart';

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    ShellRoute(
      builder: (_, __, child) => MainScaffold(child: child),
      routes: [
        GoRoute(path: '/menu', builder: (_, __) => const MenuListScreen()),
        GoRoute(path: '/orders', builder: (_, __) => const OrderListScreen()),
        GoRoute(path: '/stock', builder: (_, __) => const StockScreen()),
        GoRoute(path: '/generator', builder: (_, __) => const GeneratorScreen()),
        GoRoute(path: '/subscription', builder: (_, __) => const SubscriptionScreen()),
      ],
    ),
  ],
);
