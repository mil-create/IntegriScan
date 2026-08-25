import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_colors.dart';
import '../theme/button_styles.dart';
import '../theme/spacing.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/metrics_banner.dart';
import '../widgets/education_carousel.dart';
import '../widgets/high_risk_banner.dart';
import '../widgets/score_hero_card.dart';
import '../widgets/ai_suggestion_card.dart';
import '../widgets/quick_link_tile.dart';
import '../widgets/skin_fact_card.dart';

class HomeScreen extends StatelessWidget {
  final bool highRiskFlag;
  final VoidCallback onDismissRiskBanner;
  final VoidCallback onViewClinics;
  final VoidCallback onSimulateHighRisk;
  final VoidCallback onOpenTriage;
  final VoidCallback onOpenLogs;

  const HomeScreen({
    super.key,
    required this.highRiskFlag,
    required this.onDismissRiskBanner,
    required this.onViewClinics,
    required this.onSimulateHighRisk,
    required this.onOpenTriage,
    required this.onOpenLogs,
  });

  static const _weeklyActivity = [0.3, 0.5, 0.2, 0.8, 0.6, 0.9, 0.4];
  static const _weeklyLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _scoreTrend = [0.62, 0.68, 0.7, 0.66, 0.74, 0.8, 0.83, 0.88];

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.xl * 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DashboardHeader(),

          // Auto-shown whenever the AI pipeline flags a high-risk scan.
          if (highRiskFlag)
            HighRiskBanner(
              colors: colors,
              onViewClinics: onViewClinics,
              onDismiss: onDismissRiskBanner,
            ),

          // Hero "Skin Health Score" card — the at-a-glance headline
          // metric, mirroring the reference kit's Asklepios Score card.
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: ScoreHeroCard(
              colors: colors,
              statusLabel: 'Skin Health · Normal',
              scoreValue: '88',
              subtitle: 'Your scalp and skin are trending healthy this week',
              trend: _scoreTrend,
              onTap: onOpenLogs,
            ),
          ),

          const MetricsBanner(),

          // Skin & Scalp Fact of the Day
          const SkinFactCard(),

          // Weekly scan activity — small bar chart, same rhythm as the
          // reference kit's "Blood Pressure Stats" card.
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm + 4), // 16 = 12+4, keeping 18 would be sm + 6
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Weekly Scan Activity',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        '3 this week',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: colors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _WeeklyBars(colors: colors, values: _weeklyActivity, labels: _weeklyLabels),
                ],
              ),
            ),
          ),

          // Quick links to the two pivoted sections + the AI chatbot.
          Container(
            margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.lg),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: AppSpacing.sm,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryQuickLinkTile(
                  colors: colors,
                  icon: Icons.health_and_safety_rounded,
                  tint: colors.accent,
                  title: 'Pathology Triage',
                  subtitle: 'Answer a few questions to assess a spot',
                  onTap: onOpenTriage,
                ),
                const SizedBox(height: AppSpacing.lg),
                QuickLinkTile(
                  colors: colors,
                  icon: Icons.receipt_long_rounded,
                  tint: colors.warning,
                  title: 'Clinical Logs',
                  subtitle: '6 logged entries · last updated yesterday',
                  onTap: onOpenLogs,
                ),
                const SizedBox(height: AppSpacing.lg),
                QuickLinkTile(
                  colors: colors,
                  icon: Icons.smart_toy_outlined,
                  tint: const Color(0xFF6366F1),
                  title: 'Skin AI Chatbot',
                  subtitle: 'Ask about a symptom or treatment',
                  trailingBadge: 'New',
                  onTap: () => _showChatbotComingSoon(context, colors),
                ),
              ],
            ),
          ),

          // AI suggestions feed.
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: AiSuggestionCard(
              colors: colors,
              title: 'AI Suggestions',
              suggestions: [
                AiSuggestion(
                  title: 'Switch to a fragrance-free moisturizer',
                  subtitle: 'Based on the redness pattern on your left forearm',
                  icon: Icons.water_drop_outlined,
                  tint: colors.accent,
                ),
                AiSuggestion(
                  title: 'Apply SPF 30+ before midday sun exposure',
                  subtitle: 'Your scalp scan showed early UV sensitivity',
                  icon: Icons.wb_sunny_outlined,
                  tint: colors.warning,
                ),
                const AiSuggestion(
                  title: 'Re-scan your neck area in 5 days',
                  subtitle: 'To confirm the flaking has resolved',
                  icon: Icons.replay_rounded,
                  tint: Color(0xFF6366F1),
                ),
              ],
            ),
          ),

          const EducationCarousel(),
          const SizedBox(height: AppSpacing.xl),

          // Demo-only trigger so you can see the high-risk banner flow
          // without wiring up a real inference pipeline yet.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TextButton(
              onPressed: onSimulateHighRisk,
              style: textButtonStyle(context, foregroundColor: colors.textSecondary),
              child: const Text(
                'Simulate high-risk AI result (demo)',
                style: TextStyle(fontSize: 11.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChatbotComingSoon(BuildContext context, AppColors colors) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Skin AI Chatbot is coming soon.'),
        backgroundColor: colors.textPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  final AppColors colors;
  final List<double> values;
  final List<String> labels;

  const _WeeklyBars({required this.colors, required this.values, required this.labels});

  @override
  Widget build(BuildContext context) {
    // Highlight today (Saturday in this sample dataset, index 5).
    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 56,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: values[i].clamp(0.05, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: i == 5 ? colors.accent : colors.accentSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: i == 5 ? FontWeight.w700 : FontWeight.w500,
                        color: i == 5 ? colors.accent : colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
