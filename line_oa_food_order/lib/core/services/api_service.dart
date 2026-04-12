import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class RetryInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout) {
      try {
        await Future.delayed(const Duration(seconds: 2));
        final res = await Dio(err.requestOptions.extra['baseOptions'] as BaseOptions? ??
                BaseOptions(baseUrl: err.requestOptions.baseUrl))
            .fetch(err.requestOptions);
        return handler.resolve(res);
      } catch (_) {}
    }
    handler.next(err);
  }
}

class ApiService {
  static const String _prod = 'https://aihya-food-man.onrender.com/api';
  static const String _nextProd = 'https://line-oa-next.onrender.com/api';
  static const String _local = 'http://localhost:3001/api';
  // Use local Next.js API when running in debug mode on web (avoids CORS — Next.js adds headers)
  // static String get baseUrl => (kIsWeb && kDebugMode) ? _local : _prod;
  static String get baseUrl => _prod;
  static String get nextBaseUrl =>  _prod;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 90),
    receiveTimeout: const Duration(seconds: 90),
  ))..interceptors.add(RetryInterceptor());

  // Dio instance pointing to Next.js (has LINE push/broadcast endpoints with proper error handling)
  final Dio _nextDio = Dio(BaseOptions(
    baseUrl: nextBaseUrl,
    connectTimeout: const Duration(seconds: 90),
    receiveTimeout: const Duration(seconds: 90),
  ))..interceptors.add(RetryInterceptor());


  Future<Map<String, dynamic>> createMenu({
    required Map<String, String> data,
    Uint8List? imageBytes,
    String imageName = 'menu.jpg',
  }) async {
    final form = FormData.fromMap({
      ...data,
      if (imageBytes != null)
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: imageName,
          contentType: DioMediaType.parse(imageName.endsWith('.png') ? 'image/png' : 'image/jpeg'),
        ),
    });
    final res = await _dio.post('/menus', data: form);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMenu({
    required String id,
    required Map<String, String> data,
    Uint8List? imageBytes,
    String imageName = 'menu.jpg',
  }) async {
    final form = FormData.fromMap({
      ...data,
      if (imageBytes != null)
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: imageName,
          contentType: DioMediaType.parse(imageName.endsWith('.png') ? 'image/png' : 'image/jpeg'),
        ),
    });
    final res = await _dio.put('/menus/$id', data: form);
    return res.data as Map<String, dynamic>;
  }

  Future<void> toggleMenuAvailable(String id, bool isAvailable) async {
    await _dio.patch('/menus/$id/available', data: {'isAvailable': isAvailable});
  }

  // ─── Menus ──────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getMenus({String merchantId = 'merchant-001'}) async {
    final res = await _dio.get('/menus', queryParameters: {'merchantId': merchantId});
    return (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
  }

  // ─── Stock ──────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getStock({String merchantId = 'merchant-001'}) async {
    final res = await _dio.get('/stock', queryParameters: {'merchantId': merchantId});
    return (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
  }

  Future<void> updateStock(String id, double quantity) async {
    await _dio.patch('/stock/$id', data: {'quantity': quantity});
  }

  Future<void> broadcastFlex(String flexJson) async {
    await _nextDio.post('/broadcast/flex', data: {'flexJson': flexJson});
  }

  Future<void> pushFlex(String userId, String flexJson) async {
    await _nextDio.post('/broadcast/flex', data: {'flexJson': flexJson});
  }

  Future<Map<String, dynamic>> addIngredient(Map<String, dynamic> data) async {
    final res = await _dio.post('/stock', data: data);
    return res.data as Map<String, dynamic>;
  }

  // ─── Orders ─────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getOrders({String merchantId = 'merchant-001'}) async {
    final res = await _dio.get('/orders', queryParameters: {'merchantId': merchantId});
    return (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> updateOrderStatus(String id, String status) async {
    final res = await _nextDio.patch('/orders/$id/status', data: {'status': status});
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getOrderQueueInfo(String id) async {
    final res = await _nextDio.get('/orders/$id/queue');
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getGroupedOrders({String merchantId = 'merchant-001'}) async {
    final res = await _dio.get('/orders/grouped', queryParameters: {'merchantId': merchantId});
    return (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  // ─── Rich Menu ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> deployCustomerMenu({
    required String shopName,
    required Uint8List imageBytes,
    String imageType = 'image/png',
    bool large = false,
  }) async {
    final form = FormData.fromMap({
      'shopName': shopName,
      'large': large.toString(),
      'image': MultipartFile.fromBytes(imageBytes, filename: 'rich_menu.png', contentType: DioMediaType.parse(imageType)),
    });
    final res = await _dio.post('/rich-menu/deploy/customer', data: form);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deployMerchantMenu({
    required String shopName,
    required Uint8List imageBytes,
    String imageType = 'image/png',
    bool large = false,
  }) async {
    final form = FormData.fromMap({
      'shopName': shopName,
      'large': large.toString(),
      'image': MultipartFile.fromBytes(imageBytes, filename: 'rich_menu.png', contentType: DioMediaType.parse(imageType)),
    });
    final res = await _dio.post('/rich-menu/deploy/merchant', data: form);
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> listRichMenus() async {
    try {
      final res = await _dio.get('/rich-menu');
      return (res.data as Map<String, dynamic>)['data'] as List<dynamic>;
    } on DioException {
      return [];
    }
  }

  Future<void> deleteRichMenu(String richMenuId) async {
    await _dio.delete('/rich-menu/$richMenuId');
  }
}
