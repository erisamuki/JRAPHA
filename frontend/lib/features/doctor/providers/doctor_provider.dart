import 'package:flutter/material.dart';
import '../models/doctor_queue_item.dart';
import '../models/visit_detail_model.dart';
import '../services/doctor_service.dart';
import '../../../core/services/api_client.dart';

class DoctorProvider extends ChangeNotifier {
  final DoctorService _service = DoctorService();

  List<DoctorQueueItem> _queue = [];
  bool _isLoadingQueue = false;

  VisitDetailModel? _visitDetail;
  bool _isLoadingDetail = false;

  bool _isSubmitting = false;
  String? _errorMessage;

  List<DoctorQueueItem> get queue => _queue;
  bool get isLoadingQueue => _isLoadingQueue;
  VisitDetailModel? get visitDetail => _visitDetail;
  bool get isLoadingDetail => _isLoadingDetail;
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
      _errorMessage = 'Unable to load the doctor queue.';
    } finally {
      _isLoadingQueue = false;
      notifyListeners();
    }
  }

  Future<void> loadVisitDetail(String visitId) async {
    _isLoadingDetail = true;
    _visitDetail = null;
    notifyListeners();
    try {
      _visitDetail = await _service.getVisitDetail(visitId);
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Unable to load visit details.';
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  Future<bool> createLabOrder({required String visitId, required String testName}) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _service.createLabOrder(visitId: visitId, testName: testName);
      await loadVisitDetail(visitId);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create lab order.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> createPrescription({
    required String visitId,
    required String drugName,
    String? dosage,
    String? duration,
    int? quantity,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _service.createPrescription(
        visitId: visitId,
        drugName: drugName,
        dosage: dosage,
        duration: duration,
        quantity: quantity,
      );
      await loadVisitDetail(visitId);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create prescription.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
