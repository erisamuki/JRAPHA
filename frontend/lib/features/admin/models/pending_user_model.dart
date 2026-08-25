/// Represents a user account awaiting admin approval, as returned by
/// GET /api/auth/pending-users.
class PendingUserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final DateTime createdAt;

  PendingUserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    required this.createdAt,
  });

  factory PendingUserModel.fromJson(Map<String, dynamic> json) {
    return PendingUserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
