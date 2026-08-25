import 'package:flutter/material.dart';

/// Enhanced loading animations to replace basic CircularProgressIndicator
class EnhancedLoading extends StatelessWidget {
  const EnhancedLoading({
    super.key,
    required this.type,
    this.color,
    this.size = 40.0,
  });

  final LoadingType type;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    // For pulse and waterRipple loading, use accent color to ensure it's orange
    final effectiveColor =
        type == LoadingType.pulse || type == LoadingType.waterRipple
            ? (color ?? const Color(0xFFD97757))
            : (color ?? Theme.of(context).colorScheme.primary);

    // Check if animations are disabled
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    switch (type) {
      case LoadingType.pulse:
        return disableAnimations
            ? _StaticPulseIndicator(
                color: effectiveColor, size: size)
            : PulseLoadingIndicator(
                color: effectiveColor, size: size);
      case LoadingType.rotatingDots:
        return disableAnimations
            ? _StaticRotatingDotsIndicator(
                color: effectiveColor, size: size)
            : RotatingDotsLoadingIndicator(
                color: effectiveColor, size: size);
      case LoadingType.brandLogo:
        return disableAnimations
            ? _StaticBrandLogoIndicator(
                color: effectiveColor, size: size)
            : BrandLogoLoading(
                color: effectiveColor, size: size);
      case LoadingType.waterRipple:
        return disableAnimations
            ? _StaticWaterRippleIndicator(
                color: effectiveColor, size: size)
            : WaterRippleLoadingIndicator(
                color: effectiveColor, size: size);
      case LoadingType.circular:
        return CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
          strokeWidth: 2.5,
        );
    }
  }
}

enum LoadingType {
  pulse,
  rotatingDots,
  brandLogo,
  circular,
  waterRipple,
}

/// Static version of PulseLoadingIndicator when animations are disabled
class _StaticPulseIndicator extends StatelessWidget {
  const _StaticPulseIndicator({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Midpoint values: scale 1.0, opacity 0.5
    return Transform.scale(
      scale: 1.0,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Static version of RotatingDotsLoadingIndicator when animations are disabled
class _StaticRotatingDotsIndicator extends StatelessWidget {
  const _StaticRotatingDotsIndicator({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.0),
            width: 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(
                alpha: 0.2 + (index * 0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Static version of BrandLogoLoading when animations are disabled
class _StaticBrandLogoIndicator extends StatelessWidget {
  const _StaticBrandLogoIndicator({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Show the final state: dot full opacity, text fully visible
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated dot (now static at full opacity)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          // Text that appears to be drawing (now fully visible)
          SizedBox(
            width: size * 0.8,
            child: Text(
              'IntegriScan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Enhanced pulse loading indicator - more noticeable pulsating effect
class PulseLoadingIndicator extends StatefulWidget {
  const PulseLoadingIndicator({
    super.key,
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  State<PulseLoadingIndicator> createState() => _PulseLoadingIndicatorState();
}

class _PulseLoadingIndicatorState extends State<PulseLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800), // Modern quick pulse
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.2, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = _scaleAnimation.value;
        final opacity = _opacityAnimation.value;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: opacity),
            ),
          ),
        );
      },
    );
  }
}

/// Rotating dots loading indicator
class RotatingDotsLoadingIndicator extends StatefulWidget {
  const RotatingDotsLoadingIndicator({
    super.key,
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  State<RotatingDotsLoadingIndicator> createState() =>
      _RotatingDotsLoadingIndicatorState();
}

class _RotatingDotsLoadingIndicatorState
    extends State<RotatingDotsLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
    _controller.repeat();
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
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Transform.rotate(
            angle: value * 2 * 3.14159,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.0),
                  width: 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(
                      alpha: 0.2 + (index * 0.3),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Brand logo loading - animates the app name or logo
class BrandLogoLoading extends StatefulWidget {
  const BrandLogoLoading({
    super.key,
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  State<BrandLogoLoading> createState() => _BrandLogoLoadingState();
}

class _BrandLogoLoadingState extends State<BrandLogoLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
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
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.3 + value * 0.7),
                ),
              ),
              const SizedBox(height: 4),
              // Text that appears to be drawing
              SizedBox(
                width: widget.size * 0.8,
                child: Stack(
                  children: [
                    Text(
                      'IntegriScan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: widget.color.withValues(alpha: 0.2),
                      ),
                    ),
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        child: Text(
                          'IntegriScan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: widget.color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Static version of WaterRippleLoadingIndicator when animations are disabled
class _StaticWaterRippleIndicator extends StatelessWidget {
  const _StaticWaterRippleIndicator({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Show a simple dot at center when animations are disabled
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Water ripple loading indicator - simulates a drop hitting water with ripple effect
class WaterRippleLoadingIndicator extends StatefulWidget {
  const WaterRippleLoadingIndicator({
    super.key,
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  State<WaterRippleLoadingIndicator> createState() =>
      _WaterRippleLoadingIndicatorState();
}

class _WaterRippleLoadingIndicatorState
    extends State<WaterRippleLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = _scaleAnimation.value;
        final opacity = _opacityAnimation.value;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: opacity),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}