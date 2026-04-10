import 'package:line_oa_food_order/core/data/mock_data.dart';
import 'package:line_oa_food_order/core/models/user_model.dart';

class AuthService {
  // mock users list — เพิ่มได้ในอนาคต
  static final _users = [mockUser];

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  Future<UserModel> login(String email, String password) async {
    // simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final user = _users.where((u) => u.email == email && u.password == password).firstOrNull;

    if (user == null) {
      throw Exception('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
    }

    _currentUser = user;
    return user;
  }

  void logout() => _currentUser = null;
}
