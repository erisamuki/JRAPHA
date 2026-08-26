/// A full user record as returned by GET /api/admin/users - includes
/// every status (pending, approved, rejected, suspended), unlike
/// PendingUserModel which only covers pending accounts.
class AdminUserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final DateTime createdAt;
  final DateTime? approvedAt;

  AdminUserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    required this.createdAt,
    this.approvedAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
    );
  }
}

/// A single audit trail entry as returned by GET /api/admin/audit-log.
class AuditLogEntry {
  final String id;
  final String action;
  final String entityType;
  final String? actedBy;
  final DateTime createdAt;

  AuditLogEntry({
    required this.id,
    required this.action,
    required this.entityType,
    this.actedBy,
    required this.createdAt,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] as String,
      action: json['action'] as String,
      entityType: json['entity_type'] as String,
      actedBy: json['acted_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
