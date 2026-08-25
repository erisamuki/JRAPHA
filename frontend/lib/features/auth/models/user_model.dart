/// Mirrors the user object returned by the backend's /api/auth
/// endpoints. Keep field names in sync with the `users` table.
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role; // admin, reception, nurse, doctor, laboratory, pharmacy
  final String status; // pending, approved, rejected, suspended

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'email': email,
    'role': role,
    'status': status,
  };
}
