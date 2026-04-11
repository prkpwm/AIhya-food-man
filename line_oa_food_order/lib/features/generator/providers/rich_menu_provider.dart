import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import 'package:line_oa_food_order/core/services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class RichMenuNotifier extends AsyncNotifier<List<dynamic>> {
  @override
  Future<List<dynamic>> build() => ref.read(apiServiceProvider).listRichMenus();

  Future<String?> deployCustomer(String shopName, Uint8List imageBytes, {bool large = false}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final res = await ref.read(apiServiceProvider).deployCustomerMenu(
            shopName: shopName,
            imageBytes: imageBytes,
            large: large,
          );
      await refresh();
      return res['data']['richMenuId'] as String;
    });
    state = await AsyncValue.guard(() => ref.read(apiServiceProvider).listRichMenus());
    return result.valueOrNull;
  }

  Future<String?> deployMerchant(String shopName, Uint8List imageBytes, {bool large = false}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final res = await ref.read(apiServiceProvider).deployMerchantMenu(
            shopName: shopName,
            imageBytes: imageBytes,
            large: large,
          );
      await refresh();
      return res['data']['richMenuId'] as String;
    });
    state = await AsyncValue.guard(() => ref.read(apiServiceProvider).listRichMenus());
    return result.valueOrNull;
  }

  Future<void> delete(String richMenuId) async {
    await ref.read(apiServiceProvider).deleteRichMenu(richMenuId);
    await refresh();
  }

  Future<void> refresh() async {
    state = AsyncData(await ref.read(apiServiceProvider).listRichMenus());
  }
}

final richMenuProvider = AsyncNotifierProvider<RichMenuNotifier, List<dynamic>>(RichMenuNotifier.new);
