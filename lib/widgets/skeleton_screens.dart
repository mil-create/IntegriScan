import 'package:flutter/material.dart';

/// Skeleton screen widgets for content loading placeholders
class SkeletonScreen extends StatelessWidget {
  const SkeletonScreen({
    super.key,
    required this.type,
    this.height,
    this.width = double.infinity,
    this.radius = 8.0,
    this.margin,
  });

  final SkeletonType type;
  final double? height;
  final double width;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    Widget child;
    switch (type) {
      case SkeletonType.text:
        child = Container(
          height: height ?? 16,
          width: width * 0.8,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(radius),
          ),
        );
        break;
      case SkeletonType.title:
        child = Container(
          height: height ?? 24,
          width: width * 0.7,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(radius),
          ),
        );
        break;
      case SkeletonType.avatar:
        child = Container(
          height: height ?? 40,
          width: height ?? 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: baseColor,
          ),
        );
        break;
      case SkeletonType.icon:
        child = Container(
          height: height ?? 24,
          width: height ?? 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: baseColor,
          ),
        );
        break;
      case SkeletonType.button:
        child = Container(
          height: height ?? 36,
          width: width,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(radius),
          ),
        );
        break;
      case SkeletonType.image:
        child = Container(
          height: height ?? 120,
          width: width,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(radius),
          ),
        );
        break;
      case SkeletonType.logEntry:
        child = _buildLogEntrySkeleton(baseColor, highlightColor, radius, context);
        break;
      case SkeletonType.calendar:
        child = _buildCalendarSkeleton(baseColor, highlightColor, radius, context);
        break;
    }

    return margin != null
        ? Container(margin: margin, child: child)
        : child;
  }

  Widget _buildLogEntrySkeleton(
      Color baseColor, Color highlightColor, double radius, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: baseColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: double.infinity * 0.7,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              height: 16,
              width: 36,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSkeleton(
      Color baseColor, Color highlightColor, double radius, BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Calendar header skeleton
            Container(
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 16,
                    width: 60,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    height: 16,
                    width: 60,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            // Weekdays skeleton
            Container(
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                itemBuilder: (context, index) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 24,
                  height: 20,
                  decoration: BoxDecoration(
                    color: baseColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            // Calendar grid skeleton
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: 28,
                itemBuilder: (context, index) => Container(
                  decoration: BoxDecoration(
                    color: baseColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum SkeletonType {
  text,
  title,
  avatar,
  icon,
  button,
  image,
  logEntry,
  calendar,
}

/// Shimmer effect for skeleton screens
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.color = Colors.grey,
  });

  final Widget child;
  final Duration duration;
  final Color color;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value;
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.color.withValues(alpha: 0.1),
                widget.color.withValues(alpha: 0.3),
                widget.color.withValues(alpha: 0.1),
              ],
              stops: [
                value - 0.3,
                value,
                value + 0.3,
              ],
              tileMode: TileMode.clamp,
            ).createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            );
          },
          blendMode: BlendMode.srcIn,
          child: child,
        );
      },
    );
  }
}

/// Wrapper that combines skeleton with shimmer effect
class ShimmerSkeleton extends StatelessWidget {
  const ShimmerSkeleton({
    super.key,
    required this.type,
    this.height,
    this.width = double.infinity,
    this.radius = 8.0,
    this.margin,
  });

  final SkeletonType type;
  final double? height;
  final double width;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SkeletonScreen(
        type: type,
        height: height,
        width: width,
        radius: radius,
        margin: margin,
      ),
    );
  }
}