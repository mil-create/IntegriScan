import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';
import '../models/scan_history_item.dart';

/// Chronologically structured grid of past scans, showing body area,
/// AI confidence score, risk level, and time-since-scan — used both as
/// the "Progress" tab and as the destination for "View Past Scan
/// History" from the scan overlay menu.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  static final List<ScanHistoryItem> _history = [
    ScanHistoryItem(
      id: '1',
      bodyArea: 'Left Forearm',
      scannedAt: DateTime.now().subtract(const Duration(days: 1)),
      confidence: 0.94,
      risk: RiskLevel.low,
    ),
    ScanHistoryItem(
      id: '2',
      bodyArea: 'Scalp - Crown',
      scannedAt: DateTime.now().subtract(const Duration(days: 4)),
      confidence: 0.81,
      risk: RiskLevel.moderate,
    ),
    ScanHistoryItem(
      id: '3',
      bodyArea: 'Upper Back',
      scannedAt: DateTime.now().subtract(const Duration(days: 9)),
      confidence: 0.76,
      risk: RiskLevel.high,
    ),
    ScanHistoryItem(
      id: '4',
      bodyArea: 'Right Cheek',
      scannedAt: DateTime.now().subtract(const Duration(days: 15)),
      confidence: 0.97,
      risk: RiskLevel.low,
    ),
    ScanHistoryItem(
      id: '5',
      bodyArea: 'Neck',
      scannedAt: DateTime.now().subtract(const Duration(days: 22)),
      confidence: 0.88,
      risk: RiskLevel.moderate,
    ),
    ScanHistoryItem(
      id: '6',
      bodyArea: 'Left Forearm',
      scannedAt: DateTime.now().subtract(const Duration(days: 30)),
      confidence: 0.90,
      risk: RiskLevel.low,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final grouped = _groupByMonth(_history);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Scan Progress',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xs),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Track how each spot changes over time',
              style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
            ),
          ),
        ),
        for (final group in grouped.entries) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
            sliver: SliverToBoxAdapter(
              child: Text(
                group.key,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.82,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ScanCard(item: group.value[index], colors: colors),
                childCount: group.value.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl * 5)),
      ],
    );
  }

  Map<String, List<ScanHistoryItem>> _groupByMonth(List<ScanHistoryItem> items) {
    final sorted = [...items]..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    final map = <String, List<ScanHistoryItem>>{};
    for (final item in sorted) {
      final key = _monthLabel(item.scannedAt);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  String _monthLabel(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _ScanCard extends StatelessWidget {
  final ScanHistoryItem item;
  final AppColors colors;

  const _ScanCard({required this.item, required this.colors});

  Color _riskColor() {
    switch (item.risk) {
      case RiskLevel.low:
        return colors.success;
      case RiskLevel.moderate:
        return colors.warning;
      case RiskLevel.high:
        return colors.danger;
    }
  }

  String _riskLabel() {
    switch (item.risk) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.moderate:
        return 'Moderate';
      case RiskLevel.high:
        return 'High Risk';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.accentSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.placeholderIcon, color: colors.accent, size: 30),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.bodyArea,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: _riskColor(), shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                _riskLabel(),
                style: TextStyle(
                  fontSize: 10.5,
                  color: _riskColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(item.confidence * 100).round()}%',
                style: TextStyle(
                  fontSize: 10.5,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _timeAgo(item.scannedAt),
            style: TextStyle(fontSize: 10, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return '$days days ago';
  }
}

