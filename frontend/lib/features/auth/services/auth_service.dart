import '../../../core/services/api_client.dart';
import '../../../core/services/token_storage.dart';
import '../models/user_model.dart';

/// Handles the actual network calls to the backend's /api/auth endpoints.
/// Kept separate from AuthProvider so the API logic and the app-state
/// logic (loading flags, notifyListeners, etc.) don't get tangled.
class AuthService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    final result = await _api.post('/auth/register', {
      'full_name': fullName,
      'email': email,
      'password': password,
      'role': role,
      'phone': ?phone,
    }, auth: false);

    return result;
  }

  Future<UserModel> login({required String email, required String password}) async {
    final result = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    }, auth: false);

    final token = result['token'] as String;
    await TokenStorage.saveToken(token);

    return UserModel.fromJson(result['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await TokenStorage.clearToken();
  }
}
