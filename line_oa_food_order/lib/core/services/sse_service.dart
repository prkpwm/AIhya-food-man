import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewOrderEvent {
  final String orderId;
  final String customerName;
  final double totalPrice;
  const NewOrderEvent({required this.orderId, required this.customerName, required this.totalPrice});

  factory NewOrderEvent.fromJson(Map<String, dynamic> json) => NewOrderEvent(
        orderId: json['orderId'] as String,
        customerName: json['customerName'] as String,
        totalPrice: (json['totalPrice'] as num).toDouble(),
      );
}

class SseService {
  static const _baseUrl = 'https://aihya-food-man.onrender.com/api';

  final _controller = StreamController<NewOrderEvent>.broadcast();
  Stream<NewOrderEvent> get stream => _controller.stream;

  CancelToken? _cancelToken;
  bool _running = false;

  Future<void> connect() async {
    if (_running) return;
    _running = true;
    _listen();
  }

  void disconnect() {
    _running = false;
    _cancelToken?.cancel();
    _controller.close();
  }

  Future<void> _listen() async {
    while (_running) {
      _cancelToken = CancelToken();
      try {
        final dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          responseType: ResponseType.stream,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 10),
        ));

        final res = await dio.get<ResponseBody>(
          '/orders/events',
          cancelToken: _cancelToken,
        );

        final body = res.data!;
        String buffer = '';

        await for (final chunk in body.stream) {
          buffer += utf8.decode(chunk);
          final lines = buffer.split('\n');
          buffer = lines.removeLast(); // keep incomplete line

          String? eventType;
          for (final line in lines) {
            if (line.startsWith('event:')) {
              eventType = line.substring(6).trim();
            } else if (line.startsWith('data:') && eventType == 'new-order') {
              final raw = line.substring(5).trim();
              try {
                final json = jsonDecode(raw) as Map<String, dynamic>;
                _controller.add(NewOrderEvent.fromJson(json));
              } catch (_) {}
              eventType = null;
            }
          }
        }
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel || !_running) break;
      } catch (_) {}

      // reconnect after 3s on error
      if (_running) await Future.delayed(const Duration(seconds: 3));
    }
  }
}

final sseServiceProvider = Provider<SseService>((ref) {
  final svc = SseService();
  ref.onDispose(svc.disconnect);
  return svc;
});
