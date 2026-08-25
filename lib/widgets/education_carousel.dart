import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_colors.dart';
import '../theme/spacing.dart';
import '../models/education_topic.dart';

class EducationCarousel extends StatefulWidget {
  const EducationCarousel({super.key});

  @override
  State<EducationCarousel> createState() => _EducationCarouselState();
}

class _EducationCarouselState extends State<EducationCarousel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _animations;

  static const List<EducationTopic> _topics = [
    EducationTopic(
      title: 'Acne Vulgaris',
      subtitle: 'Causes, triggers & care',
      icon: Icons.face_retouching_natural_rounded,
      tint: Color(0xFF0D9488),
    ),
    EducationTopic(
      title: 'Melanoma Skin Cancer',
      subtitle: 'Know the ABCDE signs',
      icon: Icons.warning_amber_rounded,
      tint: Color(0xFFDC2626),
    ),
    EducationTopic(
      title: 'Eczema (Dermatitis)',
      subtitle: 'Manage flare-ups',
      icon: Icons.water_drop_outlined,
      tint: Color(0xFF2563EB),
    ),
    EducationTopic(
      title: 'Psoriasis',
      subtitle: 'Understand the cycle',
      icon: Icons.grain_rounded,
      tint: Color(0xFF9333EA),
    ),
    EducationTopic(
      title: 'Scalp Dermatitis',
      subtitle: 'Flaking & itch relief',
      icon: Icons.spa_outlined,
      tint: Color(0xFFD97706),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Create staggered animations for each card
    _animations = List.generate(
      _topics.length,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.1, // Stagger each animation by 100ms
            min(index * 0.1 + 0.2, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Learn About Conditions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: colors.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: _topics.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) =>
                  _EducationCard(topic: _topics[index], colors: colors, animation: _animations[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationCard extends StatelessWidget {
  final EducationTopic topic;
  final AppColors colors;
  final Animation<double> animation;

  const _EducationCard({
    required this.topic,
    required this.colors,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1.0 - animation.value)),
          child: child,
        ),
      ),
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.lg * 1.375), // 22 ≈ 16*1.375
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppSpacing.md * 2.5, // 40 = 16*2.5
              height: AppSpacing.md * 2.5, // 40 = 16*2.5
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: topic.tint.withValues(alpha: 0.08),
                border: Border.all(color: topic.tint.withValues(alpha: 0.4), width: AppSpacing.xs - 6), // 1.4 ≈ 2-0.6
              ),
              child: Icon(topic.icon, color: topic.tint, size: AppSpacing.lg),
            ),
            const Spacer(),
            Text(
              topic.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs - 4), // 4
            Text(
              topic.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}