import 'package:flutter/material.dart';
import '../models/pending_user_model.dart';
import '../models/dashboard_model.dart';
import '../models/admin_user_model.dart';
import '../services/admin_service.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/socket_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();
  final SocketService _socketService = SocketService();

  // Pending approvals
  List<PendingUserModel> _pendingUsers = [];
  bool _isLoadingPending = false;
  String? _processingUserId;

  // Live dashboard
  AdminDashboardModel _dashboard = AdminDashboardModel.empty();
  bool _isLoadingDashboard = false;

  // All users
  List<AdminUserModel> _allUsers = [];
  bool _isLoadingUsers = false;

  // Audit log
  List<AuditLogEntry> _auditLog = [];
  bool _isLoadingAuditLog = false;

  String? _errorMessage;

  List<PendingUserModel> get pendingUsers => _pendingUsers;
  bool get isLoadingPending => _isLoadingPending;
  String? get processingUserId => _processingUserId;

  AdminDashboardModel get dashboard => _dashboard;
  bool get isLoadingDashboard => _isLoadingDashboard;

  List<AdminUserModel> get allUsers => _allUsers;
  bool get isLoadingUsers => _isLoadingUsers;

  List<AuditLogEntry> get auditLog => _auditLog;
  bool get isLoadingAuditLog => _isLoadingAuditLog;

  String? get errorMessage => _errorMessage;

  /// Call once when the admin dashboard mounts. Loads the initial
  /// snapshot and subscribes to live Socket.IO events so the dashboard
  /// silently refreshes whenever anything relevant changes elsewhere
  /// in the system (a new visit, a payment, low stock, etc.).
  void startRealtime() {
    loadDashboard();
    _socketService.connect(
      onRelevantEvent: () {
        loadDashboard();
      },
    );
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  Future<void> loadDashboard() async {
    _isLoadingDashboard = true;
    notifyListeners();
    try {
      _dashboard = await _adminService.getDashboard();
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Unable to load dashboard.';
    } finally {
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }

  Future<void> loadPendingUsers() async {
    _isLoadingPending = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _pendingUsers = await _adminService.getPendingUsers();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Unable to load pending users.';
    } finally {
      _isLoadingPending = false;
      notifyListeners();
    }
  }

  Future<bool> approveUser(String userId) async {
    _processingUserId = userId;
    notifyListeners();
    try {
      await _adminService.approveUser(userId);
      _pendingUsers.removeWhere((u) => u.id == userId);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to approve user.';
      return false;
    } finally {
      _processingUserId = null;
      notifyListeners();
    }
  }

  Future<bool> rejectUser(String userId) async {
    _processingUserId = userId;
    notifyListeners();
    try {
      await _adminService.rejectUser(userId);
      _pendingUsers.removeWhere((u) => u.id == userId);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to reject user.';
      return false;
    } finally {
      _processingUserId = null;
      notifyListeners();
    }
  }

  Future<void> loadAllUsers() async {
    _isLoadingUsers = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _allUsers = await _adminService.getAllUsers();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Unable to load users.';
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  Future<void> loadAuditLog() async {
    _isLoadingAuditLog = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _auditLog = await _adminService.getAuditLog();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Unable to load audit log.';
    } finally {
      _isLoadingAuditLog = false;
      notifyListeners();
    }
  }
}
