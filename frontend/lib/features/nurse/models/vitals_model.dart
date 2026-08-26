/// Mirrors a row from the backend's `vitals` table.
class VitalsModel {
  final String id;
  final String visitId;
  final String? bloodPressure;
  final double? temperatureC;
  final int? pulseBpm;
  final int? respRate;
  final int? spo2Percent;
  final double? weightKg;
  final double? heightCm;
  final String? notes;
  final DateTime recordedAt;

  VitalsModel({
    required this.id,
    required this.visitId,
    this.bloodPressure,
    this.temperatureC,
    this.pulseBpm,
    this.respRate,
    this.spo2Percent,
    this.weightKg,
    this.heightCm,
    this.notes,
    required this.recordedAt,
  });

  factory VitalsModel.fromJson(Map<String, dynamic> json) {
    return VitalsModel(
      id: json['id'] as String,
      visitId: json['visit_id'] as String,
      bloodPressure: json['blood_pressure'] as String?,
      temperatureC: json['temperature_c'] != null
          ? double.tryParse(json['temperature_c'].toString())
          : null,
      pulseBpm: json['pulse_bpm'] as int?,
      respRate: json['resp_rate'] as int?,
      spo2Percent: json['spo2_percent'] as int?,
      weightKg: json['weight_kg'] != null ? double.tryParse(json['weight_kg'].toString()) : null,
      heightCm: json['height_cm'] != null ? double.tryParse(json['height_cm'].toString()) : null,
      notes: json['notes'] as String?,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }
}
