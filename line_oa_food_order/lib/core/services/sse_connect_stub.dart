// Stub — should never be used at runtime
abstract class SseConnector {
  void connect();
  void disconnect();
}

SseConnector createSseConnector({
  required String url,
  required void Function(String data) onEvent,
  required void Function(dynamic error) onError,
}) {
  throw UnsupportedError('No SSE connector for this platform');
}
