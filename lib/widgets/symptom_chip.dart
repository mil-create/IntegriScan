import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A selectable chip for symptom selection with enhanced visual feedback
class SymptomChip extends StatelessWidget {
  final AppColors colors;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? tooltipMessage; // Optional tooltip for symptom description

  const SymptomChip({
    super.key,
    required this.colors,
    required this.label,
    required this.selected,
    required this.onTap,
    this.tooltipMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltipMessage ?? label,
      child: Material(
        color: selected ? colors.accent : colors.surface,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: selected ? colors.accent : colors.border,
                width: selected ? 2.0 : 1.0,
              ),
              // Add subtle elevation for better distinction when selected
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: colors.accent.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : colors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}