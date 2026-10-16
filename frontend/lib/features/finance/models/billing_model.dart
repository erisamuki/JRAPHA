class BillingModel {
  final String id;
  final String fullName;
  final String patientNumber;
  final String visitType;
  final double totalAmount;
  final double amountPaid;
  final double balanceDue;
  final String paymentStatus;
  final DateTime? createdAt;

  const BillingModel({
    required this.id,
    required this.fullName,
    required this.patientNumber,
    required this.visitType,
    required this.totalAmount,
    required this.amountPaid,
    required this.balanceDue,
    required this.paymentStatus,
    required this.createdAt,
  });

  factory BillingModel.fromJson(Map<String, dynamic> json) {
    final total = _asDouble(json['total_amount_ugx']);
    final paid = _asDouble(json['amount_paid_ugx']);
    return BillingModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Unknown patient',
      patientNumber: json['patient_number'] as String? ?? '',
      visitType: json['visit_type'] as String? ?? '',
      totalAmount: total,
      amountPaid: paid,
      balanceDue: json['balance_due_ugx'] == null
          ? (total - paid)
          : _asDouble(json['balance_due_ugx']),
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class BillingItemModel {
  final String description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const BillingItemModel({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory BillingItemModel.fromJson(Map<String, dynamic> json) =>
      BillingItemModel(
        description: json['description'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: _asDouble(json['unit_price_ugx']),
        totalPrice: _asDouble(json['total_price_ugx']),
      );
}

class BillingPaymentModel {
  final double amount;
  final String paymentMethod;
  final String? reference;
  final DateTime? createdAt;

  const BillingPaymentModel({
    required this.amount,
    required this.paymentMethod,
    required this.reference,
    required this.createdAt,
  });

  factory BillingPaymentModel.fromJson(Map<String, dynamic> json) =>
      BillingPaymentModel(
        amount: _asDouble(json['amount_ugx']),
        paymentMethod: json['payment_method'] as String? ?? '',
        reference: json['reference'] as String?,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      );
}

class BillingDetailsModel {
  final List<BillingItemModel> items;
  final List<BillingPaymentModel> payments;

  const BillingDetailsModel({required this.items, required this.payments});

  factory BillingDetailsModel.fromJson(Map<String, dynamic> json) =>
      BillingDetailsModel(
        items: (json['items'] as List? ?? [])
            .map(
              (item) => BillingItemModel.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
        payments: (json['payments'] as List? ?? [])
            .map(
              (payment) =>
                  BillingPaymentModel.fromJson(payment as Map<String, dynamic>),
            )
            .toList(),
      );
}

double _asDouble(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
