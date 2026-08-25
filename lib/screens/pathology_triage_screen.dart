import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/theme_provider.dart';
import '../theme/app_colors.dart';
import '../theme/button_styles.dart';
import '../theme/spacing.dart';
import '../models/body_area.dart';
import '../models/symptom.dart';
import '../widgets/score_hero_card.dart';
import '../widgets/animated_body_part_dropdown.dart';
import '../widgets/enhanced_loading.dart';
import '../widgets/symptom_chip.dart';
import '../utils/error_handler.dart';

/// Standalone triage flow reachable from the Home dashboard's "Pathology
/// Triage" quick link or the bottom nav's Triage tab. Steps: pick the
/// affected area, log symptoms, capture/upload a photo, then a mock
/// analysis pass produces a risk-tiered result — same shape as the
/// reference kit's assessment-to-score flow.
class PathologyTriageScreen extends StatefulWidget {
  final VoidCallback onViewClinics;
  final ValueChanged<bool> onTriageComplete; // true = high risk result
  final Uint8List? initialImage; // Optional initial image to skip capture step

  const PathologyTriageScreen({
    super.key,
    required this.onViewClinics,
    required this.onTriageComplete,
    this.initialImage,
  });

  @override
  State<PathologyTriageScreen> createState() => _PathologyTriageScreenState();
}

enum _TriageRisk { low, moderate, high }

class _PathologyTriageScreenState extends State<PathologyTriageScreen> {
  static const _totalSteps = 5; // area, symptoms, capture, preview, result (analyzing is transient)
  static const int _previewStepIndex = 3; // Index of preview step

  int _step = 0;
  bool _analyzing = false;
  String? _selectedAreaId;
  final Set<String> _selectedSymptomIds = {};
  _TriageRisk? _result;
  Uint8List? _capturedImage; // Store the captured/selected image
  double _rotationAngle = 0; // Rotation angle in degrees

  @override
  void initState() {
    super.initState();
    // If an initial image is provided, set it and jump to preview step
    if (widget.initialImage != null) {
      _capturedImage = widget.initialImage;
      _step = _previewStepIndex;
    }
  }

  void _goBack() {
    if (_step == 0) return;
    setState(() => _step -= 1);
  }

  void _selectArea(String? id) => setState(() => _selectedAreaId = id);

  void _toggleSymptom(String id) {
    setState(() {
      if (_selectedSymptomIds.contains(id)) {
        _selectedSymptomIds.remove(id);
      } else {
        _selectedSymptomIds.add(id);
      }
    });
  }

