import 'package:flutter/material.dart';

/// Smooth filled line chart — used for the hero score card and the
/// clinical log detail trend, mirroring the wave-style charts in the
/// reference kit (Heart Rate / Weight cards).
class SparklineChart extends StatelessWidget {
  final List<double> values; // expected roughly 0.0 - 1.0, but any range works
  final Color lineColor;
  final Color fillColor;
  final double strokeWidth;

  const SparklineChart({
    super.key,
    required this.values,
    required this.lineColor,
    required this.fillColor,
    this.strokeWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(
        values: values,
        lineColor: lineColor,
        fillColor: fillColor,
        strokeWidth: strokeWidth,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final Color fillColor;
  final double strokeWidth;

  _SparklinePainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);

    final dx = size.width / (values.length - 1);
    final points = <Offset>[
      for (int i = 0; i < values.length; i++)
        Offset(
          i * dx,
          size.height - ((values[i] - minV) / range) * size.height * 0.85 - size.height * 0.05,
        ),
    ];

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final mid = Offset((current.dx + next.dx) / 2, (current.dy + next.dy) / 2);
      linePath.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }
    linePath.lineTo(points.last.dx, points.last.dy);

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [fillColor.withValues(alpha: 0.35), fillColor.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(points.last, strokeWidth + 1.5, Paint()..color = lineColor);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.lineColor != lineColor;
}

/// Small rounded bar chart — used for weekly-activity style summaries.
class MiniBarChart extends StatelessWidget {
  final List<double> values; // 0.0 - 1.0
  final List<String> labels;
  final Color barColor;
  final Color trackColor;
  final int highlightIndex;

  const MiniBarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.barColor,
    required this.trackColor,
    this.highlightIndex = -1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
                            color: i == highlightIndex ? barColor : trackColor,
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
                      fontSize: 9.5,
                      fontWeight: i == highlightIndex ? FontWeight.w700 : FontWeight.w500,
                      color: i == highlightIndex ? barColor : trackColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
