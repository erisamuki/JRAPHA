import '../../../core/services/api_client.dart';
import '../models/doctor_queue_item.dart';
import '../models/visit_detail_model.dart';

class DoctorService {
  final ApiClient _api = ApiClient();

  Future<List<DoctorQueueItem>> getQueue() async {
    final result = await _api.get('/doctor/queue');
    final List queueJson = result['queue'] as List;
    return queueJson.map((j) => DoctorQueueItem.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<VisitDetailModel> getVisitDetail(String visitId) async {
    final result = await _api.get('/doctor/visits/$visitId');
    return VisitDetailModel.fromJson(result as Map<String, dynamic>);
  }

  Future<void> createLabOrder({required String visitId, required String testName}) async {
    await _api.post('/doctor/lab-orders', {'visit_id': visitId, 'test_name': testName});
  }

  Future<void> createPrescription({
    required String visitId,
    required String drugName,
    String? dosage,
    String? duration,
    int? quantity,
  }) async {
    await _api.post('/doctor/prescriptions', {
      'visit_id': visitId,
      'drug_name': drugName,
      'dosage': dosage,
      'duration': duration,
      'quantity': quantity,
    });
  }
}
