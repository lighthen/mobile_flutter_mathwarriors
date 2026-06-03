import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '871654390558-edil1ft3scok4u84ppspigcprce4l7ef.apps.googleusercontent.com',
  );

  Future<({User user, String token})> login(
      String username, String password) async {
    try {
      final response = await _api.post('/api/auth/login', data: {
        'username': username,
        'password': password,
      });

      final data = response.data;
      if (data['status'] == 200) {
        final user = User.fromJson(data['data']['user']);
        final token = data['data']['token'] as String;
        await _api.saveToken(token);
        return (user: user, token: token);
      }
      throw Exception(data['message'] ?? 'Login gagal');
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Koneksi ke server gagal';
      throw Exception(message);
    }
  }

  Future<({User user, String token})> register(
      String username, String password, String email) async {
    try {
      final response = await _api.post('/api/auth/register', data: {
        'username': username,
        'password': password,
        'email': email,
      });

      final data = response.data;
      if (data['status'] == 201) {
        final user = User.fromJson(data['data']['user']);
        final token = data['data']['token'] as String;
        await _api.saveToken(token);
        return (user: user, token: token);
      }
      throw Exception(data['message'] ?? 'Registrasi gagal');
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Koneksi ke server gagal';
      throw Exception(message);
    }
  }

  Future<({User user, String token})> googleLogin() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Login Google dibatalkan');
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception('Gagal mendapatkan ID token Google');
      }

      final response = await _api.post('/api/auth/google_login', data: {
        'id_token': googleAuth.idToken,
      });

      final data = response.data;
      if (data['status'] == 200 || data['status'] == 201) {
        final user = User.fromJson(data['data']['user']);
        final token = data['data']['token'] as String;
        await _api.saveToken(token);
        return (user: user, token: token);
      }
      throw Exception(data['message'] ?? 'Google login gagal');
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Koneksi ke server gagal';
      throw Exception(message);
    }
  }

  Future<String?> getToken() async => await _api.getToken();

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _api.clearToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await _api.getToken();
    return token != null;
  }
}
