import 'package:dio/dio.dart';

class ApiService {
  static const String _prod = 'https://aihya-food-man.onrender.com';
  static const String _dev = 'http://localhost:3000';

  static String get baseUrl => _prod;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<Map<String, dynamic>> deployCustomerMenu({
    required String shopName,
    required String imageBase64,
    String imageType = 'image/png',
  }) async {
    final res = await _dio.post('/rich-menu/deploy/customer', data: {
      'shopName': shopName,
      'imageBase64': imageBase64,
      'imageType': imageType,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deployMerchantMenu({
    required String shopName,
    required String imageBase64,
    String imageType = 'image/png',
  }) async {
    final res = await _dio.post('/rich-menu/deploy/merchant', data: {
      'shopName': shopName,
      'imageBase64': imageBase64,
      'imageType': imageType,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> listRichMenus() async {
    try {
      final res = await _dio.get('/rich-menu');
      final data = res.data as Map<String, dynamic>;
      return data['data'] as List<dynamic>;
    } on DioException {
      return [];
    }
  }

  Future<void> deleteRichMenu(String richMenuId) async {
    await _dio.delete('/rich-menu/$richMenuId');
  }
}
