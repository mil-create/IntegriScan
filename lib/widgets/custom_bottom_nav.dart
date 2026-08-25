import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';

/// Sticky bottom navigation bar with 4 text-based destinations and a
/// central, oversized circular scan button that floats above the bar
/// and subtly scales down on press — modeled after GCash's home tab.
class CustomBottomNav extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onScanTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onScanTap,
  });

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  bool _pressed = false;

  static const _labels = ['Home', 'Triage', 'Logs', 'Account'];
  static const _icons = [
    Icons.home_rounded,
    Icons.health_and_safety_outlined,
    Icons.receipt_long_outlined,
    Icons.person_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return SizedBox(
      height: AppSpacing.xl * 4,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // The bar itself
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: AppSpacing.xl,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _navItem(0, colors),
                  _navItem(1, colors),
                  const SizedBox(width: 76), // reserved gap for the FAB
                  _navItem(2, colors),
                  _navItem(3, colors),
                ],
              ),
            ),
          ),
          // Floating central scan button
          Positioned(
            top: 0,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              onTap: widget.onScanTap,
              child: AnimatedScale(
                scale: _pressed ? 0.92 : 1.0,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: Container(
                  width: AppSpacing.xl * 3,
                  height: AppSpacing.xl * 3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [colors.accent, colors.accent.withValues(alpha: 0.75)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.accent.withValues(alpha: 0.45),
                        blurRadius: AppSpacing.lg,
                        offset: const Offset(0, AppSpacing.xs),
                      ),
                    ],
                    border: Border.all(color: colors.background, width: AppSpacing.xs / 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, AppColors colors) {
    final selected = widget.currentIndex == index;
    final color = selected ? colors.accent : colors.textSecondary;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onTap(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icons[index], size: 22, color: color),
              const SizedBox(height: AppSpacing.xs / 2),
              Text(
                _labels[index],
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
