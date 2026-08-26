/// Covers both shapes the backend returns: a plain visit record, and the
/// flattened OPD/in-patient dashboard rows (which join in patient info).
class VisitModel {
  final String id;
  final String? patientId;
  final String visitType; // 'opd' or 'inpatient'
  final String status;
  final String? ward;
  final String? bedNumber;
  final String? assignedDoctor;
  final String? fullName;
  final String? patientNumber;
  final String? phone;
  final DateTime createdAt;

  VisitModel({
    required this.id,
    this.patientId,
    required this.visitType,
    required this.status,
    this.ward,
    this.bedNumber,
    this.assignedDoctor,
    this.fullName,
    this.patientNumber,
    this.phone,
    required this.createdAt,
  });

  factory VisitModel.fromJson(Map<String, dynamic> json, {String visitType = ''}) {
    return VisitModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String?,
      visitType: visitType.isNotEmpty ? visitType : (json['visit_type'] as String? ?? ''),
      status: json['status'] as String,
      ward: json['ward'] as String?,
      bedNumber: json['bed_number'] as String?,
      assignedDoctor: json['assigned_doctor'] as String?,
      fullName: json['full_name'] as String?,
      patientNumber: json['patient_number'] as String?,
      phone: json['phone'] as String?,
      createdAt: DateTime.parse(
        (json['created_at'] ?? json['admitted_at'] ?? DateTime.now().toIso8601String()) as String,
      ),
    );
  }
}

const List<String> kVisitStatuses = [
  'registered',
  'triaged',
  'with_doctor',
  'lab_pending',
  'pharmacy_pending',
  'admitted',
  'discharged',
  'closed',
];
