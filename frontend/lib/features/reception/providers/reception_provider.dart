import 'package:flutter/material.dart';
import '../models/patient_model.dart';
import '../models/visit_model.dart';
import '../services/reception_service.dart';
import '../../../core/services/api_client.dart';

class ReceptionProvider extends ChangeNotifier {
  final ReceptionService _service = ReceptionService();

  List<PatientModel> _searchResults = [];
  bool _isSearching = false;

  List<VisitModel> _opdQueue = [];
  List<VisitModel> _inpatients = [];
  bool _isLoadingQueues = false;

  bool _isSubmitting = false;
  String? _errorMessage;

  List<PatientModel> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  List<VisitModel> get opdQueue => _opdQueue;
  List<VisitModel> get inpatients => _inpatients;
  bool get isLoadingQueues => _isLoadingQueues;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> searchPatients(String query) async {
    _isSearching = true;
    notifyListeners();
    try {
      _searchResults = await _service.searchPatients(search: query);
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Unable to search patients.';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<PatientModel?> registerPatient({
    required String fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? phone,
    String? nin,
    String? district,
    String? nextOfKinName,
    String? nextOfKinPhone,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final patient = await _service.registerPatient(
        fullName: fullName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        phone: phone,
        nin: nin,
        district: district,
        nextOfKinName: nextOfKinName,
        nextOfKinPhone: nextOfKinPhone,
      );
      return patient;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      _errorMessage = 'Failed to register patient.';
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> createVisit({
    required String patientId,
    required String visitType,
    String? ward,
    String? bedNumber,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.createVisit(
        patientId: patientId,
        visitType: visitType,
        ward: ward,
        bedNumber: bedNumber,
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create visit.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> loadQueues() async {
    _isLoadingQueues = true;
    notifyListeners();
    try {
      final results = await Future.wait([_service.getOpdQueue(), _service.getInpatients()]);
      _opdQueue = results[0];
      _inpatients = results[1];
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Unable to load visit queues.';
    } finally {
      _isLoadingQueues = false;
      notifyListeners();
    }
  }

  Future<bool> updateVisitStatus(String visitId, String status) async {
    try {
      await _service.updateVisitStatus(visitId, status);
      await loadQueues();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update visit status.';
      return false;
    }
  }
}
