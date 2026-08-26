import 'package:flutter/material.dart';
import '../models/pharmacy_models.dart';
import '../services/pharmacy_service.dart';
import '../../../core/services/api_client.dart';

class PharmacyProvider extends ChangeNotifier {
  final PharmacyService _service = PharmacyService();

  List<PharmacyQueueItem> _queue = [];
  bool _isLoadingQueue = false;

  List<StockItem> _stock = [];
  bool _isLoadingStock = false;

  bool _isSubmitting = false;
  String? _errorMessage;

  List<PharmacyQueueItem> get queue => _queue;
  bool get isLoadingQueue => _isLoadingQueue;
  List<StockItem> get stock => _stock;
  bool get isLoadingStock => _isLoadingStock;
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
      _errorMessage = 'Unable to load the pharmacy queue.';
    } finally {
      _isLoadingQueue = false;
      notifyListeners();
    }
  }

  Future<bool> dispense(String prescriptionId, {bool partial = false}) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _service.dispense(prescriptionId, partial ? 'partially_dispensed' : 'dispensed');
      await loadQueue();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to dispense.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> loadStock() async {
    _isLoadingStock = true;
    notifyListeners();
    try {
      _stock = await _service.getStock();
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Unable to load stock.';
    } finally {
      _isLoadingStock = false;
      notifyListeners();
    }
  }

  Future<bool> addStock({
    required String drugName,
    String? batchNumber,
    required int quantity,
    String? unit,
    int? reorderLevel,
    DateTime? expiryDate,
    double? unitPriceUgx,
  }) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _service.addStock(
        drugName: drugName,
        batchNumber: batchNumber,
        quantity: quantity,
        unit: unit,
        reorderLevel: reorderLevel,
        expiryDate: expiryDate,
        unitPriceUgx: unitPriceUgx,
      );
      await loadStock();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to add stock.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
