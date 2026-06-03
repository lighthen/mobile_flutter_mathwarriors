import 'package:flutter/foundation.dart';
import '../services/preferences_service.dart';

class SettingsProvider extends ChangeNotifier {
  PreferencesService? _prefs;

  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _notificationsEnabled = true;
  int _timerDuration = 15;

  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  int get timerDuration => _timerDuration;

  Future<void> init(PreferencesService prefs) async {
    _prefs = prefs;
    _soundEnabled = prefs.soundEnabled;
    _vibrationEnabled = prefs.vibrationEnabled;
    _notificationsEnabled = prefs.notificationsEnabled;
    _timerDuration = prefs.timerDuration;
    notifyListeners();
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    _prefs?.soundEnabled = _soundEnabled;
    notifyListeners();
  }

  Future<void> toggleVibration() async {
    _vibrationEnabled = !_vibrationEnabled;
    _prefs?.vibrationEnabled = _vibrationEnabled;
    notifyListeners();
  }

  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    _prefs?.notificationsEnabled = _notificationsEnabled;
    notifyListeners();
  }

  Future<void> setTimerDuration(int seconds) async {
    _timerDuration = seconds;
    _prefs?.timerDuration = seconds;
    notifyListeners();
  }
}
