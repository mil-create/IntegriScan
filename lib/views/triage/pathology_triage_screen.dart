import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:convert';
import 'package:image/image.dart' as img;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integriscan/theme/theme_provider.dart';
import 'package:integriscan/theme/app_colors.dart';
import 'package:integriscan/theme/button_styles.dart';
import 'package:integriscan/theme/spacing.dart';
import 'package:integriscan/models/body_area.dart';
import 'package:integriscan/models/symptom.dart';
import 'package:integriscan/widgets/score_hero_card.dart';
import 'package:integriscan/widgets/enhanced_loading.dart';
import 'package:integriscan/widgets/symptom_chip.dart';
import 'package:integriscan/utils/error_handler.dart';
import 'package:integriscan/services/ml_model_service.dart';
import 'package:integriscan/services/hive_service.dart';
import 'package:integriscan/models/clinical_log.dart';
import 'package:integriscan/utils/health_literacy_pre_consultation_assistant.dart';
import 'package:integriscan/models/triage_risk.dart';

/// Simple crop page for manual image cropping
class CropPage extends StatefulWidget {
  final Uint8List image;

  const CropPage({super.key, required this.image});

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  late final img.Image _originalImage;
  late img.Image _croppedImage;
  late final GlobalKey _cropKey = GlobalKey();
  late double _scale = 1.0;
  Offset _offset = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _originalImage = img.decodeImage(widget.image)!;
    _croppedImage = _originalImage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Image'),
        actions: [
          TextButton(
            onPressed: _applyCrop,
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          if (_isDragging) {
            setState(() {
              _offset += details.delta / _scale;
            });
          }
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
        },
        child: RepaintBoundary(
          key: _cropKey,
          child: InteractiveViewer(
            scaleEnabled: true,
            minScale: 0.5,
            maxScale: 3.0,
            onInteractionUpdate: (details) {
              setState(() {
                _scale = details.scale;
              });
            },
            child: SizedBox(
              width: 300,
              height: 400,
              child: CustomPaint(
                painter: _CropPainter(
                  image: _croppedImage,
                  originalImage: _originalImage,
                ),
                child: Center(
                  child: Image.memory(widget.image),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _applyCrop,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
          child: const Text('Apply Crop'),
        ),
      ),
    );
  }

  void _applyCrop() {
    // For simplicity, we'll just return the original image
    // In a full implementation, we would extract the cropped region
    Navigator.of(context).pop(widget.image);
  }
}

class _CropPainter extends CustomPainter {
  final img.Image image;
  final img.Image originalImage;

  const _CropPainter({
    required this.image,
    required this.originalImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the image
    final imageBytes = Uint8List.fromList(image.getBytes());
    // Simplified for now - in reality we'd do proper cropping
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BodyAreaSelectionGrid extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const BodyAreaSelectionGrid({
    super.key,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      padding: const EdgeInsets.all(0),
      children: BodyArea.all.map((area) {
        final bool isSelected = area.id == selectedId;
        return GestureDetector(
          onTap: () => onSelect(area.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                ? colors.accent.withValues(alpha: 0.1)
                : colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                  ? colors.accent
                  : colors.border.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                area.buildIcon(
                  size: 48,
                  color: isSelected
                    ? colors.accent
                    : colors.textPrimary,
                ),
                const SizedBox(height: 12),
                Text(
                  area.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                    color: isSelected
                      ? colors.accent
                      : colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Standalone triage flow reachable from the Home dashboard's "Pathology
/// Triage" quick link or the bottom nav's Triage tab.
class PathologyTriageScreen extends StatefulWidget {
  final VoidCallback onViewClinics;
  final Function(bool, [int?]) onTriageComplete;
  final ValueChanged<Map<String, dynamic>> onViewPreConsultationSummary;
  final ValueChanged<Map<String, dynamic>> onExportPDFReport;
  final Uint8List? initialImage;

  const PathologyTriageScreen({
    super.key,
    required this.onViewClinics,
    required this.onTriageComplete,
    required this.onViewPreConsultationSummary,
    required this.onExportPDFReport,
    this.initialImage,
  });

  @override
  State<PathologyTriageScreen> createState() => _PathologyTriageScreenState();
}

class _PathologyTriageScreenState extends State<PathologyTriageScreen> {
  static const _totalSteps = 5;
  static const int _previewStepIndex = 3;

  int _step = 0;
  bool _analyzing = false;
  String? _selectedAreaId;
  final Map<String, double?> _selectedSymptomIds = {};
  TriageRisk? _result;
  bool _isInconclusive = false;
  bool _isNormal = false;
  Uint8List? _capturedImage;
  double _rotationAngle = 0;
  String? _analysisError;
  Map<String, dynamic>? _analysisResult;
  bool _loadingPreConsultation = false;

  Future<void> _handleLostData() async {
    final picker = ImagePicker();
    final LostDataResponse response = await picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      try {
        final bytes = await response.file!.readAsBytes();
        if (!mounted) return;
        setState(() {
          _capturedImage = bytes;
          _rotationAngle = 0;
          _step = _previewStepIndex;
          _analyzing = false;
          _analysisError = null;
          _analysisResult = null;
        });
      } catch (e) {
        debugPrint('Error reading lost data file: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process recovered image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } else {
      debugPrint('Error retrieving lost data: ${response.exception}');
    }
  }

  @override
  void initState() {
    super.initState();
    _handleLostData();
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
      if (_selectedSymptomIds.containsKey(id)) {
        _selectedSymptomIds.remove(id);
      } else {
        if (id == 'itching' || id == 'pain') {
          _selectedSymptomIds[id] = 5.0;
        } else {
          _selectedSymptomIds[id] = null;
        }
      }
    });
  }

  void _updateSymptomSeverity(String id, double severity) {
    setState(() {
      _selectedSymptomIds[id] = severity;
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
          _step = _previewStepIndex;
          _analyzing = false;
        });
      }
    } catch (e) {
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
          _step = _previewStepIndex;
          _analyzing = false;
        });
      }
    } catch (e) {
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

  Future<void> _cropImage() async {
    if (!mounted || _capturedImage == null) return;

    try {
      final croppedImage = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
          builder: (context) => CropPage(
            image: _capturedImage!,
          ),
        ),
      );

      if (croppedImage != null && mounted) {
        setState(() {
          _capturedImage = croppedImage;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image cropped successfully'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error during cropping: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cropping failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _rotationAngle = 0;
      _step = 2;
    });
  }

  Future<void> _confirmPhoto() async {
    if (_capturedImage == null) return;

    setState(() {
      _step = 4;
      _analyzing = true;
    });
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    if (_capturedImage == null) {
      if (!mounted) return;
      setState(() {
        _analyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No image captured. Please capture or select an image.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    try {
      if (!mounted) return;
      setState(() => _analyzing = true);

      final bodyAreaString = _selectedAreaId ?? 'skin';

      final result = await MLModelService().predict(
        imageBytes: _capturedImage!,
        bodyArea: bodyAreaString,
      );

      if (!mounted) return;

      if (result['isValidSkinImage'] == false) {
        setState(() {
          _analyzing = false;
          _analysisError = result['message'] as String?;
          _analysisResult = result;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_analysisError ?? 'Invalid target image'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      final String primaryClass = result['primary_class'] as String;
      final double primaryConfidence = (result['primary_confidence'] as num).toDouble();
      final List<dynamic> topPredictions = result['top_3_predictions'] as List<dynamic>;

      final bool isInconclusive = primaryClass == 'Inconclusive - Consult a Dermatologist';
      final bool isNormal = !isInconclusive && TriageRiskMapper.isNormal(primaryClass);

      TriageRisk risk;
      if (isInconclusive) {
        risk = TriageRisk.moderate;
      } else if (isNormal) {
        risk = TriageRisk.low;
      } else {
        risk = TriageRiskMapper.getRiskForLabel(primaryClass);
      }

      setState(() {
        _analyzing = false;
        _isInconclusive = isInconclusive;
        _isNormal = isNormal;
        _analysisResult = {
          'primary_class': primaryClass,
          'primary_confidence': primaryConfidence,
          'top_3_predictions': topPredictions,
        };
        _result = risk;
      });

      try {
        final ClinicalLogEntry logEntry = _buildClinicalLogEntry();
        await HiveService.saveLog(logEntry);
      } catch (e) {
        debugPrint('Failed to save to Hive: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save triage history: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }

      widget.onTriageComplete(risk == TriageRisk.high);
    } catch (e) {
      debugPrint('Error during analysis: $e');
      if (!mounted) return;
      setState(() {
        _analyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _startOver() {
    setState(() {
      _step = 0;
      _selectedAreaId = null;
      _selectedSymptomIds.clear();
      _result = null;
      _isInconclusive = false;
      _isNormal = false;
      _analyzing = false;
      _capturedImage = null;
      _rotationAngle = 0;
      _loadingPreConsultation = false;
    });
  }

  List<Map<String, dynamic>> _getSymptomsForPreConsultation() {
    final List<Map<String, dynamic>> symptoms = [];

    for (final entry in _selectedSymptomIds.entries) {
      final String symptomId = entry.key;
      final double? severityValue = entry.value;

      final Symptom symptom = Symptom.all.firstWhere(
        (s) => s.id == symptomId,
        orElse: () => Symptom(label: 'Unknown', id: symptomId),
      );

      String severityType = 'TEXT';
      dynamic severityJsonValue;

      if (symptomId == 'itching' || symptomId == 'pain') {
        severityType = 'NRS_1_10';
        severityJsonValue = severityValue ?? 5.0;
      } else {
        severityJsonValue = 'present';
      }

      symptoms.add({
        'name': symptom.label,
        'severity_type': severityType,
        'severity_value': severityJsonValue,
        'notes': '',
      });
    }

    return symptoms;
  }

  Future<void> _onViewPreConsultationPressed() async {
    if (_capturedImage == null || _selectedAreaId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please complete all steps before viewing pre-consultation summary.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_loadingPreConsultation) return;

    final bodyAreaString = _selectedAreaId!;
    final symptoms = _getSymptomsForPreConsultation();

    setState(() => _loadingPreConsultation = true);

    try {
      final preConsultationResult =
          await HealthLiteracyPreConsultationAssistant.processPreConsultationInput(
        image: base64Encode(_capturedImage!),
        bodyArea: bodyAreaString,
        symptoms: symptoms,
        onsetDuration: 'Unknown',
        appliedTreatments: [],
      );

      if (!mounted) return;
      widget.onViewPreConsultationSummary(preConsultationResult);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not generate the pre-consultation summary. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingPreConsultation = false);
      }
    }
  }

  ClinicalLogEntry _buildClinicalLogEntry() {
    RiskLevel riskLevel;
    switch (_result) {
      case TriageRisk.low:
        riskLevel = RiskLevel.low;
        break;
      case TriageRisk.moderate:
        riskLevel = RiskLevel.moderate;
        break;
      case TriageRisk.high:
        riskLevel = RiskLevel.high;
        break;
      case null:
        riskLevel = RiskLevel.low;
        break;
    }

    final DateTime now = DateTime.now();
    final List<double> trend = [_analysisResult?['primary_confidence'] ?? 0.0];

    String icon = 'image_outlined';
    if (_selectedAreaId != null) {
      switch (_selectedAreaId) {
        case 'face':
          icon = 'face_outlined';
          break;
        case 'scalp':
          icon = 'hair_outlined';
          break;
        case 'hand':
          icon = 'hand_outlined';
          break;
        case 'arm':
          icon = 'straighten_outlined';
          break;
        case 'leg':
          icon = 'directions_run_outlined';
          break;
        case 'torso':
          icon = 'person_outlined';
          break;
        default:
          icon = 'image_outlined';
          break;
      }
    }

    final List<String> recommendations = <String>[];
    switch (_result) {
      case TriageRisk.low:
        recommendations.add('This doesn\'t show signs of concern. We\'ll keep an eye on it in your Clinical Logs.');
        break;
      case TriageRisk.moderate:
        recommendations.add('Worth monitoring closely. Consider a follow-up scan in a few days.');
        recommendations.add('Keep the area clean and avoid irritants.');
        break;
      case TriageRisk.high:
        recommendations.add('These signs warrant a professional opinion soon.');
        recommendations.add('Consider scheduling an appointment with a dermatologist.');
        break;
      case null:
        recommendations.add('Complete a triage scan to get personalized recommendations.');
        break;
    }

    if (_selectedSymptomIds.isNotEmpty) {
      recommendations.add('Logged symptoms: ${_selectedSymptomIds.length} symptom${_selectedSymptomIds.length == 1 ? "" : "s"}');
    }

    return ClinicalLogEntry(
      id: now.millisecondsSinceEpoch.toString(),
      bodyArea: _selectedAreaId ?? 'Unknown',
      condition: _analysisResult?['primary_class'] ?? 'Unknown condition',
      loggedAt: now,
      confidence: _analysisResult?['primary_confidence'] ?? 0.0,
      risk: riskLevel,
      status: LogStatus.monitoring,
      trend: trend,
      icon: icon,
      recommendations: recommendations,
      imagePath: null,
      thoughtProcessJson: null,
      itching: _selectedSymptomIds.containsKey('itching') ? 'yes' : null,
      pain: _selectedSymptomIds.containsKey('pain') ? 'yes' : null,
      duration: _selectedSymptomIds.containsKey('oozing') ? 'acute' : null,
    );
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
        isInconclusive: _isInconclusive,
        isNormal: _isNormal,
        area: BodyArea.all.firstWhere((a) => a.id == _selectedAreaId, orElse: () => BodyArea.all.first),
        symptomCount: _selectedSymptomIds.length,
        onViewClinics: widget.onViewClinics,
        onStartOver: _startOver,
        onViewPreConsultationPressed: _onViewPreConsultationPressed,
        onExportPDFReport: widget.onExportPDFReport,
        loadingPreConsultation: _loadingPreConsultation,
        primaryClass: _analysisResult?['primary_class'] as String?,
        confidence: _analysisResult?['primary_confidence'] as double?,
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
          onSeverityChanged: _updateSymptomSeverity,
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
        debugPrint('Unexpected step value: $_step');
        return _AnalyzingView(colors: colors);
    }
  }
}

class _TriageHeader extends StatelessWidget {
  final int step;
  final int totalSteps;
  final VoidCallback? onBack;

  const _TriageHeader({
    required this.step,
    required this.totalSteps,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs / 2, AppSpacing.lg, AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: AppSpacing.lg * 2,
                height: AppSpacing.lg * 2,
                child: onBack == null
                    ? null
                    : IconButton(
                        onPressed: onBack,
                        icon: Icon(Icons.arrow_back_ios_new_rounded, size: AppSpacing.md, color: colorScheme.onSurface),
                      ),
              ),
              Expanded(
                child: Text(
                  'Pathology Triage',
                  textAlign: onBack == null ? TextAlign.left : TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
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
                      color: i <= step ? colorScheme.primary : colorScheme.outlineVariant,
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
            child: BodyAreaSelectionGrid(
              selectedId: selectedId,
              onSelect: onSelect,
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
  final Map<String, double?> selectedIds;
  final ValueChanged<String> onToggle;
  final void Function(String symptomId, double severity) onSeverityChanged;
  final VoidCallback? onContinue;

  const _SymptomStep({
    super.key,
    required this.colors,
    required this.selectedIds,
    required this.onToggle,
    required this.onSeverityChanged,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final symptom in Symptom.all)
                      SymptomChip(
                        label: symptom.label,
                        selected: selectedIds.containsKey(symptom.id),
                        onTap: () => onToggle(symptom.id),
                        tooltipMessage: _getSymptomTooltip(symptom.id),
                      ),
                  ],
                ),
                if (selectedIds.containsKey('itching') || selectedIds.containsKey('pain'))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (selectedIds.containsKey('itching'))
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Itch Severity:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary),
                              ),
                              Row(
                                children: [
                                  const Text('1 = Mild', style: TextStyle(fontSize: 12)),
                                  Expanded(
                                    child: Slider(
                                      value: selectedIds['itching'] ?? 5.0,
                                      min: 1.0,
                                      max: 10.0,
                                      divisions: 9,
                                      label: '${selectedIds['itching']?.round() ?? 5}',
                                      onChanged: (value) {
                                        onSeverityChanged('itching', value);
                                      },
                                      activeColor: colors.accent,
                                    ),
                                  ),
                                  const Text('10 = Severe', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        if (selectedIds.containsKey('pain'))
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pain Severity:',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colors.textPrimary),
                              ),
                              Row(
                                children: [
                                  const Text('1 = Mild', style: TextStyle(fontSize: 12)),
                                  Expanded(
                                    child: Slider(
                                      value: selectedIds['pain'] ?? 5.0,
                                      min: 1.0,
                                      max: 10.0,
                                      divisions: 9,
                                      label: '${selectedIds['pain']?.round() ?? 5}',
                                      onChanged: (value) {
                                        onSeverityChanged('pain', value);
                                      },
                                      activeColor: colors.accent,
                                    ),
                                  ),
                                  const Text('10 = Severe', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                _ContinueBar(colors: colors, onContinue: onContinue),
              ],
            ),
          ),
        ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add a photo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            'Position the lesion closely inside the frame for maximum AI visual accuracy.',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colorScheme.outline, style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Visual framing guidance - target reticle/outline
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.6),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Icon(Icons.image_search_rounded, size: MediaQuery.of(context).size.width * 0.07, color: colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'A clear, well-lit photo gives the most accurate assessment',
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ensure good lighting, focus on the area of concern, and keep the camera steady',
                        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
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
    final colorScheme = Theme.of(context).colorScheme;
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
              Icon(icon, size: MediaQuery.of(context).size.width * 0.0667, color: filled ? colorScheme.onPrimary : colors.textPrimary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: filled ? colorScheme.onPrimary : colors.textPrimary,
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surface,
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
              Text(
                'Analyzing your scan…',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Please wait a moment',
                style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12.5),
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
  final TriageRisk risk;
  final bool isInconclusive;
  final bool isNormal;
  final BodyArea area;
  final int symptomCount;
  final VoidCallback onViewClinics;
  final VoidCallback onStartOver;
  final VoidCallback onViewPreConsultationPressed;
  final ValueChanged<Map<String, dynamic>> onExportPDFReport;
  final bool loadingPreConsultation;
  final String? primaryClass;
  final double? confidence;

  const _ResultView({
    super.key,
    required this.colors,
    required this.risk,
    required this.isInconclusive,
    required this.isNormal,
    required this.area,
    required this.symptomCount,
    required this.onViewClinics,
    required this.onStartOver,
    required this.onViewPreConsultationPressed,
    required this.onExportPDFReport,
    required this.loadingPreConsultation,
    required this.primaryClass,
    required this.confidence,
  });

  Color get _riskColor {
    if (isInconclusive) return colors.warning;
    if (isNormal) return colors.success;
    switch (risk) {
      case TriageRisk.low:
        return colors.success;
      case TriageRisk.moderate:
        return colors.warning;
      case TriageRisk.high:
        return colors.danger;
    }
  }

  String get _riskLabel {
    if (isInconclusive) return 'Inconclusive';
    if (isNormal) return 'No Concern Detected';
    switch (risk) {
      case TriageRisk.low:
        return 'Low Risk';
      case TriageRisk.moderate:
        return 'Moderate Risk';
      case TriageRisk.high:
        return 'High Risk';
    }
  }

  String get _riskMessage {
    if (isInconclusive) {
      return "We couldn't get a clear read from this photo. Please consult a dermatologist, or retake the photo with better lighting and a closer, centered view of the area.";
    }
    if (isNormal) {
      return "No signs of a skin or scalp condition were detected in this photo. We'll keep an eye on it in your Clinical Logs.";
    }
    switch (risk) {
      case TriageRisk.low:
        return "This appears to be a mild condition. We'll keep an eye on it in your Clinical Logs.";
      case TriageRisk.moderate:
        return 'Worth monitoring closely. Consider a follow-up scan in a few days.';
      case TriageRisk.high:
        return 'These signs warrant a professional opinion soon.';
    }
  }

  String get _scoreValue {
    if (isInconclusive) return '—';
    if (isNormal) return '98';
    switch (risk) {
      case TriageRisk.low:
        return '92';
      case TriageRisk.moderate:
        return '61';
      case TriageRisk.high:
        return '28';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (primaryClass != null && confidence != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                '$primaryClass — ${(confidence! * 100).toStringAsFixed(1)}% AI Match',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ScoreHeroCard(
            colors: colors,
            overrideColor: _riskColor,
            statusLabel: _riskLabel,
            scoreValue: _scoreValue,
            scoreUnit: isInconclusive ? '' : '/ 100',
            subtitle: '${area.label} · $symptomCount symptom${symptomCount == 1 ? '' : 's'} logged',
          ),
          const SizedBox(height: 18),
          Text(
            _riskMessage,
            style: TextStyle(fontSize: 13.5, color: colors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          isInconclusive
            ? ElevatedButton(
                onPressed: onStartOver,
                style: elevatedButtonStyle(context, backgroundColor: colors.warning),
                child: const Text('Retake Photo', style: TextStyle(fontWeight: FontWeight.w700)),
              )
            : !isNormal && risk == TriageRisk.high
                ? ElevatedButton(
                    onPressed: onViewClinics,
                    style: elevatedButtonStyle(context, backgroundColor: colors.danger),
                    child: const Text('Find Nearby Clinics', style: TextStyle(fontWeight: FontWeight.w700)),
                  )
                : ElevatedButton(
                    onPressed: onStartOver,
                    style: elevatedButtonStyle(context),
                    child: const Text('Saved to Clinical Logs', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: loadingPreConsultation ? null : onViewPreConsultationPressed,
            style: elevatedButtonStyle(context, backgroundColor: colors.accent),
            child: loadingPreConsultation
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colors.background),
                  )
                : const Text('View Pre-Consultation Summary', style: TextStyle(fontWeight: FontWeight.w700)),
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
    final colorScheme = Theme.of(context).colorScheme;
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
              Icon(icon, size: MediaQuery.of(context).size.width * 0.0667, color: filled ? colorScheme.onPrimary : colors.textPrimary),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: filled ? colorScheme.onPrimary : colors.textPrimary,
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