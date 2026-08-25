import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Standardized border radius values for buttons
class ButtonRadius {
  ButtonRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
}

/// Standardized height values for buttons
class ButtonHeight {
  ButtonHeight._();

  static const double sm = 32.0;
  static const double md = 40.0;
  static const double lg = 48.0;
  static const double xl = 56.0;
}

/// Standardized padding values for buttons
class ButtonPadding {
  ButtonPadding._();

  static const EdgeInsets sm = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  static const EdgeInsets md = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const EdgeInsets lg = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  static const EdgeInsets xl = EdgeInsets.symmetric(horizontal: 24, vertical: 20);
}

/// Standardized elevation values for ElevatedButton
class ButtonElevation {
  ButtonElevation._();

  static const double sm = 1.0;
  static const double md = 2.0;
  static const double lg = 4.0;
  static const double xl = 6.0;
}

/// Creates a standardized ElevatedButton style
ButtonStyle elevatedButtonStyle(
  BuildContext context, {
  Color? backgroundColor,
  double radius = ButtonRadius.md,
  double elevation = ButtonElevation.md,
}) {
  final colors = Theme.of(context).extension<AppColors>()!;
  final Color effectiveBgColor = backgroundColor ?? colors.accent;

  return ElevatedButton.styleFrom(
    backgroundColor: effectiveBgColor,
    foregroundColor: Colors.white,
    disabledBackgroundColor: effectiveBgColor.withValues(alpha: 0.5),
    disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    ),
    elevation: elevation,
    padding: ButtonPadding.lg,
    minimumSize: const Size.fromHeight(ButtonHeight.lg),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
    ),
  );
}

/// Creates a standardized OutlinedButton style
ButtonStyle outlinedButtonStyle(
  BuildContext context, {
  Color? foregroundColor,
  double radius = ButtonRadius.md,
}) {
  final colors = Theme.of(context).extension<AppColors>()!;
  final Color effectiveFgColor = foregroundColor ?? colors.accent;

  return OutlinedButton.styleFrom(
    foregroundColor: effectiveFgColor,
    side: BorderSide(
      color: effectiveFgColor,
      width: 2,
    ),
    disabledForegroundColor: effectiveFgColor.withValues(alpha: 0.5),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    ),
    padding: ButtonPadding.lg,
    minimumSize: const Size.fromHeight(ButtonHeight.lg),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );
}

/// Creates a standardized TextButton style
ButtonStyle textButtonStyle(
  BuildContext context, {
  Color? foregroundColor,
}) {
  final colors = Theme.of(context).extension<AppColors>()!;
  final Color effectiveFgColor = foregroundColor ?? colors.accent;

  return TextButton.styleFrom(
    foregroundColor: effectiveFgColor,
    disabledForegroundColor: effectiveFgColor.withValues(alpha: 0.5),
    padding: ButtonPadding.md,
    minimumSize: const Size.fromHeight(ButtonHeight.md),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );
}