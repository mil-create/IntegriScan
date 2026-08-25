import 'package:flutter/material.dart';

enum RiskLevel { low, moderate, high }

enum LogStatus { monitoring, resolved, escalated }

class ClinicalLogEntry {
  final String id;
  final String bodyArea;
  final String condition; // AI-suggested label, e.g. "Suspected Contact Dermatitis"
  final DateTime loggedAt;
  final double confidence; // 0.0 - 1.0
  final RiskLevel risk;
  final LogStatus status;
  final List<double> trend; // recent confidence readings for the sparkline
  final IconData icon;
  final List<String> recommendations;
  final String? imagePath; // Path to the captured image for this scan

  const ClinicalLogEntry({
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
