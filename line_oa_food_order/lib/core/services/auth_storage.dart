import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _keyToken = 'auth_token';
  static const _keyName = 'auth_name';
  static const _keyEmail = 'auth_email';
  static const _keyMerchantId = 'auth_merchant_id';

  static Future<void> save({
    required String token,
    required String name,
    required String email,
    required String merchantId,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyToken, token);
    await p.setString(_keyName, name);
    await p.setString(_keyEmail, email);
    await p.setString(_keyMerchantId, merchantId);
  }

  static Future<String?> getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyToken);
  }

  static Future<Map<String, String?>> getAll() async {
    final p = await SharedPreferences.getInstance();
    return {
      'token': p.getString(_keyToken),
      'name': p.getString(_keyName),
      'email': p.getString(_keyEmail),
      'merchantId': p.getString(_keyMerchantId),
    };
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_keyToken);
    await p.remove(_keyName);
    await p.remove(_keyEmail);
    await p.remove(_keyMerchantId);
  }
}
