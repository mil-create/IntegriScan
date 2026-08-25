import 'package:flutter/material.dart';
import '../widgets/svg_icon.dart';

class BodyArea {
  final String id;
  final String label;
  final String assetName;
  final IconData fallbackIcon;

  const BodyArea({
    required this.id,
    required this.label,
    required this.assetName,
    required this.fallbackIcon,
  });

  Widget buildIcon({double size = 24.0, Color color = Colors.black}) {
    return SvgIcon(
      assetName: assetName,
      size: size,
      color: color,
      fallbackIcon: fallbackIcon,
    );
  }

  static const all = [
    BodyArea(
      id: 'scalp',
      label: 'Scalp',
      assetName: 'scalp',
      fallbackIcon: Icons.face_6_rounded,
    ),
    BodyArea(
      id: 'face',
      label: 'Face',
      assetName: 'face',
      fallbackIcon: Icons.face_retouching_natural_rounded,
    ),
    BodyArea(
      id: 'neck',
      label: 'Neck',
      assetName: 'neck',
      fallbackIcon: Icons.accessibility_new_rounded,
    ),
    BodyArea(
      id: 'arms',
      label: 'Arms & Hands',
      assetName: 'arms',
      fallbackIcon: Icons.back_hand_rounded,
    ),
    BodyArea(
      id: 'torso',
      label: 'Torso / Back',
      assetName: 'torso',
      fallbackIcon: Icons.airline_seat_flat_rounded,
    ),
    BodyArea(
      id: 'legs',
      label: 'Legs & Feet',
      assetName: 'legs',
      fallbackIcon: Icons.directions_walk_rounded,
    ),
  ];
}