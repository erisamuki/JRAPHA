/// A single row from GET /api/pharmacy/queue.
class PharmacyQueueItem {
  final String id;
  final String visitId;
  final String drugName;
  final String? dosage;
  final String? duration;
  final int? quantity;
  final String status;
  final String fullName;
  final String patientNumber;
  final DateTime createdAt;

  PharmacyQueueItem({
    required this.id,
    required this.visitId,
    required this.drugName,
    this.dosage,
    this.duration,
    this.quantity,
    required this.status,
    required this.fullName,
    required this.patientNumber,
    required this.createdAt,
  });

  factory PharmacyQueueItem.fromJson(Map<String, dynamic> json) {
    return PharmacyQueueItem(
      id: json['id'] as String,
      visitId: json['visit_id'] as String,
      drugName: json['drug_name'] as String,
      dosage: json['dosage'] as String?,
      duration: json['duration'] as String?,
      quantity: json['quantity'] as int?,
      status: json['status'] as String,
      fullName: json['full_name'] as String,
      patientNumber: json['patient_number'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// A single row from GET /api/pharmacy/stock (and its alerts variant).
class StockItem {
  final String id;
  final String drugName;
  final String? batchNumber;
  final int quantity;
  final String? unit;
  final int reorderLevel;
  final DateTime? expiryDate;
  final double? unitPriceUgx;

  StockItem({
    required this.id,
    required this.drugName,
    this.batchNumber,
    required this.quantity,
    this.unit,
    required this.reorderLevel,
    this.expiryDate,
    this.unitPriceUgx,
  });

  bool get isLowStock => quantity <= reorderLevel;
  bool get isNearExpiry =>
      expiryDate != null && expiryDate!.difference(DateTime.now()).inDays <= 90;

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      id: json['id'] as String,
      drugName: json['drug_name'] as String,
      batchNumber: json['batch_number'] as String?,
      quantity: json['quantity'] as int,
      unit: json['unit'] as String?,
      reorderLevel: json['reorder_level'] as int,
      expiryDate: json['expiry_date'] != null ? DateTime.tryParse(json['expiry_date']) : null,
      unitPriceUgx: json['unit_price_ugx'] != null
          ? double.tryParse(json['unit_price_ugx'].toString())
          : null,
    );
  }
}