  Future<void> _takePhoto() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _capturedImage = bytes;
          _rotationAngle = 0;
          _step = _previewStepIndex; // Go to preview step
          _analyzing = false;
        });
      }
    } catch (e) {
      // In production, use proper logging framework
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getUserFriendlyErrorMessage(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _uploadPhoto() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _capturedImage = bytes;
          _rotationAngle = 0;
          _step = _previewStepIndex; // Go to preview step
          _analyzing = false;
        });
      }
    } catch (e) {
      // In production, use proper logging framework
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getUserFriendlyErrorMessage(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _rotateLeft() {
    setState(() {
      _rotationAngle = (_rotationAngle - 90) % 360;
    });
  }

  void _rotateRight() {
    setState(() {
      _rotationAngle = (_rotationAngle + 90) % 360;
    });
  }

  void _cropImage() {
  // TODO: Implement actual cropping logic using the crop package
  // For now, we'll show a message indicating this feature is planned
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image cropping feature coming soon'),
      ),
    );
  }
}

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _rotationAngle = 0;
      _step = 2; // Go back to capture step
    });
  }

  Future<void> _confirmPhoto() async {
    if (_capturedImage == null) return;

    setState(() {
      _step = 4; // Go to analyzing/result step
      _analyzing = true;
    });
    _runAnalysis();
  }

  /// Placeholder for the real inference call. Swap this for your actual
  /// model request — everything downstream just needs a _TriageRisk.
  Future<void> _runAnalysis() async {
    try {
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;

      final flagCount = _selectedSymptomIds.length;
      final hasSevereSigns = _selectedSymptomIds.contains('bumps') &&
          _selectedSymptomIds.contains('discoloration');

      final risk = hasSevereSigns || flagCount >= 5
          ? _TriageRisk.high
          : flagCount >= 2
              ? _TriageRisk.moderate
              : _TriageRisk.low;

      setState(() {
        _analyzing = false;
        _result = risk;
      });
      widget.onTriageComplete(risk == _TriageRisk.high);
    } catch (e) {
      debugPrint('Error during analysis: $e');
      if (mounted) {
        setState(() {
          _analyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to analyze image. Please try again with a clearer photo.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _startOver() {
    setState(() {
      _step = 0;
      _selectedAreaId = null;
      _selectedSymptomIds.clear();
      _result = null;
      _analyzing = false;
      _capturedImage = null;
      _rotationAngle = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    if (_analyzing) {
      return _AnalyzingView(colors: colors);
    }

    return SafeArea(
      child: Column(
        children: [
          _TriageHeader(
            colors: colors,
            step: _step,
            totalSteps: _totalSteps,
            onBack: _step > 0 && _result == null ? _goBack : null,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildStep(colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(AppColors colors) {
    if (_result != null) {
      return _ResultView(
        key: const ValueKey('result'),
        colors: colors,
        risk: _result!,
        area: BodyArea.all.firstWhere((a) => a.id == _selectedAreaId, orElse: () => BodyArea.all.first),
        symptomCount: _selectedSymptomIds.length,
        onViewClinics: widget.onViewClinics,
        onStartOver: _startOver,
      );
    }

    switch (_step) {
      case 0:
        return _AreaStep(
          key: const ValueKey('area'),
          colors: colors,
          selectedId: _selectedAreaId,
          onSelect: _selectArea,
          onContinue: _selectedAreaId != null ? () => setState(() => _step = 1) : null,
        );
      case 1:
        return _SymptomStep(
          key: const ValueKey('symptoms'),
          colors: colors,
          selectedIds: _selectedSymptomIds,
          onToggle: _toggleSymptom,
          onContinue: _selectedSymptomIds.isNotEmpty ? () => setState(() => _step = 2) : null,
        );
      case 2:
        return _CaptureStep(
          key: const ValueKey('capture'),
          colors: colors,
          onTakePhoto: _takePhoto,
          onUploadPhoto: _uploadPhoto,
        );
      case _previewStepIndex:
        return _PhotoPreviewStep(
          key: const ValueKey('preview'),
          colors: colors,
          image: _capturedImage!,
          rotationAngle: _rotationAngle,
          onRotateLeft: _rotateLeft,
          onRotateRight: _rotateRight,
          onCrop: _cropImage,
          onRetake: _retakePhoto,
          onConfirm: _confirmPhoto,
        );
      default:
        // This should never happen with proper step management, but just in case:
        debugPrint('Unexpected step value: $_step');
        return _AnalyzingView(colors: colors);
    }
  }
}

class _TriageHeader extends StatelessWidget {
  final AppColors colors;
  final int step;
  final int totalSteps;
  final VoidCallback? onBack;

  const _TriageHeader({
    required this.colors,
    required this.step,
    required this.totalSteps,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs / 2, AppSpacing.lg, AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: AppSpacing.lg * 2, // 40 = 20*2
                height: AppSpacing.lg * 2, // 40 = 20*2
                child: onBack == null
                    ? null
                    : IconButton(
                        onPressed: onBack,
                        icon: Icon(Icons.arrow_back_ios_new_rounded, size: AppSpacing.md, color: colors.textPrimary),
                      ),
              ),
              Expanded(
                child: Text(
                  'Pathology Triage',
                  textAlign: onBack == null ? TextAlign.left : TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colors.textPrimary),
                ),
              ),
              const SizedBox(width: AppSpacing.lg * 2),
            ],
          ),
          const SizedBox(height: AppSpacing.md - 2),
          Row(
            children: [
              for (int i = 0; i < totalSteps; i++) ...[
                Expanded(
                  child: Container(
                    height: AppSpacing.xs / 2,
                    decoration: BoxDecoration(
                      color: i <= step ? colors.accent : colors.border,
                      borderRadius: BorderRadius.circular(AppSpacing.xs / 2),
                    ),
                  ),
                ),
                if (i != totalSteps - 1) const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AreaStep extends StatelessWidget {
  final AppColors colors;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback? onContinue;

  const _AreaStep({
    super.key,
    required this.colors,
    required this.selectedId,
    required this.onSelect,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Where is the affected area?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Select the body area you want to assess',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            child: AnimatedBodyPartDropdown(
              value: selectedId,
              colors: colors,
              onChanged: (value) => onSelect(value ?? ''),
              bodyAreas: BodyArea.all,
            ),
          ),
        ),
        _ContinueBar(colors: colors, onContinue: onContinue),
      ],
    );
  }
}

class _SymptomStep extends StatelessWidget {
  final AppColors colors;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;
  final VoidCallback? onContinue;

  const _SymptomStep({
    super.key,
    required this.colors,
    required this.selectedIds,
    required this.onToggle,
    required this.onContinue,
  });

  String _getSymptomTooltip(String symptomId) {
    switch (symptomId) {
      case 'itching':
        return 'Persistent itching or irritation in the affected area';
      case 'redness':
        return 'Redness or inflammation of the skin';
      case 'flaking':
        return 'Flaking, scaling, or peeling of the skin';
      case 'bumps':
        return 'Raised bumps, lesions, or abnormal growths';
      case 'discoloration':
        return 'Changes in skin color or pigmentation';
      case 'swelling':
        return 'Swelling, puffiness, or fluid retention';
      case 'pain':
        return 'Pain, tenderness, or discomfort in the area';
      case 'oozing':
        return 'Fluid discharge, oozing, or crusting';
      case 'hairloss':
        return 'Hair thinning or loss in the affected area';
      default:
        return 'Symptom description not available';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What are you noticing?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Select all symptoms that apply',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final symptom in Symptom.all)
                  SymptomChip(
                    colors: colors,
                    label: symptom.label,
                    selected: selectedIds.contains(symptom.id),
                    onTap: () => onToggle(symptom.id),
                    tooltipMessage: _getSymptomTooltip(symptom.id),
                  ),
              ],
            ),
          ),
        ),
        _ContinueBar(colors: colors, onContinue: onContinue),
      ],
    );
  }
}

class _CaptureStep extends StatelessWidget {
  final AppColors colors;
  final VoidCallback onTakePhoto;
  final VoidCallback onUploadPhoto;

  const _CaptureStep({super.key, required this.colors, required this.onTakePhoto, required this.onUploadPhoto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a photo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'A clear, well-lit photo gives the most accurate assessment',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.border, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_search_rounded, size: MediaQuery.of(context).size.width * 0.07, color: colors.accent),
                  const SizedBox(height: 16),
                  Text(
                    'A clear, well-lit photo gives the most accurate assessment',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ensure good lighting, focus on the area of concern, and keep the camera steady',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _CaptureOptionButton(
            colors: colors,
            icon: Icons.camera_alt_rounded,
            label: 'Take Live Photo',
            filled: true,
            onTap: onTakePhoto,
          ),
          const SizedBox(height: 12),
          _CaptureOptionButton(
            colors: colors,
            icon: Icons.photo_library_rounded,
            label: 'Upload from Device Library',
            filled: false,
            onTap: onUploadPhoto,
          ),
        ],
      ),
    );
  }
}

class _PhotoPreviewStep extends StatelessWidget {
  final AppColors colors;
  final Uint8List image;
  final double rotationAngle;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onCrop;
  final VoidCallback onRetake;
  final VoidCallback onConfirm;

  const _PhotoPreviewStep({
    super.key,
    required this.colors,
    required this.image,
    required this.rotationAngle,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onCrop,
    required this.onRetake,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview Photo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Review and edit your photo before analysis',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.border, style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Transform.rotate(
                        angle: rotationAngle * (math.pi / 180),
                        child: Image.memory(
                          image,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _PreviewActionButton(
                        colors: colors,
                        icon: Icons.rotate_left,
                        label: 'Rotate Left',
                        onTap: onRotateLeft,
                      ),
                      _PreviewActionButton(
                        colors: colors,
                        icon: Icons.crop,
                        label: 'Crop',
                        onTap: onCrop,
                      ),
                      _PreviewActionButton(
                        colors: colors,
                        icon: Icons.rotate_right,
                        label: 'Rotate Right',
                        onTap: onRotateRight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _PreviewActionButton(
                        colors: colors,
                        icon: Icons.camera_alt,
                        label: 'Retake',
                        onTap: onRetake,
                      ),
                      _PreviewActionButton(
                        colors: colors,
                        icon: Icons.check_circle,
                        label: 'Confirm',
                        filled: true,
                        onTap: onConfirm,
                      ),
                    ],
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

class _PreviewActionButton extends StatelessWidget {
  final AppColors colors;
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _PreviewActionButton({
    required this.colors,
    required this.icon,
    required this.label,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? colors.accent : colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: filled ? null : Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: MediaQuery.of(context).size.width * 0.0667, color: filled ? Colors.white : colors.textPrimary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: filled ? Colors.white : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyzingView extends StatelessWidget {
  final AppColors colors;
  const _AnalyzingView({required this.colors});

  // Intentionally fixed regardless of light/dark theme — mirrors the
  // reference kit's dark "compiling" screen, which reads as a distinct
  // processing state rather than following the app's day/night mode.
  static const _bg = Color(0xFF0F172A);
  static const _fg = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 56,
                height: 56,
                child: EnhancedLoading(type: LoadingType.brandLogo, size: 56),
              ),
              const SizedBox(height: 24),
              const Text(
                'Analyzing your scan…',
                style: TextStyle(
                  color: _fg,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Please wait a moment',
                style: TextStyle(color: _fg.withValues(alpha: 0.6), fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final AppColors colors;
  final _TriageRisk risk;
  final BodyArea area;
  final int symptomCount;
  final VoidCallback onViewClinics;
  final VoidCallback onStartOver;

  const _ResultView({
    super.key,
    required this.colors,
    required this.risk,
    required this.area,
    required this.symptomCount,
    required this.onViewClinics,
    required this.onStartOver,
  });

  Color get _riskColor {
    switch (risk) {
      case _TriageRisk.low:
        return colors.success;
      case _TriageRisk.moderate:
        return colors.warning;
      case _TriageRisk.high:
        return colors.danger;
    }
  }

  String get _riskLabel {
    switch (risk) {
      case _TriageRisk.low:
        return 'Low Risk';
      case _TriageRisk.moderate:
        return 'Moderate Risk';
      case _TriageRisk.high:
        return 'High Risk';
    }
  }

  String get _riskMessage {
    switch (risk) {
      case _TriageRisk.low:
        return "This doesn't show signs of concern. We'll keep an eye on it in your Clinical Logs.";
      case _TriageRisk.moderate:
        return 'Worth monitoring closely. Consider a follow-up scan in a few days.';
      case _TriageRisk.high:
        return 'These signs warrant a professional opinion soon.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScoreHeroCard(
            colors: colors,
            overrideColor: _riskColor,
            statusLabel: _riskLabel,
            scoreValue: risk == _TriageRisk.low ? '92' : risk == _TriageRisk.moderate ? '61' : '28',
            scoreUnit: '/ 100',
            subtitle: '${area.label} · $symptomCount symptom${symptomCount == 1 ? '' : 's'} logged',
          ),
          const SizedBox(height: 18),
          Text(
            _riskMessage,
            style: TextStyle(fontSize: 13.5, color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          if (risk == _TriageRisk.high)
            ElevatedButton(
              onPressed: onViewClinics,
              style: elevatedButtonStyle(context, backgroundColor: colors.danger),
              child: const Text('Find Nearby Clinics', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          else
            ElevatedButton(
              onPressed: onStartOver,
              style: elevatedButtonStyle(context),
              child: const Text('Saved to Clinical Logs', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onStartOver,
            child: Text('Start a new triage', style: TextStyle(color: colors.textSecondary, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

class _CaptureOptionButton extends StatelessWidget {
  final AppColors colors;
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _CaptureOptionButton({
    required this.colors,
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? colors.accent : colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: filled ? null : Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: MediaQuery.of(context).size.width * 0.0667, color: filled ? Colors.white : colors.textPrimary),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueBar extends StatelessWidget {
  final AppColors colors;
  final VoidCallback? onContinue;

  const _ContinueBar({required this.colors, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onContinue,
          style: elevatedButtonStyle(context),
          child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}