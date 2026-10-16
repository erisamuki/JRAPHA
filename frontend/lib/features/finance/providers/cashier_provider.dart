import 'package:flutter/material.dart';

import '../../../core/services/api_client.dart';
import '../models/billing_model.dart';
import '../services/cashier_service.dart';

class CashierProvider extends ChangeNotifier {
  final CashierService _service = CashierService();

  List<BillingModel> _outstanding = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<BillingModel> get outstanding => _outstanding;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  double get totalOutstanding =>
      _outstanding.fold(0, (total, bill) => total + bill.balanceDue);

  Future<void> loadOutstanding() async {
    _isLoading = true;
    notifyListeners();
    try {
      _outstanding = await _service.getOutstandingBalances();
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Unable to load outstanding bills.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<BillingDetailsModel?> getBillingDetails(String billingId) async {
    try {
      _errorMessage = null;
      return await _service.getBillingDetails(billingId);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Unable to load billing details.';
    }
    notifyListeners();
    return null;
  }

  Future<bool> recordPayment({
    required String billingId,
    required double amount,
    required String paymentMethod,
    String? reference,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.recordPayment(
        billingId: billingId,
        amount: amount,
        paymentMethod: paymentMethod,
        reference: reference,
      );
      await loadOutstanding();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to record payment.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
