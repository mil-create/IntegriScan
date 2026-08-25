import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';

class MetricsBanner extends StatelessWidget {
  const MetricsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs - 4), // 4 = 8-4
      child: Row(
        children: [
          Expanded(
            child: _MetricCard(
              colors: colors,
              label: 'Scans Done',
              value: '12',
              icon: Icons.check_circle_outline_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.sm - 2), // 8 = 10-2
          Expanded(
            child: _MetricCard(
              colors: colors,
              label: 'This Week',
              value: '3',
              icon: Icons.calendar_today_outlined,
            ),
          ),
          const SizedBox(width: AppSpacing.sm - 2), // 8 = 10-2
          Expanded(
            child: _MetricCard(
              colors: colors,
              label: 'Alerts',
              value: '1',
              icon: Icons.notifications_active_outlined,
              highlight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final AppColors colors;
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _MetricCard({
    required this.colors,
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: AppSpacing.lg * 3 / 2, // 18 = 12*1.5
              offset: const Offset(0, AppSpacing.sm - 4), // 4 = 8-4
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeIn,
              opacity: 1.0,
              child: Icon(icon, size: AppSpacing.lg, color: highlight ? colors.danger : colors.accent),
            ),
            const SizedBox(height: AppSpacing.sm - 2), // 8 = 10-2
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
              child: Text(value),
            ),
            const SizedBox(height: AppSpacing.xs - 6), // 2 = 8-6
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              style: TextStyle(
                fontSize: 11.5,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}