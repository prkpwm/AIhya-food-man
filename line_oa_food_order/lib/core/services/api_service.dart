import 'dart:typed_data';
import 'package:dio/dio.dart';

class ApiService {
  static const String _prod = 'https://aihya-food-man.onrender.com';

  static String get baseUrl => _prod;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<Map<String, dynamic>> deployCustomerMenu({
    required String shopName,
    required Uint8List imageBytes,
    String imageType = 'image/png',
  }) async {
    final form = FormData.fromMap({
      'shopName': shopName,
      'image': MultipartFile.fromBytes(
        imageBytes,
        filename: 'rich_menu.png',
        contentType: DioMediaType.parse(imageType),
      ),
    });
    final res = await _dio.post('/rich-menu/deploy/customer', data: form);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deployMerchantMenu({
    required String shopName,
    required Uint8List imageBytes,
    String imageType = 'image/png',
  }) async {
    final form = FormData.fromMap({
      'shopName': shopName,
      'image': MultipartFile.fromBytes(
        imageBytes,
        filename: 'rich_menu.png',
        contentType: DioMediaType.parse(imageType),
      ),
    });
    final res = await _dio.post('/rich-menu/deploy/merchant', data: form);
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
