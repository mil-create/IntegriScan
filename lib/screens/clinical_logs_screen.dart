import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../theme/theme_provider.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';
import '../models/clinical_log.dart';
import 'clinical_log_detail_screen.dart';
import '../widgets/skeleton_screens.dart';
import '../utils/retry_util.dart';
import '../widgets/svg_icon.dart';

class ClinicalLogsScreen extends StatefulWidget {
  final VoidCallback onLogNewScan;

  const ClinicalLogsScreen({super.key, required this.onLogNewScan});

  @override
  State<ClinicalLogsScreen> createState() => _ClinicalLogsScreenState();
}

class _ClinicalLogsScreenState extends State<ClinicalLogsScreen> {
  late VoidCallback onLogNewScan;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late List<ClinicalLogEntry> _allLogs;
  late List<ClinicalLogEntry> _filteredLogs;
  late Map<DateTime, List<ClinicalLogEntry>> markers;
  bool _isLoading = true; // Track loading state for skeleton screens

  // Filter state
  DateTimeRange? _selectedDateRange;
  List<String> _selectedBodyParts = [];
  List<RiskLevel> _selectedRiskLevels = [];
  List<LogStatus> _selectedStatuses = [];
  double _minConfidence = 0.0;

  // Sort state
  String _selectedSortOption = 'Date (Newest First)';

