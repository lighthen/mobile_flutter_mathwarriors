class AppConfig {
  static final AppConfig _instance = AppConfig._();
  factory AppConfig() => _instance;
  AppConfig._();

  String _ipAddress = '192.168.0.7';

  String get ipAddress => _ipAddress;
  set ipAddress(String ip) => _ipAddress = ip;

  String get baseUrl => 'http://$_ipAddress/math-warriors/backend';
  String get wsUrl => 'ws://$_ipAddress:8080';
  String get uploadsUrl => '$baseUrl/uploads';

  String avatarUrl(String? avatar) {
    if (avatar == null || avatar.isEmpty || avatar == 'default.png') return '';
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) return avatar;
    return '$uploadsUrl/avatars/$avatar';
  }
}
