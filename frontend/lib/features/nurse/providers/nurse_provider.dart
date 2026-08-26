import 'package:flutter/material.dart';
import '../models/nurse_queue_item.dart';
import '../services/nurse_service.dart';
import '../../../core/services/api_client.dart';

class NurseProvider extends ChangeNotifier {
  final NurseService _service = NurseService();

  List<NurseQueueItem> _queue = [];
  bool _isLoadingQueue = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<NurseQueueItem> get queue => _queue;
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
      _errorMessage = 'Unable to load the nurse queue.';
    } finally {
      _isLoadingQueue = false;
      notifyListeners();
    }
  }

  Future<bool> recordVitals({
    required String visitId,
    String? bloodPressure,
    double? temperatureC,
    int? pulseBpm,
    int? respRate,
    int? spo2Percent,
    double? weightKg,
    double? heightCm,
    String? notes,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.recordVitals(
        visitId: visitId,
        bloodPressure: bloodPressure,
        temperatureC: temperatureC,
        pulseBpm: pulseBpm,
        respRate: respRate,
        spo2Percent: spo2Percent,
        weightKg: weightKg,
        heightCm: heightCm,
        notes: notes,
      );
      // Vitals recorded moves the visit out of the nurse queue (backend
      // sets it to 'triaged'), so refresh the list.
      await loadQueue();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to record vitals.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
