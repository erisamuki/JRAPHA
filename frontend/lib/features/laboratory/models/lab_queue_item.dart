/// A single row from GET /api/laboratory/queue.
class LabQueueItem {
  final String id;
  final String visitId;
  final String testName;
  final String status;
  final String? result;
  final bool isCritical;
  final String fullName;
  final String patientNumber;
  final String visitType;
  final DateTime orderedAt;

  LabQueueItem({
    required this.id,
    required this.visitId,
    required this.testName,
    required this.status,
    this.result,
    required this.isCritical,
    required this.fullName,
    required this.patientNumber,
    required this.visitType,
    required this.orderedAt,
  });

  factory LabQueueItem.fromJson(Map<String, dynamic> json) {
    return LabQueueItem(
      id: json['id'] as String,
      visitId: json['visit_id'] as String,
      testName: json['test_name'] as String,
      status: json['status'] as String,
      result: json['result'] as String?,
      isCritical: json['is_critical'] as bool? ?? false,
      fullName: json['full_name'] as String,
      patientNumber: json['patient_number'] as String,
      visitType: json['visit_type'] as String,
      orderedAt: DateTime.parse(json['ordered_at'] as String),
    );
  }
}

const List<String> kLabOrderStatuses = [
  'ordered',
  'sample_collected',
  'in_progress',
  'completed',
  'cancelled',
];
