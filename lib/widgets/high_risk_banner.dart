import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';

class HighRiskBanner extends StatelessWidget {
  final AppColors colors;
  final VoidCallback onViewClinics;
  final VoidCallback onDismiss;

  const HighRiskBanner({
    super.key,
    required this.colors,
    required this.onViewClinics,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.danger.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.priority_high_rounded, color: colors.danger, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'High-risk result detected',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs - 6), // 2 = 8-6
                Text(
                  'We recommend seeing a dermatologist soon.',
                  style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm - 2), // 8 = 10-2
                Row(
                  children: [
                    GestureDetector(
                      onTap: onViewClinics,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: colors.danger,
                          borderRadius: BorderRadius.circular(AppSpacing.md),
                        ),
                        child: const Text(
                          'Find Nearby Clinics',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm - 2), // 8 = 10-2
                    GestureDetector(
                      onTap: onDismiss,
                      child: Text(
                        'Dismiss',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
