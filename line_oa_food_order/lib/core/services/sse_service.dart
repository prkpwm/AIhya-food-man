import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

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
  static const _url = 'https://aihya-food-man.onrender.com/api/orders/events';

  final _controller = StreamController<NewOrderEvent>.broadcast();
  Stream<NewOrderEvent> get stream => _controller.stream;

  // mobile
  CancelToken? _cancelToken;
  bool _running = false;

  // web
  js.JsObject? _eventSource;

  Future<void> connect() async {
    if (_running) return;
    _running = true;
    debugPrint('[SSE] connecting to $_url (web=$kIsWeb)');
    if (kIsWeb) {
      _connectWeb();
    } else {
      _listenMobile();
    }
  }

  void disconnect() {
    _running = false;
    _cancelToken?.cancel();
    _eventSource?.callMethod('close');
    _eventSource = null;
    if (!_controller.isClosed) _controller.close();
  }

  // ─── Web: use native EventSource ─────────────────────────────────────────

  void _connectWeb() {
    try {
      _eventSource = js.JsObject(js.context['EventSource'] as js.JsFunction, [_url]);
      _eventSource!.callMethod('addEventListener', [
        'new-order',
        js.JsFunction.withThis((_, event) {
          final jsEvent = js.JsObject.fromBrowserObject(event);
          final data = jsEvent['data'] as String?;
          if (data == null) return;
          debugPrint('[SSE] web event data: $data');
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            _controller.add(NewOrderEvent.fromJson(json));
            debugPrint('[SSE] emitted NewOrderEvent');
          } catch (e) {
            debugPrint('[SSE] parse error: $e');
          }
        }),
      ]);
      _eventSource!.callMethod('addEventListener', [
        'error',
        js.JsFunction.withThis((_, __) {
          debugPrint('[SSE] web EventSource error, reconnecting...');
          _eventSource?.callMethod('close');
          if (_running) {
            Future.delayed(const Duration(seconds: 3), _connectWeb);
          }
        }),
      ]);
      debugPrint('[SSE] web EventSource created');
    } catch (e) {
      debugPrint('[SSE] web connect error: $e');
    }
  }

  // ─── Mobile: Dio streaming ────────────────────────────────────────────────

  Future<void> _listenMobile() async {
    while (_running) {
      _cancelToken = CancelToken();
      try {
        final dio = Dio(BaseOptions(
          responseType: ResponseType.stream,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 10),
        ));

        final res = await dio.get<ResponseBody>(_url, cancelToken: _cancelToken);
        final body = res.data!;
        String buffer = '';
        debugPrint('[SSE] mobile stream connected');

        await for (final chunk in body.stream) {
          buffer += utf8.decode(chunk);
          final lines = buffer.split('\n');
          buffer = lines.removeLast();

          String? eventType;
          for (final line in lines) {
            if (line.startsWith('event:')) {
              eventType = line.substring(6).trim();
            } else if (line.startsWith('data:') && eventType == 'new-order') {
              final raw = line.substring(5).trim();
              debugPrint('[SSE] mobile data: $raw');
              try {
                final json = jsonDecode(raw) as Map<String, dynamic>;
                _controller.add(NewOrderEvent.fromJson(json));
                debugPrint('[SSE] emitted NewOrderEvent');
              } catch (e) {
                debugPrint('[SSE] parse error: $e');
              }
              eventType = null;
            }
          }
        }
      } on DioException catch (e) {
        debugPrint('[SSE] DioException: ${e.type}');
        if (e.type == DioExceptionType.cancel || !_running) break;
      } catch (e) {
        debugPrint('[SSE] error: $e');
      }
      if (_running) await Future.delayed(const Duration(seconds: 3));
    }
  }
}

final sseServiceProvider = Provider<SseService>((ref) {
  final svc = SseService();
  ref.onDispose(svc.disconnect);
  return svc;
});
