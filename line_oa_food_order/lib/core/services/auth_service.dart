import 'package:line_oa_food_order/core/models/user_model.dart';
import 'package:line_oa_food_order/core/services/api_service.dart';
import 'package:line_oa_food_order/core/services/auth_storage.dart';

class AuthService {
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  Future<UserModel> login(String email, String password) async {
    final data = await ApiService().login(email, password);
    final token = data['token'] as String;
    final name = data['name'] as String;
    final merchantId = data['merchantId'] as String? ?? '';

    await AuthStorage.save(
      token: token,
      name: name,
      email: email,
      merchantId: merchantId,
    );

    final user = UserModel(
      id: token, // use token as transient id
      email: email,
      password: '',
      shopName: name,
      lineChannelId: '',
      lineChannelSecret: '',
      tier: SubscriptionTier.free,
      subscriptionExpiry: DateTime.now().add(const Duration(days: 30)),
    );
    _currentUser = user;
    return user;
  }

  Future<void> logout() async {
    await AuthStorage.clear();
    _currentUser = null;
  }
}
