import '../../../core/services/api_client.dart';
import '../models/nurse_queue_item.dart';
import '../models/vitals_model.dart';

class NurseService {
  final ApiClient _api = ApiClient();

  Future<List<NurseQueueItem>> getQueue() async {
    final result = await _api.get('/nurse/queue');
    final List queueJson = result['queue'] as List;
    return queueJson.map((j) => NurseQueueItem.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<VitalsModel> recordVitals({
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
    final result = await _api.post('/nurse/vitals', {
      'visit_id': visitId,
      'blood_pressure': bloodPressure,
      'temperature_c': temperatureC,
      'pulse_bpm': pulseBpm,
      'resp_rate': respRate,
      'spo2_percent': spo2Percent,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'notes': notes,
    });
    return VitalsModel.fromJson(result['vitals'] as Map<String, dynamic>);
  }
}
