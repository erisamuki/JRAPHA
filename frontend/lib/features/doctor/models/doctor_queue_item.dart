/// A single row from GET /api/doctor/queue - a visit that's been triaged
/// (vitals recorded) and is waiting for a doctor.
class DoctorQueueItem {
  final String visitId;
  final String visitType;
  final String status;
  final String patientId;
  final String fullName;
  final String patientNumber;
  final DateTime? dateOfBirth;
  final String? gender;
  final DateTime createdAt;

  DoctorQueueItem({
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

  factory DoctorQueueItem.fromJson(Map<String, dynamic> json) {
    return DoctorQueueItem(
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
