import 'package:flutter/material.dart';

class DisplayItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;

  const DisplayItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
  });
}