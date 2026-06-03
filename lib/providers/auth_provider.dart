import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _initialized = false;

  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null && _token != null;

  AuthProvider() {
    _setupApiCallbacks();
  }

  void _setupApiCallbacks() {
    final api = ApiService();

    api.setOnUnauthorized(() {
      logout();
    });

    api.setOnTokenRefreshed((userData) async {
      _token = await _authService.getToken();
      _user = User(
        id: userData['id'] as int,
        username: userData['username'] as String,
        tier: userData['tier'] as String,
        points: userData['points'] as int,
      );
      notifyListeners();
    });
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.login(username, password);
      _user = result.user;
      _token = result.token;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(
      String username, String password, String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result =
          await _authService.register(username, password, email);
      _user = result.user;
      _token = result.token;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> googleLogin() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.googleLogin();
      _user = result.user;
      _token = result.token;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _token = null;
    notifyListeners();
  }

  void updateUser(User updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    if (_initialized) return;
    _initialized = true;

    final token = await _authService.getToken();
    if (token != null) {
      final userFromToken = _decodeJwtUser(token);
      if (userFromToken != null) {
        _token = token;
        _user = userFromToken;
        notifyListeners();
        return;
      }
      await _authService.logout();
    }
    _user = null;
    _token = null;
    notifyListeners();
  }

  User? _decodeJwtUser(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      String payload = parts[1];
      switch (payload.length % 4) {
        case 2: payload += '=='; break;
        case 3: payload += '='; break;
      }
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');

      final decoded = utf8.decode(base64.decode(payload));
      final data = json.decode(decoded) as Map<String, dynamic>;

      final exp = data['exp'] as int? ?? 0;
      if (exp < DateTime.now().millisecondsSinceEpoch ~/ 1000) {
        return null;
      }

      return User(
        id: data['user_id'] as int,
        username: data['username'] as String,
        tier: data['tier'] as String,
        points: 0,
      );
    } catch (_) {
      return null;
    }
  }
}
