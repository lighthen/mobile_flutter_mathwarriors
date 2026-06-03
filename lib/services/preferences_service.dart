import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _keySoundEnabled = 'sound_enabled';
  static const _keyVibrationEnabled = 'vibration_enabled';
  static const _keyTimerDuration = 'timer_duration';
  static const _keyHighScore = 'high_score';
  static const _keyNotificationsEnabled = 'notifications_enabled';

  static PreferencesService? _instance;
  static Future<PreferencesService> get instance async {
    if (_instance == null) {
      _instance = PreferencesService._();
      await _instance!._init();
    }
    return _instance!;
  }

  late SharedPreferences _prefs;

  PreferencesService._();

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get soundEnabled => _prefs.getBool(_keySoundEnabled) ?? true;
  set soundEnabled(bool value) => _prefs.setBool(_keySoundEnabled, value);

  bool get vibrationEnabled => _prefs.getBool(_keyVibrationEnabled) ?? true;
  set vibrationEnabled(bool value) => _prefs.setBool(_keyVibrationEnabled, value);

  bool get notificationsEnabled =>
      _prefs.getBool(_keyNotificationsEnabled) ?? true;
  set notificationsEnabled(bool value) =>
      _prefs.setBool(_keyNotificationsEnabled, value);

  int get timerDuration => _prefs.getInt(_keyTimerDuration) ?? 15;
  set timerDuration(int value) => _prefs.setInt(_keyTimerDuration, value);

  int get highScore => _prefs.getInt(_keyHighScore) ?? 0;
  set highScore(int value) => _prefs.setInt(_keyHighScore, value);

  Future<void> updateHighScore(int score) async {
    if (score > highScore) {
      highScore = score;
    }
  }
}
