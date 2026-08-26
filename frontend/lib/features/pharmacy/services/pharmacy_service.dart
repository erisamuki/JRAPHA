import '../../../core/services/api_client.dart';
import '../models/pharmacy_models.dart';

class PharmacyService {
  final ApiClient _api = ApiClient();

  Future<List<PharmacyQueueItem>> getQueue() async {
    final result = await _api.get('/pharmacy/queue');
    final List queueJson = result['queue'] as List;
    return queueJson.map((j) => PharmacyQueueItem.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> dispense(String prescriptionId, String status) async {
    await _api.patch('/pharmacy/prescriptions/$prescriptionId/dispense', {'status': status});
  }

  Future<List<StockItem>> getStock() async {
    final result = await _api.get('/pharmacy/stock');
    final List stockJson = result['stock'] as List;
    return stockJson.map((j) => StockItem.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<StockItem> addStock({
    required String drugName,
    String? batchNumber,
    required int quantity,
    String? unit,
    int? reorderLevel,
    DateTime? expiryDate,
    double? unitPriceUgx,
  }) async {
    final result = await _api.post('/pharmacy/stock', {
      'drug_name': drugName,
      'batch_number': batchNumber,
      'quantity': quantity,
      'unit': unit,
      'reorder_level': reorderLevel,
      'expiry_date': expiryDate?.toIso8601String().split('T').first,
      'unit_price_ugx': unitPriceUgx,
    });
    return StockItem.fromJson(result['stock_item'] as Map<String, dynamic>);
  }
}
