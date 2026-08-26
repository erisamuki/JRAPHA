/// A single row from GET /api/nurse/queue - a visit waiting for vitals.
class NurseQueueItem {
  final String visitId;
  final String visitType;
  final String status;
  final String patientId;
  final String fullName;
  final String patientNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final DateTime createdAt;

  NurseQueueItem({
    required this.visitId,
    required this.visitType,
    required this.status,
    required this.patientId,
    required this.fullName,
    required this.patientNumber,
    this.dateOfBirth,
    this.gender,
    required this.createdAt,
  });

  factory NurseQueueItem.fromJson(Map<String, dynamic> json) {
    return NurseQueueItem(
      visitId: json['visit_id'] as String,
      visitType: json['visit_type'] as String,
      status: json['status'] as String,
      patientId: json['patient_id'] as String,
      fullName: json['full_name'] as String,
      patientNumber: json['patient_number'] as String,
      dateOfBirth: json['date_of_birth'] != null ? DateTime.tryParse(json['date_of_birth']) : null,
      gender: json['gender'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Simple age calculation for display, since the backend only sends DOB.
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int years = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      years--;
    }
    return years;
  }
}