  // Helper function to compare dates ignoring time component
  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Available filter options
  List<String> _availableBodyParts = [];
  final List<RiskLevel> _availableRiskLevels = RiskLevel.values;
  final List<LogStatus> _availableStatuses = LogStatus.values;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _allLogs = [];
    _filteredLogs = [];
    markers = {};
    onLogNewScan = widget.onLogNewScan;
    _loadLogs().then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _applyFiltersAndSort();
        });
      }
    });
  }

  Future<void> _loadLogs() async {
    await Future.delayed(const Duration(milliseconds: 800));

    await RetryUtil.retryOperation<bool>(
      () async {
        _allLogs = _generateLogs();
        _availableBodyParts = _allLogs.map((log) => log.bodyArea).toSet().toList();
        _availableBodyParts.sort();
        return true;
      },
      maxAttempts: 2,
    );
  }

  List<ClinicalLogEntry> _generateLogs() {
    final now = DateTime.now();
    return [
      ClinicalLogEntry(
        id: '1',
        bodyArea: 'Left Forearm',
        condition: 'Mild Contact Dermatitis',
        loggedAt: now.subtract(const Duration(days: 1)),
        confidence: 0.94,
        risk: RiskLevel.low,
        status: LogStatus.monitoring,
        trend: [0.55, 0.6, 0.7, 0.66, 0.8, 0.88, 0.94],
        icon: Icons.pan_tool_rounded,
        recommendations: [
          'Apply fragrance-free moisturizer twice daily',
          'Avoid known irritants for 5–7 days',
          'Rescan in 5 days to confirm improvement',
        ],
        imagePath: 'assets/scans/scan_1.jpg',
      ),
      ClinicalLogEntry(
        id: '2',
        bodyArea: 'Scalp - Crown',
        condition: 'Seborrheic Dermatitis',
        loggedAt: now.subtract(const Duration(days: 4)),
        confidence: 0.81,
        risk: RiskLevel.moderate,
        status: LogStatus.monitoring,
        trend: [0.4, 0.5, 0.62, 0.7, 0.75, 0.81],
        icon: Icons.face_6_rounded,
        recommendations: [
          'Use an anti-dandruff shampoo 2–3x per week',
          'Avoid excessive heat styling',
          'Track flaking severity in your next scan',
        ],
        imagePath: 'assets/scans/scan_2.jpg',
      ),
      ClinicalLogEntry(
        id: '3',
        bodyArea: 'Upper Back',
        condition: 'Irregular Pigmented Lesion',
        loggedAt: now.subtract(const Duration(days: 9)),
        confidence: 0.76,
        risk: RiskLevel.high,
        status: LogStatus.escalated,
        trend: [0.3, 0.35, 0.5, 0.6, 0.68, 0.76],
        icon: Icons.priority_high_rounded,
        recommendations: [
          'Schedule an in-person dermatologist visit',
          'Avoid direct sun exposure on the area',
          'Bring your scan history to the appointment',
        ],
        imagePath: 'assets/scans/scan_3.jpg',
      ),
      ClinicalLogEntry(
        id: '4',
        bodyArea: 'Right Cheek',
        condition: 'Resolved Acne Lesion',
        loggedAt: now.subtract(const Duration(days: 15)),
        confidence: 0.97,
        risk: RiskLevel.low,
        status: LogStatus.resolved,
        trend: [0.5, 0.62, 0.7, 0.8, 0.9, 0.97],
        icon: Icons.face_retouching_natural_rounded,
        recommendations: [
          "Continue your current routine — it's working",
          'No further action needed for this spot',
        ],
        imagePath: 'assets/scans/scan_4.jpg',
      ),
      ClinicalLogEntry(
        id: '5',
        bodyArea: 'Neck',
        condition: 'Mild Eczema Flare',
        loggedAt: now.subtract(const Duration(days: 22)),
        confidence: 0.88,
        risk: RiskLevel.moderate,
        status: LogStatus.resolved,
        trend: [0.45, 0.5, 0.6, 0.7, 0.8, 0.88],
        icon: Icons.water_drop_outlined,
        recommendations: [
          'Keep the area moisturized',
          'Avoid tight collars or fabric friction',
        ],
        imagePath: 'assets/scans/scan_5.jpg',
      ),
    ];
  }

  void _applyFiltersAndSort() {
    List<ClinicalLogEntry> filtered = List.from(_allLogs);

    if (_selectedDateRange != null) {
      filtered = filtered.where((log) {
        final logDate = DateTime(log.loggedAt.year, log.loggedAt.month, log.loggedAt.day);
        return logDate.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
               logDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    if (_selectedBodyParts.isNotEmpty) {
      filtered = filtered.where((log) => _selectedBodyParts.contains(log.bodyArea)).toList();
    }

    if (_selectedRiskLevels.isNotEmpty) {
      filtered = filtered.where((log) => _selectedRiskLevels.contains(log.risk)).toList();
    }

    if (_selectedStatuses.isNotEmpty) {
      filtered = filtered.where((log) => _selectedStatuses.contains(log.status)).toList();
    }

    if (_minConfidence > 0) {
      filtered = filtered.where((log) => log.confidence >= _minConfidence).toList();
    }

    switch (_selectedSortOption) {
      case 'Date (Newest First)':
        filtered.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
        break;
      case 'Date (Oldest First)':
        filtered.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
        break;
      case 'Risk (High→Low)':
        filtered.sort((a, b) => _riskLevelToInt(b.risk).compareTo(_riskLevelToInt(a.risk)));
        break;
      case 'Risk (Low→High)':
        filtered.sort((a, b) => _riskLevelToInt(a.risk).compareTo(_riskLevelToInt(b.risk)));
        break;
      case 'Body Part (A-Z)':
        filtered.sort((a, b) => a.bodyArea.compareTo(b.bodyArea));
        break;
      case 'Body Part (Z-A)':
        filtered.sort((a, b) => b.bodyArea.compareTo(a.bodyArea));
        break;
      case 'Confidence (High→Low)':
        filtered.sort((a, b) => b.confidence.compareTo(a.confidence));
        break;
      case 'Confidence (Low→High)':
        filtered.sort((a, b) => a.confidence.compareTo(b.confidence));
        break;
      default:
        filtered.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    }

    setState(() {
      _filteredLogs = filtered;
      markers = _computeMarkers(_filteredLogs);
    });
  }

  int _riskLevelToInt(RiskLevel level) {
    switch (level) {
      case RiskLevel.low: return 0;
      case RiskLevel.moderate: return 1;
      case RiskLevel.high: return 2;
    }
  }

  Map<DateTime, List<ClinicalLogEntry>> _computeMarkers(List<ClinicalLogEntry> logs) {
    final map = <DateTime, List<ClinicalLogEntry>>{};
    for (final log in logs) {
      final date = DateTime(log.loggedAt.year, log.loggedAt.month, log.loggedAt.day);
      if (map[date] == null) {
        map[date] = <ClinicalLogEntry>[];
      }
      map[date]!.add(log);
    }
    return map;
  }

  String _getWeeklyDateRange(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return '${DateFormat.MMMd().format(startOfWeek)} - ${DateFormat.MMMd().format(endOfWeek)}';
  }

  int _calculateScanStreak() {
    if (_filteredLogs.isEmpty) return 0;

    final sortedLogs = List<ClinicalLogEntry>.from(_filteredLogs);
    sortedLogs.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

    int streak = 0;
    DateTime? lastDate;

    for (final log in sortedLogs) {
      final logDate = DateTime(log.loggedAt.year, log.loggedAt.month, log.loggedAt.day);

      if (lastDate == null) {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        if (_isSameDate(logDate, today) || _isSameDate(logDate, yesterday)) {
          streak = 1;
          lastDate = logDate;
        } else {
          break;
        }
      } else {
        final difference = lastDate.difference(logDate).inDays;
        if (difference == 1) {
          streak++;
          lastDate = logDate;
        } else if (difference == 0) {
          continue;
        } else {
          break;
        }
      }
    }

    return streak;
  }

  int _getMonthlyScanCount() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    return _filteredLogs.where((log) {
      final logDate = DateTime(log.loggedAt.year, log.loggedAt.month, log.loggedAt.day);
      return logDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
             logDate.isBefore(DateTime(now.year, now.month + 1, 1));
    }).length;
  }

  String _getMonthlyScanTrend() {
    final now = DateTime.now();
    final startOfCurrentMonth = DateTime(now.year, now.month, 1);
    final startOfPreviousMonth = DateTime(now.year, now.month - 1, 1);
    final endOfPreviousMonth = DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));

    final currentMonthCount = _filteredLogs.where((log) {
      final logDate = DateTime(log.loggedAt.year, log.loggedAt.month, log.loggedAt.day);
      return logDate.isAfter(startOfCurrentMonth.subtract(const Duration(days: 1))) &&
             logDate.isBefore(DateTime(now.year, now.month + 1, 1));
    }).length;

    final previousMonthCount = _filteredLogs.where((log) {
      final logDate = DateTime(log.loggedAt.year, log.loggedAt.month, log.loggedAt.day);
      return logDate.isAfter(startOfPreviousMonth.subtract(const Duration(days: 1))) &&
             logDate.isBefore(endOfPreviousMonth.add(const Duration(days: 1)));
    }).length;

    if (previousMonthCount == 0) {
      return currentMonthCount > 0 ? '↑' : '-';
    }

    if (currentMonthCount > previousMonthCount) {
      return '↑';
    } else if (currentMonthCount < previousMonthCount) {
      return '↓';
    } else {
      return '→';
    }
  }

  Widget _buildEmptyLogsView(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl * 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              Icons.face_rounded,
              size: 50,
              color: colors.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No scans for ${DateFormat.MMMd().format(_selectedDay)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Regular tracking helps identify changes early',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              '• Track treatment effectiveness over time\n• Identify patterns and triggers\n• Provide valuable data for healthcare consultations',
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: widget.onLogNewScan,
            icon: const Icon(Icons.add_photo_alternate, size: 20),
            label: const Text(
              'Log Your First Scan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg * 1.5,
                vertical: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showScanPhotoPreviewDialog(BuildContext context, List<ClinicalLogEntry> logs, AppColors colors) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Scan Photos for ${logs[0].loggedAt.month}/${logs[0].loggedAt.day}/${logs[0].loggedAt.year}',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs - 4),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      _showFullScreenImageViewer(context, log, colors);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: AppSpacing.md * 2.5,
                            height: AppSpacing.md * 2.5,
                            decoration: BoxDecoration(
                              color: colors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppSpacing.xs - 4),
                            ),
                            child: Icon(
                              log.icon,
                              color: colors.accent,
                              size: AppSpacing.md - 4,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.condition,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs - 4),
                                Text(
                                  '${log.bodyArea} · ${(log.confidence * 100).round()}% confidence',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: colors.textSecondary,
              ),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showFullScreenImageViewer(BuildContext context, ClinicalLogEntry log, AppColors colors) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: colors.background.withValues(alpha: 0.9),
            child: Center(
              child: log.imagePath != null
                  ? Image(
                      image: AssetImage(log.imagePath!),
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          'Failed to load image. Please try again.',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ),
                    )
                  : Icon(
                      Icons.broken_image,
                      size: 100,
                      color: colors.textSecondary,
                    ),
            ),
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet(BuildContext context, AppColors colors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.border.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Filter & Sort',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.md),
                          ),
                        ),
                        child: const Text('Filter'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.accent,
                          side: BorderSide(color: colors.accent),
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.md),
                          ),
                        ),
                        child: const Text('Sort'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Date Range',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    FilterChip(
                      label: const Text('Last 7 days'),
                      selected: _selectedDateRange != null &&
                          _isSameDate(_selectedDateRange!.start, DateTime.now().subtract(const Duration(days: 7))) &&
                          _isSameDate(_selectedDateRange!.end, DateTime.now()),
                      onSelected: (selected) {
                        setState(() {
                          _selectedDateRange = selected
                              ? DateTimeRange(
                                  start: DateTime.now().subtract(const Duration(days: 7)),
                                  end: DateTime.now(),
                                )
                              : null;
                        });
                        _applyFiltersAndSort();
                      },
                      backgroundColor: colors.background,
                      selectedColor: colors.accentSoft,
                      labelStyle: TextStyle(color: colors.textPrimary),
                    ),
                    FilterChip(
                      label: const Text('Last 30 days'),
                      selected: _selectedDateRange != null &&
                          _isSameDate(_selectedDateRange!.start, DateTime.now().subtract(const Duration(days: 30))) &&
                          _isSameDate(_selectedDateRange!.end, DateTime.now()),
                      onSelected: (selected) {
                        setState(() {
                          _selectedDateRange = selected
                              ? DateTimeRange(
                                  start: DateTime.now().subtract(const Duration(days: 30)),
                                  end: DateTime.now(),
                                )
                              : null;
                        });
                        _applyFiltersAndSort();
                      },
                      backgroundColor: colors.background,
                      selectedColor: colors.accentSoft,
                      labelStyle: TextStyle(color: colors.textPrimary),
                    ),
                    FilterChip(
                      label: const Text('Last 3 months'),
                      selected: _selectedDateRange != null &&
                          _isSameDate(_selectedDateRange!.start, DateTime.now().subtract(const Duration(days: 90))) &&
                          _isSameDate(_selectedDateRange!.end, DateTime.now()),
                      onSelected: (selected) {
                        setState(() {
                          _selectedDateRange = selected
                              ? DateTimeRange(
                                  start: DateTime.now().subtract(const Duration(days: 90)),
                                  end: DateTime.now(),
                                )
                              : null;
                        });
                        _applyFiltersAndSort();
                      },
                      backgroundColor: colors.background,
                      selectedColor: colors.accentSoft,
                      labelStyle: TextStyle(color: colors.textPrimary),
                    ),
                    FilterChip(
                      label: const Text('Custom'),
                      selected: _selectedDateRange != null &&
                          !(_isSameDate(_selectedDateRange!.start, DateTime.now().subtract(const Duration(days: 7))) &&
                              _isSameDate(_selectedDateRange!.end, DateTime.now())) &&
                          !(_isSameDate(_selectedDateRange!.start, DateTime.now().subtract(const Duration(days: 30))) &&
                              _isSameDate(_selectedDateRange!.end, DateTime.now())) &&
                          !(_isSameDate(_selectedDateRange!.start, DateTime.now().subtract(const Duration(days: 90))) &&
                              _isSameDate(_selectedDateRange!.end, DateTime.now())),
                      onSelected: (selected) {
                        if (selected) {
                          _showDateRangePicker(context, colors);
                        } else {
                          setState(() {
                            _selectedDateRange = null;
                          });
                          _applyFiltersAndSort();
                        }
                      },
                      backgroundColor: colors.background,
                      selectedColor: colors.accentSoft,
                      labelStyle: TextStyle(color: colors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (_availableBodyParts.isNotEmpty) ...[
                  const Text(
                    'Body Parts',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: _availableBodyParts.map((bodyPart) {
                      return FilterChip(
                        label: Text(bodyPart),
                        selected: _selectedBodyParts.contains(bodyPart),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedBodyParts.add(bodyPart);
                            } else {
                              _selectedBodyParts.remove(bodyPart);
                            }
                          });
                          _applyFiltersAndSort();
                        },
                        backgroundColor: colors.background,
                        selectedColor: colors.accentSoft,
                        labelStyle: TextStyle(color: colors.textPrimary),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                const Text(
                  'Risk Levels',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: _availableRiskLevels.map((riskLevel) {
                    final label = riskLevel.toString().split('.').last.toUpperCase();
                    final chipColor = riskLevel == RiskLevel.low
                        ? colors.success
                        : riskLevel == RiskLevel.moderate
                            ? colors.warning
                            : colors.danger;
                    return FilterChip(
                      label: Text(label),
                      selected: _selectedRiskLevels.contains(riskLevel),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedRiskLevels.add(riskLevel);
                          } else {
                            _selectedRiskLevels.remove(riskLevel);
                          }
                        });
                        _applyFiltersAndSort();
                      },
                      backgroundColor: colors.background,
                      selectedColor: chipColor.withValues(alpha: 0.2),
                      labelStyle: TextStyle(color: chipColor),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: _availableStatuses.map((status) {
                    final label = status.toString().split('.').last;
                    final chipColor = status == LogStatus.monitoring
                        ? colors.warning
                        : status == LogStatus.resolved
                            ? colors.success
                            : colors.danger;
                    return FilterChip(
                      label: Text(label),
                      selected: _selectedStatuses.contains(status),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedStatuses.add(status);
                          } else {
                            _selectedStatuses.remove(status);
                          }
                        });
                        _applyFiltersAndSort();
                      },
                      backgroundColor: colors.background,
                      selectedColor: chipColor.withValues(alpha: 0.2),
                      labelStyle: TextStyle(color: chipColor),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Minimum Confidence',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _minConfidence,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        label: '${(_minConfidence * 100).round()}%',
                        onChanged: (value) {
                          setState(() {
                            _minConfidence = value;
                          });
                          _applyFiltersAndSort();
                        },
                        activeColor: colors.accent,
                        inactiveColor: colors.border,
                      ),
                    ),
                    Container(
                      width: 50,
                      alignment: Alignment.center,
                      child: Text(
                        '${(_minConfidence * 100).round()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Sort By',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    'Date (Newest First)',
                    'Date (Oldest First)',
                    'Risk (High→Low)',
                    'Risk (Low→High)',
                    'Body Part (A-Z)',
                    'Body Part (Z-A)',
                    'Confidence (High→Low)',
                    'Confidence (Low→High)',
                  ].map((option) {
                    return FilterChip(
                      label: Text(option),
                      selected: _selectedSortOption == option,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedSortOption = option;
                          });
                        }
                        _applyFiltersAndSort();
                      },
                      backgroundColor: colors.background,
                      selectedColor: colors.accentSoft,
                      labelStyle: TextStyle(color: colors.textPrimary),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedDateRange = null;
                            _selectedBodyParts = [];
                            _selectedRiskLevels = [];
                            _selectedStatuses = [];
                            _minConfidence = 0.0;
                            _selectedSortOption = 'Date (Newest First)';
                          });
                          _applyFiltersAndSort();
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.textSecondary,
                          side: BorderSide(color: colors.border),
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.md),
                          ),
                        ),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.md),
                          ),
                        ),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDateRangePicker(BuildContext context, AppColors colors) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: colors.accent,
              onPrimary: Colors.white,
              surface: colors.background,
              onSurface: colors.textPrimary,
            ),
            dialogTheme: DialogThemeData(backgroundColor: colors.surface),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
      _applyFiltersAndSort();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    final List<ClinicalLogEntry> logsForSelectedDay = _filteredLogs.where((log) {
      return _isSameDate(log.loggedAt, _selectedDay);
    }).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
          sliver: SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Clinical Logs',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: colors.textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => _showFilterBottomSheet(context, colors),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Every scan, tracked over time',
              style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
          sliver: SliverToBoxAdapter(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Week: ${_getWeeklyDateRange(_focusedDay)}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textSecondary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.accentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_getMonthlyScanCount()} scans this month ${_getMonthlyScanTrend()}',
                        style: TextStyle(fontSize: 12, color: colors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _calculateScanStreak() > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '🔥 ${_calculateScanStreak()} day streak',
                              style: const TextStyle(fontSize: 12, color: Colors.green),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm - 2, AppSpacing.lg, AppSpacing.md),
          sliver: SliverToBoxAdapter(
            child: _isLoading
                ? const ShimmerSkeleton(
                    type: SkeletonType.calendar,
                    height: 300,
                  )
                : TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    rangeSelectionMode: RangeSelectionMode.toggledOff,
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    daysOfWeekHeight: 20,
                    eventLoader: (day) => markers[day] ?? [],
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      formatButtonShowsNext: false,
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: colors.accent,
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      selectedTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      defaultTextStyle: TextStyle(
                        color: colors.textPrimary,
                      ),
                      weekendTextStyle: TextStyle(
                        color: colors.textSecondary,
                      ),
                      outsideTextStyle: TextStyle(
                        color: colors.textSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });

                      final logsForSelectedDay = markers[selectedDay] ?? [];
                      if (logsForSelectedDay.isNotEmpty) {
                        _showScanPhotoPreviewDialog(context, logsForSelectedDay, colors);
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarBuilders: CalendarBuilders(
                      dowBuilder: (context, date) {
                        return Center(
                          child: Text(
                            DateFormat.E().format(date)[0],
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                      markerBuilder: (context, date, events) {
                        final hasEvents = events.isNotEmpty;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasEvents ? colors.accent : Colors.transparent,
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: Text(
              '${logsForSelectedDay.length} Scan${logsForSelectedDay.length == 1 ? '' : 's'} on ${_selectedDay.month}/${_selectedDay.day}/${_selectedDay.year}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: !_isLoading && logsForSelectedDay.isEmpty
              ? SliverToBoxAdapter(
                  child: _buildEmptyLogsView(colors),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (_isLoading) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ShimmerSkeleton(
                            type: SkeletonType.logEntry,
                          ),
                        );
                      }

                      final log = logsForSelectedDay[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _LogRow(
                          colors: colors,
                          log: log,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ClinicalLogDetailScreen(log: log)),
                            );
                          },
                        ),
                      );
                    },
                    childCount: _isLoading ? 3 : logsForSelectedDay.length,
                  ),
                ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

class _LogRow extends StatelessWidget {
  final AppColors colors;
  final ClinicalLogEntry log;
  final VoidCallback onTap;

  const _LogRow({required this.colors, required this.log, required this.onTap});

  Color get _statusColor {
    switch (log.status) {
      case LogStatus.monitoring:
        return colors.warning;
      case LogStatus.resolved:
        return colors.success;
      case LogStatus.escalated:
        return colors.danger;
    }
  }

  String get _statusLabel {
    switch (log.status) {
      case LogStatus.monitoring:
        return 'Monitoring';
      case LogStatus.resolved:
        return 'Resolved';
      case LogStatus.escalated:
        return 'Escalated';
    }
  }

  String _timeAgo(DateTime date) {
    final days = DateTime.now().difference(date).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return '$days days ago';
  }

  Widget _buildLogIcon(AppColors colors, ClinicalLogEntry log) {
    // Map body areas to SVG icons for clear matches
    final bodyAreaLower = log.bodyArea.toLowerCase();

    if (bodyAreaLower.contains('scalp')) {
      return SvgIcon(
        assetName: 'scalp',
        size: 20,
        color: _statusColor,
        fallbackIcon: Icons.face_6_rounded,
      );
    } else if (bodyAreaLower.contains('face') ||
               bodyAreaLower.contains('cheek') ||
               bodyAreaLower.contains('chin') ||
               bodyAreaLower.contains('forehead')) {
      return SvgIcon(
        assetName: 'face',
        size: 20,
        color: _statusColor,
        fallbackIcon: Icons.face_retouching_natural_rounded,
      );
    } else if (bodyAreaLower.contains('neck') ||
               bodyAreaLower.contains('throat')) {
      return SvgIcon(
        assetName: 'neck',
        size: 20,
        color: _statusColor,
        fallbackIcon: Icons.accessibility_new_rounded,
      );
    } else if (bodyAreaLower.contains('arm') ||
               bodyAreaLower.contains('forearm') ||
               bodyAreaLower.contains('hand') ||
               bodyAreaLower.contains('elbow') ||
               bodyAreaLower.contains('wrist')) {
      return SvgIcon(
        assetName: 'arms',
        size: 20,
        color: _statusColor,
        fallbackIcon: Icons.back_hand_rounded,
      );
    } else if (bodyAreaLower.contains('torso') ||
               bodyAreaLower.contains('back') ||
               bodyAreaLower.contains('chest') ||
               bodyAreaLower.contains('shoulder') ||
               bodyAreaLower.contains('abdomen')) {
      return SvgIcon(
        assetName: 'torso',
        size: 20,
        color: _statusColor,
        fallbackIcon: Icons.airline_seat_flat_rounded,
      );
    } else if (bodyAreaLower.contains('leg') ||
               bodyAreaLower.contains('foot') ||
               bodyAreaLower.contains('knee') ||
               bodyAreaLower.contains('ankle') ||
               bodyAreaLower.contains('toe')) {
      return SvgIcon(
        assetName: 'legs',
        size: 20,
        color: _statusColor,
        fallbackIcon: Icons.directions_walk_rounded,
      );
    } else {
      // Fallback to original icon for unclear cases or condition-specific icons
      return Icon(log.icon, color: _statusColor, size: 20);
    }
  }

  void _showLogRowOptions(BuildContext context) {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(0, 0, 0, 0),
      items: const [
        PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: [
              Icon(Icons.share, size: 20),
              SizedBox(width: 8),
              Text('Share'),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 1,
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 2,
          child: Row(
            children: [
              Icon(Icons.close, size: 20),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
        PopupMenuItem<int>(
          value: 3,
          child: Row(
            children: [
              Icon(Icons.check_circle, size: 20),
              SizedBox(width: 8),
              Text('Mark as Reviewed'),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        onLongPress: () => _showLogRowOptions(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _statusColor.withValues(alpha: 0.08),
                  border: Border.all(color: _statusColor.withValues(alpha: 0.45), width: 1.4),
                ),
                child: _buildLogIcon(colors, log),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.condition,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: colors.textPrimary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${log.bodyArea} · ${_timeAgo(log.loggedAt)}',
                      style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(log.confidence * 100).round()}%',
                    style: TextStyle(fontSize: 10.5, color: colors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}