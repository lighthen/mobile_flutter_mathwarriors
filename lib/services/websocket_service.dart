import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';

class WebSocketNotification {
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;

  WebSocketNotification({
    required this.type,
    required this.title,
    required this.body,
    this.data,
  });

  factory WebSocketNotification.fromJson(Map<String, dynamic> json) {
    return WebSocketNotification(
      type: json['type'] as String? ?? 'info',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance {
    _instance ??= WebSocketService._();
    return _instance!;
  }

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _connected = false;
  bool _disposed = false;
  final List<Map<String, dynamic>> _pendingMessages = [];

  final _notificationController =
      StreamController<WebSocketNotification>.broadcast();

  Stream<WebSocketNotification> get notifications =>
      _notificationController.stream;
  bool get isConnected => _connected;

  WebSocketService._();

  String _getWebSocketUrl() => ApiConfig.wsUrl;

  Future<void> connect() async {
    if (_disposed || _connected) return;

    try {
      final url = _getWebSocketUrl();
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _connected = true;

      _flushPending();

      _channel!.stream.listen(
        (message) {
          try {
            final data = json.decode(message as String) as Map<String, dynamic>;
            final notification = WebSocketNotification.fromJson(data);
            _notificationController.add(notification);
          } catch (_) {}
        },
        onDone: () {
          _connected = false;
          _scheduleReconnect();
        },
        onError: (_) {
          _connected = false;
          _scheduleReconnect();
        },
      );
    } catch (_) {
      _connected = false;
      _scheduleReconnect();
    }
  }

  void _flushPending() {
    for (final msg in _pendingMessages) {
      _channel!.sink.add(json.encode(msg));
    }
    _pendingMessages.clear();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 10), () {
      if (!_disposed) {
        connect();
      }
    });
  }

  void sendMessage(Map<String, dynamic> data) {
    if (_connected && _channel != null) {
      _channel!.sink.add(json.encode(data));
    } else {
      _pendingMessages.add(data);
    }
  }

  void sendRegister(String username, int totalPoints) {
    sendMessage({
      'type': 'register',
      'username': username,
      'total_points': totalPoints,
    });
  }

  void sendScoreUpdate(String username, int totalPoints) {
    sendMessage({
      'type': 'score_update',
      'username': username,
      'total_points': totalPoints,
    });
  }

  void sendJoinGame(String username) {
    sendMessage({
      'type': 'join_game',
      'username': username,
    });
  }

  void disconnect() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _connected = false;
  }

  void dispose() {
    disconnect();
    _notificationController.close();
    _instance = null;
  }
}
