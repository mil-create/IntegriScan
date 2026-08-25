import 'package:flutter/material.dart';
import '../theme/theme_provider.dart';
import '../theme/app_colors.dart';
import '../theme/button_styles.dart';
import '../theme/spacing.dart';
import '../models/clinical_log.dart';
import 'package:provider/provider.dart';

class ScanPhotoPreviewDialog extends StatelessWidget {
  final List<ClinicalLogEntry> logs;

  const ScanPhotoPreviewDialog({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final DateTime date = logs[0].loggedAt;

    return Dialog(
      backgroundColor: colors.surface,
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(color: colors.border),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Scan Photos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs / 2),
                  Text(
                    '${date.month}/${date.day}/${date.year}',
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Photos grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return _buildScanItem(context, log, colors);
                },
              ),
            ),

            // Close button
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanItem(BuildContext context, ClinicalLogEntry log, AppColors colors) {
    return GestureDetector(
      onTap: () {
        // Navigate to full-screen image viewer in the parent screen
        // This widget assumes the parent will handle navigation
        // For standalone use, we show a detail dialog
        _showScanDetailDialog(context, log, colors);
      },
      child: Semantics(
        button: true,
        enabled: true,
        label: 'View scan details for ${log.condition}',
        child: Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image placeholder
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppSpacing.md * 0.75), // 9 ≈ 12*0.75
                      topRight: Radius.circular(AppSpacing.md * 0.75), // 9 ≈ 12*0.75
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        log.icon,
                        size: AppSpacing.lg * 1.33, // 27 ≈ 20*1.33
                        color: log.icon == Icons.priority_high_rounded
                            ? colors.danger
                            : log.icon == Icons.water_drop_outlined
                                ? colors.warning
                                : colors.accent,
                      ),
                      const SizedBox(height: AppSpacing.xs / 2),
                      Text(
                        log.bodyArea.split(' ')[0], // Just first part for brevity
                        style: TextStyle(
                          fontSize: AppSpacing.sm * 0.75, // 9 ≈ 12*0.75
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.condition,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Confidence: ${(log.confidence * 100).round()}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScanDetailDialog(BuildContext context, ClinicalLogEntry log, AppColors colors) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            log.condition,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  Icons.pan_tool_rounded,
                  'Body Area',
                  log.bodyArea,
                  colors,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.calendar_today,
                  'Date',
                  '${log.loggedAt.month}/${log.loggedAt.day}/${log.loggedAt.year}',
                  colors,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.percent,
                  'Confidence',
                  '${(log.confidence * 100).round()}%',
                  colors,
                ),
                const SizedBox(height: 8),
                _buildInfoRowWithValueColor(
                  Icons.error_outline,
                  'Risk Level',
                  log.risk.toString().split('.').last,
                  log.risk == RiskLevel.high
                      ? colors.danger
                      : log.risk == RiskLevel.moderate
                          ? colors.warning
                          : colors.success,
                  colors,
                ),
                const SizedBox(height: 16),
                Text(
                  'Recommendations:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...log.recommendations.map((rec) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(color: colors.accent)),
                          Expanded(
                            child: Text(
                              rec,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: textButtonStyle(context, foregroundColor: colors.textSecondary),
              child: const Text(
                'Close',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, AppColors colors) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowWithValueColor(IconData icon, String label, String value, Color valueColor, AppColors colors) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}