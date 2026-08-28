import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'clinical_log.g.dart';

@HiveType(typeId: 0)
enum RiskLevel {
  @HiveField(0)
  low,
  @HiveField(1)
  moderate,
  @HiveField(2)
  high
}

@HiveType(typeId: 1)
enum LogStatus {
  @HiveField(0)
  monitoring,
  @HiveField(1)
  resolved,
  @HiveField(2)
  escalated
}

@HiveType(typeId: 2)
class ClinicalLogEntry {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String bodyArea;
  @HiveField(2)
  final String condition; // AI-suggested label, e.g. "Suspected Contact Dermatitis"
  @HiveField(3)
  final DateTime loggedAt;
  @HiveField(4)
  final double confidence; // 0.0 - 1.0
  @HiveField(5)
  final RiskLevel risk;
  @HiveField(6)
  final LogStatus status;
  @HiveField(7)
  final List<double> trend; // recent confidence readings for the sparkline
  @HiveField(8)
  final IconData icon;
  @HiveField(9)
  final List<String> recommendations;
  @HiveField(10)
  final String? imagePath; // Path to the captured image for this scan

  ClinicalLogEntry({
    required this.id,
    required this.bodyArea,
    required this.condition,
    required this.loggedAt,
    required this.confidence,
    required this.risk,
    required this.status,
    required this.trend,
    required this.recommendations,
    this.icon = Icons.image_outlined,
    this.imagePath,
  });
}
