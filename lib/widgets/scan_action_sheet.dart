import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';

/// Overlay menu presented when the central scan button is tapped.
/// Offers the 3 required routes: live camera, library upload, or
/// jumping straight to past scan history.
/// The live camera and upload options now properly navigate to the screening flow.
class ScanActionSheet extends StatelessWidget {
  final VoidCallback onViewHistory;
  final VoidCallback onTakePhoto;
  final VoidCallback onUploadPhoto;

  const ScanActionSheet({
    super.key,
    required this.onViewHistory,
    required this.onTakePhoto,
    required this.onUploadPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.xl + 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: AppSpacing.lg * 1.5,
              offset: const Offset(0, AppSpacing.md),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSpacing.md * 2.5,
              height: AppSpacing.xs / 2,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(AppSpacing.xs),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'New Skin Scan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs / 2),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose how you want to analyze your skin',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _Option(
              colors: colors,
              icon: Icons.camera_alt_rounded,
              label: 'Take Live Photo',
              subtitle: 'Use your camera for a real-time scan',
              onTap: onTakePhoto,
            ),
            const SizedBox(height: AppSpacing.sm),
            _Option(
              colors: colors,
              icon: Icons.photo_library_rounded,
              label: 'Upload from Device Library',
              subtitle: 'Choose an existing photo',
              onTap: onUploadPhoto,
            ),
            const SizedBox(height: AppSpacing.sm),
            _Option(
              colors: colors,
              icon: Icons.history_rounded,
              label: 'View Past Scan History',
              subtitle: 'Track how a spot has changed over time',
              onTap: onViewHistory,
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final AppColors colors;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _Option({
    required this.colors,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.background,
      borderRadius: BorderRadius.circular(AppSpacing.lg - 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.lg - 2),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: AppSpacing.lg * 2.2, // 44 ≈ 20*2.2
                height: AppSpacing.lg * 2.2, // 44 ≈ 20*2.2
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.accent, width: AppSpacing.xs / 5),
                ),
                child: Icon(icon, color: colors.accent, size: AppSpacing.md),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs / 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
