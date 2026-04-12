import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// conditional import: web uses EventSource, others use Dio streaming
import 'sse_connect_stub.dart'
    if (dart.library.js) 'sse_connect_web.dart'
    if (dart.library.io) 'sse_connect_mobile.dart';

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
  static const url = 'https://aihya-food-man.onrender.com/api/orders/events';

  final _controller = StreamController<NewOrderEvent>.broadcast();
  Stream<NewOrderEvent> get stream => _controller.stream;

  bool _running = false;
  SseConnector? _connector;

  Future<void> connect() async {
    if (_running) return;
    _running = true;
    debugPrint('[SSE] connecting (web=$kIsWeb)');
    _connector = createSseConnector(
      url: url,
      onEvent: (data) {
        debugPrint('[SSE] event: $data');
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          _controller.add(NewOrderEvent.fromJson(json));
        } catch (e) {
          debugPrint('[SSE] parse error: $e');
        }
      },
      onError: (e) => debugPrint('[SSE] error: $e'),
    );
    _connector!.connect();
  }

  void disconnect() {
    _running = false;
    _connector?.disconnect();
    if (!_controller.isClosed) _controller.close();
  }
}

final sseServiceProvider = Provider<SseService>((ref) {
  final svc = SseService();
  ref.onDispose(svc.disconnect);
  return svc;
});
