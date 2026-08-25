import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgIcon extends StatelessWidget {
  final String assetName;
  final double size;
  final Color color;
  final IconData? fallbackIcon; // For backward compatibility

  const SvgIcon({
    super.key,
    required this.assetName,
    this.size = 24.0,
    this.color = Colors.black,
    this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    return assetName.isNotEmpty
        ? SvgPicture.asset(
            'assets/icons/$assetName.svg',
            width: size,
            height: size,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          )
        : fallbackIcon != null
            ? Icon(fallbackIcon, size: size, color: color)
            : Icon(Icons.image, size: size, color: Colors.grey); // Ultimate fallback
  }
}