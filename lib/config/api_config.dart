import 'app_config.dart';

class ApiConfig {
  static String get baseUrl => AppConfig().baseUrl;
  static String get uploadsUrl => AppConfig().uploadsUrl;
  static String get wsUrl => AppConfig().wsUrl;
  static String avatarUrl(String? avatar) => AppConfig().avatarUrl(avatar);
}