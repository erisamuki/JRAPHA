import 'package:flutter/material.dart';
import '../models/lab_queue_item.dart';
import '../services/lab_service.dart';
import '../../../core/services/api_client.dart';

class LabProvider extends ChangeNotifier {
  final LabService _service = LabService();

  List<LabQueueItem> _queue = [];
  bool _isLoadingQueue = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<LabQueueItem> get queue => _queue;
  bool get isLoadingQueue => _isLoadingQueue;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> loadQueue() async {
    _isLoadingQueue = true;
    notifyListeners();
    try {
      _queue = await _service.getQueue();
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Unable to load the lab queue.';
    } finally {
      _isLoadingQueue = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(String labOrderId, String status) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _service.updateStatus(labOrderId, status);
      await loadQueue();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update status.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> submitResult({
    required String labOrderId,
    required String result,
    required bool isCritical,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _service.submitResult(labOrderId: labOrderId, result: result, isCritical: isCritical);
      await loadQueue();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to submit result.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
