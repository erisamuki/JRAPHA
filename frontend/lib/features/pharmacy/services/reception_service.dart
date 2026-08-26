/// Mirrors a row returned by createVisit / getOpdDashboard /
/// getInpatientDashboard / updateVisitStatus in visits.controller.js.
/// Note: the OPD/in-patient list endpoints join in patient fields
/// (full_name, patient_number, phone) directly, so this model covers both
/// the plain `visit` object and the joined dashboard row shapes.
class VisitModel {
  final String id;
  final String status;
  final String visitType; // 'opd' | 'inpatient' — only present on createVisit's response
  final String? ward;
  final String? bedNumber;
  final String? assignedDoctor;
  final String? createdAt;
  final String? admittedAt;
  final String? patientId;
  final String? fullName;
  final String? patientNumber;
  final String? phone;

  VisitModel({
    required this.id,
    required this.status,
    this.visitType = '',
    this.ward,
    this.bedNumber,
    this.assignedDoctor,
    this.createdAt,
    this.admittedAt,
    this.patientId,
    this.fullName,
    this.patientNumber,
    this.phone,
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      id: json['id'].toString(),
      status: json['status'] as String,
      visitType: json['visit_type'] as String? ?? '',
      ward: json['ward'] as String?,
      bedNumber: json['bed_number']?.toString(),
      assignedDoctor: json['assigned_doctor'] as String?,
      createdAt: json['created_at'] as String?,
      admittedAt: json['admitted_at'] as String?,
      patientId: json['patient_id']?.toString(),
      fullName: json['full_name'] as String?,
      patientNumber: json['patient_number'] as String?,
      phone: json['phone'] as String?,
    );
  }
}

/// Matches the visit_type check in createVisit.
const List<String> kVisitTypes = ['opd', 'inpatient'];

/// Matches validStatuses in updateVisitStatus exactly.
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
