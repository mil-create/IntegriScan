import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';
import 'sparkline_chart.dart';

/// Full-width gradient hero card showing a headline score, modeled after
/// the "Asklepios Score" pattern — a big number the user can read at a
/// glance, with a status pill and an optional trend strip underneath.
class ScoreHeroCard extends StatefulWidget {
  final AppColors colors;
  final String statusLabel;
  final String scoreValue;
  final String scoreUnit;
  final String subtitle;
  final List<double>? trend;
  final VoidCallback? onTap;
  final Color? overrideColor; // lets Triage results tint red/amber for risk

  const ScoreHeroCard({
    super.key,
    required this.colors,
    required this.statusLabel,
    required this.scoreValue,
    required this.subtitle,
    this.scoreUnit = '',
    this.trend,
    this.onTap,
    this.overrideColor,
  });

  @override
  State<ScoreHeroCard> createState() => _ScoreHeroCardState();
}

class _ScoreHeroCardState extends State<ScoreHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.overrideColor ?? widget.colors.accent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTapDown: (_) {
          _controller.stop();
        },
        onTapUp: (_) {
          _controller.repeat(reverse: true);
        },
        onTapCancel: () {
          _controller.repeat(reverse: true);
        },
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [base, Color.lerp(base, Colors.black, 0.35)!],
            ),
            boxShadow: [
              BoxShadow(
                color: base.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    widget.scoreValue,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  if (widget.scoreUnit.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      widget.scoreUnit,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5),
              ),
              if (widget.trend != null && widget.trend!.length > 1) ...[
                const SizedBox(height: AppSpacing.md),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  child: SizedBox(
                    height: 44,
                    width: double.infinity,
                    child: SparklineChart(
                      values: widget.trend!,
                      lineColor: Colors.white,
                      fillColor: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}