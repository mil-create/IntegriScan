import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colors = themeProvider.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs - 4, AppSpacing.lg, AppSpacing.xs), // 4 = 8-4
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greetingForNow(),
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs - 6), // 2 = 8-6
                Text(
                  "Let's check your skin",
                  style: TextStyle(
                    fontSize: 21,
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          _ThemeToggle(themeProvider: themeProvider, colors: colors),
          const SizedBox(width: AppSpacing.sm),
          _Avatar(colors: colors),
        ],
      ),
    );
  }

  String _greetingForNow() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

class _ThemeToggle extends StatelessWidget {
  final ThemeProvider themeProvider;
  final AppColors colors;
  const _ThemeToggle({required this.themeProvider, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: true,
      label: themeProvider.isDarkMode ? 'Light mode' : 'Dark mode',
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: themeProvider.toggleTheme,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.accentSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(
            themeProvider.isDarkMode
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            color: colors.accent,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final AppColors colors;
  const _Avatar({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: true,
      label: 'User profile',
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [colors.accent, colors.accent.withValues(alpha: 0.6)],
          ),
          border: Border.all(color: colors.surface, width: 2),
        ),
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
      ),
    );
  }
}
