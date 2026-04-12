// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

abstract class SseConnector {
  void connect();
  void disconnect();
}

SseConnector createSseConnector({
  required String url,
  required void Function(String data) onEvent,
  required void Function(dynamic error) onError,
}) => _WebSseConnector(url: url, onEvent: onEvent, onError: onError);

class _WebSseConnector implements SseConnector {
  final String url;
  final void Function(String) onEvent;
  final void Function(dynamic) onError;
  js.JsObject? _es;

  _WebSseConnector({required this.url, required this.onEvent, required this.onError});

  @override
  void connect() {
    try {
      _es = js.JsObject(js.context['EventSource'] as js.JsFunction, [url]);
      _es!.callMethod('addEventListener', [
        'new-order',
        js.JsFunction.withThis((_, event) {
          final jsEvent = js.JsObject.fromBrowserObject(event);
          final data = jsEvent['data'] as String?;
          if (data != null) onEvent(data);
        }),
      ]);
      _es!.callMethod('addEventListener', [
        'error',
        js.JsFunction.withThis((_, __) {
          onError('EventSource error');
          _es?.callMethod('close');
          Future.delayed(const Duration(seconds: 3), connect);
        }),
      ]);
    } catch (e) {
      onError(e);
    }
  }

  @override
  void disconnect() {
    _es?.callMethod('close');
    _es = null;
  }
}
