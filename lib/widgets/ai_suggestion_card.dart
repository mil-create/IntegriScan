import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';
import '../models/display_item.dart';

/// Card containing a short list of AI-generated suggestions, each shown
/// as a slim accent bar + bare icon + title/detail — an editorial "feed"
/// treatment, deliberately distinct from the boxed-icon badges used for
/// navigation elements elsewhere in the app.
class AiSuggestionCard extends StatelessWidget {
  final AppColors colors;
  final String title;
  final List<DisplayItem> suggestions;

  const AiSuggestionCard({
    super.key,
    required this.colors,
    required this.title,
    required this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              Icon(Icons.auto_awesome_rounded, size: 16, color: colors.accent),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (int i = 0; i < suggestions.length; i++) ...[
            _SuggestionRow(colors: colors, suggestion: suggestions[i]),
            if (i != suggestions.length - 1) ...[
              const SizedBox(height: AppSpacing.sm),
              Divider(height: 1, color: colors.border),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final AppColors colors;
  final DisplayItem suggestion;

  const _SuggestionRow({required this.colors, required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A slim accent bar instead of a boxed icon — reads as "one
        // entry in a feed" rather than another app-icon-style badge.
        Container(
          width: AppSpacing.xs / 6, // 1.33 ≈ 8/6
          height: AppSpacing.sm + 10, // 22 = 12+10
          margin: const EdgeInsets.only(top: AppSpacing.xs / 4), // 2 = 8/4
          decoration: BoxDecoration(
            color: suggestion.tint,
            borderRadius: BorderRadius.circular(AppSpacing.xs / 4), // 2 = 8/4
          ),
        ),
        const SizedBox(width: AppSpacing.xs / 1.6), // 5 ≈ 8/1.6
        Icon(suggestion.icon, color: suggestion.tint, size: AppSpacing.sm * 1.5), // 18 = 12*1.5
        const SizedBox(width: AppSpacing.xs / 1.6), // 5 ≈ 8/1.6
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                suggestion.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs / 2), // 4 = 8/2
              Text(
                suggestion.subtitle,
                style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
