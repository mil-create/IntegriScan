import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/theme_provider.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/scan_action_sheet.dart';
import 'home_screen.dart';
import 'pathology_triage_screen.dart';
import 'clinical_logs_screen.dart';
import 'account_screen.dart';
import 'clinic_locator_screen.dart';

/// Root scaffold. Holds the local UI state shared across tabs — active
/// tab, scan overlay, and the AI risk flag — using plain StatefulWidget
/// + setState (Flutter's equivalent of useState).
///
/// Tabs: Home Dashboard · Pathology Triage · Clinical Logs · Account.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _highRiskFlag = false; // set by the AI background pipeline in production

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  void _openScanSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScanActionSheet(
        onViewHistory: () {
          Navigator.pop(context);
          setState(() => _currentIndex = 2); // jump straight to Clinical Logs
        },
        onTakePhoto: _handleTakePhoto,
        onUploadPhoto: _handleUploadPhoto,
      ),
    );
  }

  Future<void> _handleTakePhoto() async {
    Navigator.pop(context); // Close the bottom sheet
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      maxHeight: 1080,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PathologyTriageScreen(
              onViewClinics: _openClinicLocator,
              onTriageComplete: _onTriageComplete,
              initialImage: bytes,
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleUploadPhoto() async {
    Navigator.pop(context); // Close the bottom sheet
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PathologyTriageScreen(
              onViewClinics: _openClinicLocator,
              onTriageComplete: _onTriageComplete,
              initialImage: bytes,
            ),
          ),
        );
      }
    }
  }

  void _openClinicLocator() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ClinicLocatorScreen()),
    );
  }

  /// Demo hook standing in for the real AI background pipeline. Wire
  /// this up to fire automatically once a scan result comes back with
  /// a high-risk classification.
  void _simulateHighRiskScan() {
    setState(() => _highRiskFlag = true);
  }

  /// Fired when the Pathology Triage flow finishes. If the mock/real
  /// model flags the result as high risk, surface the same banner +
  /// clinic-locator redirect used for scan results elsewhere.
  void _onTriageComplete(bool isHighRisk) {
    if (isHighRisk) {
      setState(() => _highRiskFlag = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    final screens = [
      HomeScreen(
        highRiskFlag: _highRiskFlag,
        onDismissRiskBanner: () => setState(() => _highRiskFlag = false),
        onViewClinics: _openClinicLocator,
        onSimulateHighRisk: _simulateHighRiskScan,
        onOpenTriage: () => setState(() => _currentIndex = 1),
        onOpenLogs: () => setState(() => _currentIndex = 2),
      ),
      PathologyTriageScreen(
        onViewClinics: _openClinicLocator,
        onTriageComplete: _onTriageComplete,
      ),
      ClinicalLogsScreen(onLogNewScan: _openScanSheet),
      const AccountScreen(),
    ];

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        top: false,
        child: IndexedStack(index: _currentIndex, children: screens),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        onScanTap: _openScanSheet,
      ),
    );
  }
}
