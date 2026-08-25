import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';

/// Horizontal quick-link tile: icon badge, title + subtitle, chevron.
/// Used on the Home Dashboard to surface Pathology Triage, Clinical
/// Logs, and the AI chatbot as one-tap destinations.
class QuickLinkTile extends StatefulWidget {
  final AppColors colors;
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final String? trailingBadge;
  final VoidCallback onTap;

  const QuickLinkTile({
    super.key,
    required this.colors,
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingBadge,
  });

  /// Calculates the relative luminance of a color for contrast checking
  static double calculateLuminance(Color color) {
    final double r = color.r;
    final double g = color.g;
    final double b = color.b;

    final double rsrgb = r <= 0.03928 ? r / 12.92 : math.pow((r + 0.055) / 1.055, 2.4).toDouble();
    final double gsrgb = g <= 0.03928 ? g / 12.92 : math.pow((g + 0.055) / 1.055, 2.4).toDouble();
    final double bsrgb = b <= 0.03928 ? b / 12.92 : math.pow((b + 0.055) / 1.055, 2.4).toDouble();

    return 0.2126 * rsrgb + 0.7152 * gsrgb + 0.0722 * bsrgb;
  }

  /// Returns white or black color based on which provides better contrast with the background
  static Color getContrastColor(Color background) {
    final double luminance = calculateLuminance(background);
    // Use WCAG 2.0 formula: if luminance > 0.5, use black; otherwise use white
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  @override
  State<QuickLinkTile> createState() => _QuickLinkTileState();
}

class _QuickLinkTileState extends State<QuickLinkTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => _onTapDown(),
        onTapUp: (_) => _onTapUp(),
        onTapCancel: _onTapUp,
        onTap: widget.onTap,
        child: Semantics(
          button: true,
          enabled: true,
          label: widget.title,
          child: Material(
            color: widget.colors.surface,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm - 2), // 12 = 14-2
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                  border: Border.all(color: widget.colors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: AppSpacing.md * 3.0,
                      height: AppSpacing.md * 3.0,
                      decoration: BoxDecoration(
                        color: widget.tint,
                        borderRadius: BorderRadius.circular(AppSpacing.xs - 2), // 6 = 8-2
                        boxShadow: [
                          BoxShadow(
                            color: widget.tint.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: QuickLinkTile.getContrastColor(widget.tint),
                        size: AppSpacing.md * 1.125,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: widget.colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs - 6), // 2 = 8-6
                          Text(
                            widget.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: widget.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.trailingBadge != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs - 2,
                          vertical: AppSpacing.xs / 3,
                        ),
                        decoration: BoxDecoration(
                          color: widget.tint.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppSpacing.xs - 2), // 6 = 8-2
                        ),
                        child: Text(
                          widget.trailingBadge!,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: widget.tint,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs - 2), // 6 = 8-2
                    ],
                    Icon(
                      Icons.chevron_right_rounded,
                      color: widget.colors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTapDown() {
    if (mounted) {
      setState(() => _pressed = true);
    }
  }

  void _onTapUp() {
    if (mounted) {
      setState(() => _pressed = false);
    }
  }
}

/// Primary variant of QuickLinkTile with elevated styling for primary actions
class PrimaryQuickLinkTile extends StatefulWidget {
  final AppColors colors;
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final String? trailingBadge;
  final VoidCallback onTap;

  const PrimaryQuickLinkTile({
    super.key,
    required this.colors,
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingBadge,
  });

  @override
  State<PrimaryQuickLinkTile> createState() => _PrimaryQuickLinkTileState();
}

class _PrimaryQuickLinkTileState extends State<PrimaryQuickLinkTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Semantics(
        button: true,
        enabled: true,
        label: widget.title,
        child: GestureDetector(
          onTapDown: (_) => _onTapDown(),
          onTapUp: (_) => _onTapUp(),
          onTapCancel: _onTapUp,
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: widget.colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: widget.colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: AppSpacing.lg,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Material(
                child: InkWell(
                  onTap: widget.onTap,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: AppSpacing.lg * 2.5,
                          height: AppSpacing.lg * 2.5,
                          decoration: BoxDecoration(
                            color: widget.tint,
                            borderRadius: BorderRadius.circular(AppSpacing.lg),
                          ),
                          child: Icon(
                            widget.icon,
                            color: QuickLinkTile.getContrastColor(widget.tint),
                            size: AppSpacing.lg,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: widget.colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs - 4),
                              Text(
                                widget.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: widget.colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.trailingBadge != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs / 2,
                            ),
                            decoration: BoxDecoration(
                              color: widget.tint.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(AppSpacing.md),
                            ),
                            child: Text(
                              widget.trailingBadge!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: widget.tint,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md - 4),
                        ],
                        Icon(
                          Icons.chevron_right_rounded,
                          color: widget.colors.textSecondary,
                          size: AppSpacing.md,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTapDown() {
    if (mounted) {
      setState(() => _pressed = true);
    }
  }

  void _onTapUp() {
    if (mounted) {
      setState(() => _pressed = false);
    }
  }
}