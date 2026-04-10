import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:line_oa_food_order/core/models/user_model.dart';
import 'package:line_oa_food_order/core/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final currentUserProvider = StateProvider<UserModel?>((ref) => null);

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async => null;

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(authServiceProvider);
      final user = await service.login(email, password);
      ref.read(currentUserProvider.notifier).state = user;
      return user;
    });
  }

  void logout() {
    ref.read(authServiceProvider).logout();
    ref.read(currentUserProvider.notifier).state = null;
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);
