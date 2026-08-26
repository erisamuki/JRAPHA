/// A single lab order, as returned within the visit detail response.
class LabOrderModel {
  final String id;
  final String testName;
  final String status;
  final String? result;
  final bool isCritical;
  final DateTime orderedAt;

  LabOrderModel({
    required this.id,
    required this.testName,
    required this.status,
    this.result,
    required this.isCritical,
    required this.orderedAt,
  });

  factory LabOrderModel.fromJson(Map<String, dynamic> json) {
    return LabOrderModel(
      id: json['id'] as String,
      testName: json['test_name'] as String,
      status: json['status'] as String,
      result: json['result'] as String?,
      isCritical: json['is_critical'] as bool? ?? false,
      orderedAt: DateTime.parse(json['ordered_at'] as String),
    );
  }
}

/// A single prescription, as returned within the visit detail response.
class PrescriptionModel {
  final String id;
  final String drugName;
  final String? dosage;
  final String? duration;
  final int? quantity;
  final String status;
  final DateTime createdAt;

  PrescriptionModel({
    required this.id,
    required this.drugName,
    this.dosage,
    this.duration,
    this.quantity,
    required this.status,
    required this.createdAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'] as String,
      drugName: json['drug_name'] as String,
      dosage: json['dosage'] as String?,
      duration: json['duration'] as String?,
      quantity: json['quantity'] as int?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// A single vitals reading, as returned within the visit detail response.
class VisitVitals {
  final String? bloodPressure;
  final double? temperatureC;
  final int? pulseBpm;
  final int? spo2Percent;
  final double? weightKg;
  final double? heightCm;
  final DateTime recordedAt;

  VisitVitals({
    this.bloodPressure,
    this.temperatureC,
    this.pulseBpm,
    this.spo2Percent,
    this.weightKg,
    this.heightCm,
    required this.recordedAt,
  });

  factory VisitVitals.fromJson(Map<String, dynamic> json) {
    return VisitVitals(
      bloodPressure: json['blood_pressure'] as String?,
      temperatureC: json['temperature_c'] != null
          ? double.tryParse(json['temperature_c'].toString())
          : null,
      pulseBpm: json['pulse_bpm'] as int?,
      spo2Percent: json['spo2_percent'] as int?,
      weightKg: json['weight_kg'] != null ? double.tryParse(json['weight_kg'].toString()) : null,
      heightCm: json['height_cm'] != null ? double.tryParse(json['height_cm'].toString()) : null,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }
}

/// Full response from GET /api/doctor/visits/:visit_id.
class VisitDetailModel {
  final String visitId;
  final String fullName;
  final String patientNumber;
  final String status;
  final List<VisitVitals> vitals;
  final List<LabOrderModel> labOrders;
  final List<PrescriptionModel> prescriptions;

  VisitDetailModel({
    required this.visitId,
    required this.fullName,
    required this.patientNumber,
    required this.status,
    required this.vitals,
    required this.labOrders,
    required this.prescriptions,
  });

  factory VisitDetailModel.fromJson(Map<String, dynamic> json) {
    final visit = json['visit'] as Map<String, dynamic>;
    return VisitDetailModel(
      visitId: visit['id'] as String,
      fullName: visit['full_name'] as String,
      patientNumber: visit['patient_number'] as String,
      status: visit['status'] as String,
      vitals: (json['vitals'] as List)
          .map((v) => VisitVitals.fromJson(v as Map<String, dynamic>))
          .toList(),
      labOrders: (json['lab_orders'] as List)
          .map((l) => LabOrderModel.fromJson(l as Map<String, dynamic>))
          .toList(),
      prescriptions: (json['prescriptions'] as List)
          .map((p) => PrescriptionModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}
