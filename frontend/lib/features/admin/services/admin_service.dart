import '../../../core/services/api_client.dart';
import '../models/pending_user_model.dart';

/// Handles the network calls for admin user-approval actions, matching
/// the backend's GET/PATCH /api/auth/... admin-only endpoints.
class AdminService {
  final ApiClient _api = ApiClient();

  Future<List<PendingUserModel>> getPendingUsers() async {
    final result = await _api.get('/auth/pending-users');
    final List usersJson = result['users'] as List;
    return usersJson
        .map((json) => PendingUserModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveUser(String userId) async {
    await _api.patch('/auth/users/$userId/approve', {});
  }

  Future<void> rejectUser(String userId) async {
    await _api.patch('/auth/users/$userId/reject', {});
  }
}
