/// Mirrors a row from the backend's `patients` table.
class PatientModel {
  final String id;
  final String patientNumber;
  final String fullName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? phone;
  final String? nin;
  final String? district;
  final String? nextOfKinName;
  final String? nextOfKinPhone;
  final DateTime createdAt;

  PatientModel({
    required this.id,
    required this.patientNumber,
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.phone,
    this.nin,
    this.district,
    this.nextOfKinName,
    this.nextOfKinPhone,
    required this.createdAt,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'] as String,
      patientNumber: json['patient_number'] as String,
      fullName: json['full_name'] as String,
      dateOfBirth: json['date_of_birth'] != null ? DateTime.tryParse(json['date_of_birth']) : null,
      gender: json['gender'] as String?,
      phone: json['phone'] as String?,
      nin: json['nin'] as String?,
      district: json['district'] as String?,
      nextOfKinName: json['next_of_kin_name'] as String?,
      nextOfKinPhone: json['next_of_kin_phone'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

const List<Map<String, String>> kGenderOptions = [
  {'value': 'male', 'label': 'Male'},
  {'value': 'female', 'label': 'Female'},
  {'value': 'other', 'label': 'Other'},
];
