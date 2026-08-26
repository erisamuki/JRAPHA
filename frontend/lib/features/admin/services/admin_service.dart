import '../../../core/services/api_client.dart';
import '../models/pending_user_model.dart';
import '../models/dashboard_model.dart';
import '../models/admin_user_model.dart';

/// Handles the network calls for every admin-only endpoint: pending-user
/// approvals, the real-time dashboard aggregate, the full user list, and
/// the audit log.
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

  Future<AdminDashboardModel> getDashboard() async {
    final result = await _api.get('/admin/dashboard');
    return AdminDashboardModel.fromJson(result as Map<String, dynamic>);
  }

  Future<List<AdminUserModel>> getAllUsers() async {
    final result = await _api.get('/admin/users');
    final List usersJson = result['users'] as List;
    return usersJson.map((json) => AdminUserModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<AuditLogEntry>> getAuditLog() async {
    final result = await _api.get('/admin/audit-log');
    final List logJson = result['audit_log'] as List;
    return logJson.map((json) => AuditLogEntry.fromJson(json as Map<String, dynamic>)).toList();
  }
}
