/// A single OPD or in-patient row shown on the admin dashboard.
class DashboardVisit {
  final String id;
  final String status;
  final String fullName;
  final String patientNumber;
  final String? ward;
  final String? bedNumber;

  DashboardVisit({
    required this.id,
    required this.status,
    required this.fullName,
    required this.patientNumber,
    this.ward,
    this.bedNumber,
  });

  factory DashboardVisit.fromJson(Map<String, dynamic> json) {
    return DashboardVisit(
      id: json['id'] as String,
      status: json['status'] as String,
      fullName: json['full_name'] as String,
      patientNumber: json['patient_number'] as String,
      ward: json['ward'] as String?,
      bedNumber: json['bed_number'] as String?,
    );
  }
}

/// A pending-user summary row (lighter than the full PendingUserModel,
/// used just for the dashboard count/list).
class DashboardPendingUser {
  final String id;
  final String fullName;
  final String role;

  DashboardPendingUser({required this.id, required this.fullName, required this.role});

  factory DashboardPendingUser.fromJson(Map<String, dynamic> json) {
    return DashboardPendingUser(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
    );
  }
}

/// Mirrors the full GET /api/admin/dashboard aggregate response.
class AdminDashboardModel {
  final List<DashboardVisit> opdQueue;
  final List<DashboardVisit> inpatients;
  final List<DashboardPendingUser> pendingUsers;
  final num todayRevenueUgx;
  final int outstandingBillsCount;
  final int lowStockCount;

  AdminDashboardModel({
    required this.opdQueue,
    required this.inpatients,
    required this.pendingUsers,
    required this.todayRevenueUgx,
    required this.outstandingBillsCount,
    required this.lowStockCount,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      opdQueue: (json['opd_queue'] as List)
          .map((e) => DashboardVisit.fromJson(e as Map<String, dynamic>))
          .toList(),
      inpatients: (json['inpatients'] as List)
          .map((e) => DashboardVisit.fromJson(e as Map<String, dynamic>))
          .toList(),
      pendingUsers: (json['pending_users'] as List)
          .map((e) => DashboardPendingUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      todayRevenueUgx: json['today_revenue_ugx'] as num,
      outstandingBillsCount: json['outstanding_bills_count'] as int,
      lowStockCount: json['low_stock_count'] as int,
    );
  }

  factory AdminDashboardModel.empty() => AdminDashboardModel(
        opdQueue: [],
        inpatients: [],
        pendingUsers: [],
        todayRevenueUgx: 0,
        outstandingBillsCount: 0,
        lowStockCount: 0,
      );
}