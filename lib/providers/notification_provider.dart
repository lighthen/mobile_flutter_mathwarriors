import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/fcm_service.dart';
import '../services/notification_service.dart';
import '../services/websocket_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService.instance;
  final WebSocketService _webSocketService = WebSocketService.instance;

  StreamSubscription<WebSocketNotification>? _wsSubscription;
  StreamSubscription<Map<String, String>>? _fcmSubscription;

  int _notificationCount = 0;
  String? _lastBeatenBy;
  int? _lastBeatenNewScore;

  int get notificationCount => _notificationCount;
  bool get connected => _webSocketService.isConnected;
  String? get lastBeatenBy => _lastBeatenBy;
  int? get lastBeatenNewScore => _lastBeatenNewScore;

  Future<void> init() async {
    await _notificationService.init();

    _webSocketService.connect();

    _fcmSubscription = FcmService.instance.onScoreBeaten.listen((data) {
      final beatenBy = data['beaten_by'] ?? '';
      final newScore = int.tryParse(data['beaten_by_points'] ?? '0') ?? 0;
      _lastBeatenBy = beatenBy;
      _lastBeatenNewScore = newScore;
      _notificationCount++;
      notifyListeners();
    });

    _wsSubscription = _webSocketService.notifications.listen((notification) {
      _notificationCount++;
      notifyListeners();

      if (notification.type == 'score_beaten') {
        final beatenBy = notification.data?['beaten_by'] as String? ?? '';
        final newScore = notification.data?['beaten_by_points'] as int? ?? 0;
        _lastBeatenBy = beatenBy;
        _lastBeatenNewScore = newScore;

        _notificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: '⚠️ Skor Terlewati!',
          body: '$beatenBy melewati skor kamu ($newScore pts)! Ayo main lagi!',
          payload: 'score_beaten',
        );
      } else {
        _notificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: notification.title,
          body: notification.body,
          payload: notification.type,
        );
      }
    });
  }

  void clearBeatenIndicator() {
    _lastBeatenBy = null;
    _lastBeatenNewScore = null;
    notifyListeners();
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notificationService.showNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> showGameCompleteNotification({
    required int score,
    required int correctCount,
    required int totalQuestions,
  }) async {
    await _notificationService.showGameCompleteNotification(
      score: score,
      correctCount: correctCount,
      totalQuestions: totalQuestions,
    );
  }

  void clearNotifications() {
    _notificationCount = 0;
    notifyListeners();
  }

  void connectWebSocket() {
    _webSocketService.connect();
  }

  void sendJoinGame(String username) {
    _webSocketService.sendJoinGame(username);
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _fcmSubscription?.cancel();
    super.dispose();
  }
}
