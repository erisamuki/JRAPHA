import '../../../core/services/api_client.dart';
import '../models/billing_model.dart';

class CashierService {
  final ApiClient _api = ApiClient();

  Future<List<BillingModel>> getOutstandingBalances() async {
    final result = await _api.get('/finance/outstanding');
    return (result['outstanding'] as List)
        .map((item) => BillingModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<BillingDetailsModel> getBillingDetails(String billingId) async {
    final result = await _api.get('/finance/billing/$billingId');
    return BillingDetailsModel.fromJson(result as Map<String, dynamic>);
  }

  Future<void> recordPayment({
    required String billingId,
    required double amount,
    required String paymentMethod,
    String? reference,
  }) async {
    await _api.patch('/finance/billing/$billingId/payment', {
      'amount_ugx': amount,
      'payment_method': paymentMethod,
      if (reference != null && reference.trim().isNotEmpty)
        'reference': reference.trim(),
    });
  }
}
