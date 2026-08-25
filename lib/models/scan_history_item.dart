import 'package:flutter/material.dart';

enum RiskLevel { low, moderate, high }

class ScanHistoryItem {
  final String id;
  final String bodyArea;
  final DateTime scannedAt;
  final double confidence; // 0.0 - 1.0
  final RiskLevel risk;
  final IconData placeholderIcon;

  const ScanHistoryItem({
    required this.id,
    required this.bodyArea,
    required this.scannedAt,
    required this.confidence,
    required this.risk,
    this.placeholderIcon = Icons.image_outlined,
  });
}

