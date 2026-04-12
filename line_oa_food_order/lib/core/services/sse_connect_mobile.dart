import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

abstract class SseConnector {
  void connect();
  void disconnect();
}

SseConnector createSseConnector({
  required String url,
  required void Function(String data) onEvent,
  required void Function(dynamic error) onError,
}) => _MobileSseConnector(url: url, onEvent: onEvent, onError: onError);

class _MobileSseConnector implements SseConnector {
  final String url;
  final void Function(String) onEvent;
  final void Function(dynamic) onError;

  CancelToken? _cancelToken;
  bool _active = false;

  _MobileSseConnector({required this.url, required this.onEvent, required this.onError});

  @override
  void connect() {
    _active = true;
    _listen();
  }

  @override
  void disconnect() {
    _active = false;
    _cancelToken?.cancel();
  }

  Future<void> _listen() async {
    while (_active) {
      _cancelToken = CancelToken();
      try {
        final dio = Dio(BaseOptions(
          responseType: ResponseType.stream,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 10),
        ));
        final res = await dio.get<ResponseBody>(url, cancelToken: _cancelToken);
        String buffer = '';
        await for (final chunk in res.data!.stream) {
          buffer += utf8.decode(chunk);
          final lines = buffer.split('\n');
          buffer = lines.removeLast();
          String? eventType;
          for (final line in lines) {
            if (line.startsWith('event:')) {
              eventType = line.substring(6).trim();
            } else if (line.startsWith('data:') && eventType == 'new-order') {
              onEvent(line.substring(5).trim());
              eventType = null;
            }
          }
        }
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel || !_active) break;
        onError(e);
      } catch (e) {
        onError(e);
      }
      if (_active) await Future.delayed(const Duration(seconds: 3));
    }
  }
}
