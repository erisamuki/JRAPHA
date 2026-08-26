import '../../../core/services/api_client.dart';
import '../models/patient_model.dart';
import '../models/visit_model.dart';

/// Handles the network calls for every /api/reception/... endpoint:
/// patients, visits (OPD/in-patient), and appointments.
class ReceptionService {
  final ApiClient _api = ApiClient();

  // ===== Patients =====

  Future<PatientModel> registerPatient({
    required String fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? phone,
    String? nin,
    String? district,
    String? nextOfKinName,
    String? nextOfKinPhone,
  }) async {
    final result = await _api.post('/reception/patients', {
      'full_name': fullName,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
      'gender': ?gender,
      'phone': ?phone,
      'nin': ?nin,
      'district': ?district,
      'next_of_kin_name': ?nextOfKinName,
      'next_of_kin_phone': ?nextOfKinPhone,
    });
    return PatientModel.fromJson(result['patient'] as Map<String, dynamic>);
  }

  Future<List<PatientModel>> searchPatients({String? search}) async {
    final query = search != null && search.isNotEmpty ? '?search=$search' : '';
    final result = await _api.get('/reception/patients$query');
    final List patientsJson = result['patients'] as List;
    return patientsJson.map((j) => PatientModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  // ===== Visits =====

  Future<VisitModel> createVisit({
    required String patientId,
    required String visitType,
    String? ward,
    String? bedNumber,
  }) async {
    final result = await _api.post('/reception/visits', {
      'patient_id': patientId,
      'visit_type': visitType,
      'ward': ?ward,
      'bed_number': ?bedNumber,
    });
    return VisitModel.fromJson(result['visit'] as Map<String, dynamic>, visitType: visitType);
  }

  Future<List<VisitModel>> getOpdQueue() async {
    final result = await _api.get('/reception/visits/opd');
    final List queueJson = result['opd_queue'] as List;
    return queueJson
        .map((j) => VisitModel.fromJson(j as Map<String, dynamic>, visitType: 'opd'))
        .toList();
  }

  Future<List<VisitModel>> getInpatients() async {
    final result = await _api.get('/reception/visits/inpatient');
    final List listJson = result['inpatients'] as List;
    return listJson
        .map((j) => VisitModel.fromJson(j as Map<String, dynamic>, visitType: 'inpatient'))
        .toList();
  }

  Future<void> updateVisitStatus(String visitId, String status) async {
    await _api.patch('/reception/visits/$visitId/status', {'status': status});
  }

  // ===== Appointments =====

  Future<Map<String, dynamic>> createAppointment({
    required String patientId,
    required DateTime scheduledAt,
    String? scheduledWith,
    String? notes,
  }) async {
    final result = await _api.post('/reception/appointments', {
      'patient_id': patientId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'scheduled_with': ?scheduledWith,
      'notes': ?notes,
    });
    return result['appointment'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getAppointments({String? date}) async {
    final query = date != null ? '?date=$date' : '';
    final result = await _api.get('/reception/appointments$query');
    return result['appointments'] as List;
  }
}
