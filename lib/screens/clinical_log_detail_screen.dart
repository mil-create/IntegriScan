import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_colors.dart';
import '../theme/button_styles.dart';
import '../theme/spacing.dart';
import '../models/clinical_log.dart';
import '../widgets/sparkline_chart.dart';

class ClinicalLogDetailScreen extends StatefulWidget {
  final ClinicalLogEntry log;

  const ClinicalLogDetailScreen({super.key, required this.log});

  @override
  State<ClinicalLogDetailScreen> createState() => _ClinicalLogDetailScreenState();
}

class _ClinicalLogDetailScreenState extends State<ClinicalLogDetailScreen> {
  bool _reviewed = false;

  Color _riskColor(AppColors colors) {
    switch (widget.log.risk) {
      case RiskLevel.low:
        return colors.success;
      case RiskLevel.moderate:
        return colors.warning;
      case RiskLevel.high:
        return colors.danger;
    }
  }

  String get _riskLabel {
    switch (widget.log.risk) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.moderate:
        return 'Moderate Risk';
      case RiskLevel.high:
        return 'High Risk';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final riskColor = _riskColor(colors);
    final log = widget.log;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(log.condition, style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xl * 2), // 40 = 20*2
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg * 2.5), // 50 = 20*2.5
            decoration: BoxDecoration(
              color: riskColor,
              borderRadius: BorderRadius.circular(AppSpacing.lg * 3), // 78 ~ 26*3
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm / 2, vertical: AppSpacing.xs / 4), // 5 = 10/2, 2 = 8/4
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppSpacing.lg * 1.25), // 25 = 20*1.25
                  ),
                  child: Text(_riskLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '${(log.confidence * 100).round()}% confidence',
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.xs / 4), // 2 = 8/4
                Text(
                  '${log.bodyArea} · logged ${_dateLabel(log.loggedAt)}',
                  style: TextStyle(color: colors.textPrimary.withValues(alpha: 0.85), fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg - 2), // 16 = 18-2
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg - 2), // 16 = 18-2
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.lg * 1.1), // 22 ~ 20*1.1
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Confidence Trend', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 90,
                  width: double.infinity,
                  child: SparklineChart(
                    values: log.trend,
                    lineColor: colors.accent,
                    fillColor: colors.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg - 2), // 16 = 18-2
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg - 2), // 16 = 18-2
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.lg * 1.1), // 22 ~ 20*1.1
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                const SizedBox(height: AppSpacing.md),
                _DetailRow(colors: colors, label: 'Body Area', value: log.bodyArea),
                _DetailRow(colors: colors, label: 'Date Logged', value: _dateLabel(log.loggedAt)),
                _DetailRow(colors: colors, label: 'AI Confidence', value: '${(log.confidence * 100).round()}%'),
                _DetailRow(colors: colors, label: 'Risk Level', value: _riskLabel, valueColor: riskColor),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg - 2), // 16 = 18-2
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg - 2), // 16 = 18-2
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.lg * 1.1), // 22 ~ 20*1.1
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recommendations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                const SizedBox(height: AppSpacing.md),
                for (final rec in log.recommendations) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md), // 16
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 18, color: colors.accent),
                            const SizedBox(width: AppSpacing.sm), // 12
                            Expanded(
                              child: Text(
                                rec,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs - 2), // 6 = 8-2
                        Text(
                          _getRecommendationExplanation(log.condition, rec),
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _reviewed ? null : () => setState(() => _reviewed = true),
              style: elevatedButtonStyle(
                context,
                backgroundColor: _reviewed ? colors.success : colors.accent,
              ),
              child: Text(
                _reviewed ? 'Marked as Reviewed ✓' : 'Mark as Reviewed',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRecommendationExplanation(String condition, String recommendation) {
    // Provide brief, educational explanations for why each recommendation is helpful
    final explanationMap = {
      'Apply fragrance-free moisturizer twice daily':
          'Fragrance-free moisturizers help restore the skin barrier without irritating sensitive skin.',
      'Avoid known irritants for 5–7 days':
          'Giving skin time to heal by avoiding triggers reduces inflammation and promotes faster recovery.',
      'Rescan in 5 days to confirm improvement':
          'Follow-up scans help track progress and ensure the treatment is working effectively.',
      'Use an anti-dandruff shampoo 2–3x per week':
          'Regular use helps control yeast growth on the scalp that causes flaking and irritation.',
      'Avoid excessive heat styling':
          'Heat can damage hair follicles and irritate the scalp, slowing down healing processes.',
      'Track flaking severity in your next scan':
          'Monitoring changes over time helps determine if treatments are reducing scalp inflammation.',
      'Schedule an in-person dermatologist visit':
          'Professional evaluation ensures accurate diagnosis and appropriate treatment plan.',
      'Avoid direct sun exposure on the area':
          'UV exposure can worsen pigmentation issues and delay healing of skin lesions.',
      'Bring your scan history to the appointment':
          'Visual documentation helps dermatologists understand the progression of your condition.',
      'Continue your current routine — it\'s working':
          'Consistency is key - maintaining what\'s helping prevents regression and promotes healing.',
      'No further action needed for this spot':
          'The condition has resolved, but continue general skin health practices for prevention.',
      'Keep the area moisturized':
          'Proper hydration supports skin barrier function and reduces irritation and itching.',
      'Avoid tight collars or fabric friction':
          'Reducing mechanical irritation allows inflamed skin to heal without additional stress.',
    };

    return explanationMap[recommendation] ??
        'Following this recommendation supports skin health and healing based on clinical best practices.';
  }

  String _dateLabel(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final AppColors colors;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.colors, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12.5, color: colors.textSecondary)),
          Text(
            value,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: valueColor ?? colors.textPrimary),
          ),
        ],
      ),
    );
  }
}
