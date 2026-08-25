import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';

/// Modern clinic locator module. This is pushed automatically whenever
/// the AI pipeline flags a high-risk scan (see HighRiskBanner), or can
/// be reached manually from the Discover tab in a full build-out.
class ClinicLocatorScreen extends StatelessWidget {
  const ClinicLocatorScreen({super.key});

  static const _clinics = [
    {'name': 'Skinova Dermatology Center', 'distance': '1.2 km', 'rating': '4.8'},
    {'name': 'DermaCare Specialist Clinic', 'distance': '2.4 km', 'rating': '4.6'},
    {'name': 'City General — Dermatology Wing', 'distance': '3.1 km', 'rating': '4.5'},
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          'Nearby Clinics',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Stylized map placeholder. Swap this container for a real
          // google_maps_flutter / apple_maps_flutter widget in
          // production, fed with clinic coordinates from your backend.
          Container(
            margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xs / 2, AppSpacing.lg, AppSpacing.md),
            height: 220,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.xl),
              border: Border.all(color: colors.border),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _MapGridPainter(colors.border)),
                ),
                Icon(Icons.location_on_rounded, color: colors.accent, size: 40),
                Positioned(
                  top: 40,
                  left: 60,
                  child: Icon(Icons.local_hospital_rounded, color: colors.danger, size: 22),
                ),
                Positioned(
                  bottom: 50,
                  right: 50,
                  child: Icon(Icons.local_hospital_rounded, color: colors.danger, size: 22),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: _clinics.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _ClinicTile(clinic: _clinics[index], colors: colors),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  final Color lineColor;
  _MapGridPainter(this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ClinicTile extends StatelessWidget {
  final Map<String, String> clinic;
  final AppColors colors;
  const _ClinicTile({required this.clinic, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.lg - 2),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: AppSpacing.md * 2.875, // 46 ≈ 16*2.875
            height: AppSpacing.md * 2.875, // 46 ≈ 16*2.875
            decoration: BoxDecoration(
              color: colors.accentSoft,
              borderRadius: BorderRadius.circular(AppSpacing.md - 2),
            ),
            child: Icon(Icons.local_hospital_rounded, color: colors.accent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clinic['name']!,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs / 2),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: AppSpacing.sm + 2, color: colors.warning),
                    Text(
                      ' ${clinic['rating']}  ·  ${clinic['distance']} away',
                      style: TextStyle(fontSize: 11.5, color: colors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
        ],
      ),
    );
  }
}
