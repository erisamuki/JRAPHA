import '../../../core/services/api_client.dart';
import '../models/lab_queue_item.dart';

class LabService {
  final ApiClient _api = ApiClient();

  Future<List<LabQueueItem>> getQueue() async {
    final result = await _api.get('/laboratory/queue');
    final List queueJson = result['queue'] as List;
    return queueJson.map((j) => LabQueueItem.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> updateStatus(String labOrderId, String status) async {
    await _api.patch('/laboratory/lab-orders/$labOrderId/status', {'status': status});
  }

  Future<void> submitResult({
    required String labOrderId,
    required String result,
    required bool isCritical,
  }) async {
    await _api.patch('/laboratory/lab-orders/$labOrderId/result', {
      'result': result,
      'is_critical': isCritical,
    });
  }
}
