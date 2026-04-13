import 'package:dio/dio.dart';
import 'package:line_oa_food_order/core/models/user_model.dart';
import 'package:line_oa_food_order/core/services/api_service.dart';
import 'package:line_oa_food_order/core/services/auth_storage.dart';

class AuthService {
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  Future<UserModel> login(String email, String password) async {
    try {
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
        id: token,
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
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map) {
        final th = body['th'] as String?;
        final en = body['en'] as String?;
        throw Exception(th ?? en ?? 'เกิดข้อผิดพลาด');
      }
      throw Exception('เกิดข้อผิดพลาด กรุณาลองใหม่');
    }
  }

  Future<void> logout() async {
    await AuthStorage.clear();
    _currentUser = null;
  }
}
