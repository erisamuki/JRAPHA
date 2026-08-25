import 'package:flutter/material.dart';
import '../models/pending_user_model.dart';
import '../services/admin_service.dart';
import '../../../core/services/api_client.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  List<PendingUserModel> _pendingUsers = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Tracks which specific user row is mid-action, so only that row
  // shows a spinner instead of blocking the whole list.
  String? _processingUserId;

  List<PendingUserModel> get pendingUsers => _pendingUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get processingUserId => _processingUserId;

  Future<void> loadPendingUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _pendingUsers = await _adminService.getPendingUsers();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Unable to load pending users.';
    } finally {
      _isLoading = false;
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
}
