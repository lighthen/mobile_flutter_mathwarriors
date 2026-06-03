import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final notification = message.notification;
  if (notification != null) {
    NotificationService.instance.showNotification(
      id: message.messageId.hashCode,
      title: notification.title ?? 'MathWarriors',
      body: notification.body ?? '',
      payload: message.data['type'],
    );
  }
}

class FcmService {
  static FcmService? _instance;
  static FcmService get instance {
    _instance ??= FcmService._();
    return _instance!;
  }

  late final FirebaseMessaging _messaging;
  final ApiService _api = ApiService();
  final _scoreBeatenController = StreamController<Map<String, String>>.broadcast();

  Stream<Map<String, String>> get onScoreBeaten => _scoreBeatenController.stream;
  String? _currentToken;

  FcmService._();

  Future<void> init() async {
    await Firebase.initializeApp();
    _messaging = FirebaseMessaging.instance;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Izin notifikasi ditolak');
      return;
    }

    _currentToken = await _messaging.getToken();
    debugPrint('[FCM] Token: $_currentToken');

    _messaging.onTokenRefresh.listen((token) {
      _currentToken = token;
      _sendTokenToBackend();
      debugPrint('[FCM] Token refreshed: $token');
    });

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        NotificationService.instance.showNotification(
          id: message.messageId.hashCode,
          title: notification.title ?? 'MathWarriors',
          body: notification.body ?? '',
          payload: message.data['type'],
        );

        if (message.data['type'] == 'score_beaten') {
          _scoreBeatenController.add({
            'beaten_by': message.data['beaten_by'] ?? '',
            'beaten_by_points': message.data['beaten_by_points'] ?? '0',
            'your_points': message.data['your_points'] ?? '0',
          });
        }
      }
    });
  }

  Future<void> sendTokenToBackend() async {
    if (_currentToken == null) return;
    await _sendTokenToBackend();
  }

  Future<void> _sendTokenToBackend() async {
    try {
      await _api.post('/api/user/update-fcm-token', data: {
        'fcm_token': _currentToken,
      });
      debugPrint('[FCM] Token terkirim ke backend');
    } catch (e) {
      debugPrint('[FCM] Gagal kirim token: $e');
    }
  }

  String? get currentToken => _currentToken;

  void dispose() {
    _scoreBeatenController.close();
    _instance = null;
  }
}
