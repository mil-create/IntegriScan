import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme/theme_provider.dart';
import '../theme/app_colors.dart';
import '../theme/auth_provider.dart';
import '../theme/button_styles.dart';
import '../theme/spacing.dart';
import '../models/user.dart';
import '../screens/policy/privacy_policy_screen.dart';
import '../screens/policy/terms_of_service_screen.dart';
import '../utils/error_handler.dart';
import '../widgets/retry_network_image.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _versionInfo = 'Loading...';
  bool _isLoadingVersion = true;
  bool _notificationsEnabled = false;
  bool _aiSensitivityEnabled = false;

  @override
  void initState() {
    super.initState();
    _getVersionInfo();
  }

  Future<void> _getVersionInfo() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _versionInfo =
            'Version ${packageInfo.version} (Build ${packageInfo.buildNumber})';
        _isLoadingVersion = false;
      });
    } catch (e) {
      setState(() {
        _versionInfo = 'Version 1.0.0+1';
        _isLoadingVersion = false;
      });
    }
  }

  Future<void> _pickAvatarImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        // ImagePicker with maxWidth/maxHeight/imageQuality already validates and compresses.
        // No need to read full bytes into memory just to validate.
        // In a real app, you would upload pickedFile.path to a server and update the user's photoUrl
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar updated! (In a real app, this would upload to your profile)'),
            ),
          );
        }
      }
    } catch (e) {
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

  void _showAvatarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAvatarImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAvatarImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;
    final authProvider = context.watch<AuthProvider>();
    final User? user = authProvider.user;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // User Profile Section
        if (user != null)
          _buildProfileSection(context, colors, user)
        else
          _buildNotSignedInSection(context, colors),

        const SizedBox(height: 32),

        // App Information Section
        _buildAppInfoSection(context, colors),

        const SizedBox(height: 32),

        // Actions Section
        _buildActionsSection(context, colors, authProvider, user),
      ],
    );
  }

  Widget _buildProfileSection(BuildContext context, AppColors colors, User user) {
    return Column(
      children: [
        Stack(
          children: [
            // Avatar with camera overlay for editing
            user.photoUrl != null && user.photoUrl!.isNotEmpty
                ? ClipOval(
                    child: RetryNetworkImage(
                      imageUrl: user.photoUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error) {
                        return _buildAvatarFallback(colors, user);
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                            color: colors.accent,
                          ),
                        );
                      },
                    ),
                  )
                : _buildAvatarFallback(colors, user),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.accent,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.white,
                  ),
                  onPressed: () => _showAvatarOptions(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          user.displayName ?? 'Anonymous User',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs - 4), // 4 = 8-4
        Text(
          user.email,
          style: TextStyle(
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
        if (!user.isEmailVerified) ...[
          const SizedBox(height: AppSpacing.sm - 4), // 4 = 12-8
          Text(
            'Email not verified',
            style: TextStyle(
              fontSize: 12,
              color: colors.warning,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildAvatarFallback(AppColors colors, User user) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: colors.accent.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          user.displayName?.isNotEmpty == true
              ? user.displayName![0].toUpperCase()
              : 'U',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colors.accent,
          ),
        ),
      ),
    );
  }

  Widget _buildNotSignedInSection(BuildContext context, AppColors colors) {
    return Column(
      children: [
        Icon(Icons.person_outline_rounded, size: 60, color: colors.textSecondary),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Welcome to IntegriScan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm - 4), // 4 = 8-4
        Text(
          'Sign in to access your personal scan history and settings',
          style: TextStyle(
            fontSize: 14,
            color: colors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/login');
            },
            style: elevatedButtonStyle(context),
            child: const Text(
              'Sign In',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/register');
            },
            style: outlinedButtonStyle(context),
            child: Text(
              'Create Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfoSection(BuildContext context, AppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About IntegriScan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm - 4), // 4 = 8-4
        Text(
          'AI-powered Skin & Scalp Pathology Assistant designed for Filipino skin tones.',
          style: TextStyle(
            fontSize: 14,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _isLoadingVersion
            ? const SizedBox(
                height: 16,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              )
            : Text(
                _versionInfo,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
      ],
    );
  }

  Widget _buildActionsSection(
      BuildContext context,
      AppColors colors,
      AuthProvider authProvider,
      User? user
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (user != null) ...[
          ListTile(
            leading: Icon(Icons.history, color: colors.textSecondary),
            title: const Text('Scan History'),
            trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
            onTap: () {
              // Navigate to scan history (already available in logs tab)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Your scan history is available in the Clinical Logs tab'),
                ),
              );
            },
          ),
          ExpansionTile(
            leading: Icon(Icons.settings, color: colors.textSecondary),
            title: const Text('Settings'),
            trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text(
                  'Switch between light and dark themes',
                  style: TextStyle(fontSize: 12),
                ),
                value: context.watch<ThemeProvider>().isDarkMode,
                onChanged: (bool value) {
                  context.read<ThemeProvider>().setDarkMode(value);
                },
                secondary: Icon(
                  context.watch<ThemeProvider>().isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: colors.textSecondary,
                ),
              ),
              SwitchListTile(
                title: const Text('Notifications'),
                subtitle: const Text(
                  'Receive push notifications for scan results and updates',
                  style: TextStyle(fontSize: 12),
                ),
                value: _notificationsEnabled,
                onChanged: (bool value) {
                  setState(() => _notificationsEnabled = value);
                  // TODO: Connect to backend service
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Notifications setting: $value (Backend connection coming soon)'),
                    ),
                  );
                },
                secondary: Icon(Icons.notifications, color: colors.textSecondary),
              ),
              SwitchListTile(
                title: const Text('AI Sensitivity'),
                subtitle: const Text(
                  'Adjust analysis sensitivity for more/less detections',
                  style: TextStyle(fontSize: 12),
                ),
                value: _aiSensitivityEnabled,
                onChanged: (bool value) {
                  setState(() => _aiSensitivityEnabled = value);
                  // TODO: Connect to backend service
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('AI Sensitivity: $value (Backend connection coming soon)'),
                    ),
                  );
                },
                secondary: Icon(Icons.psychology, color: colors.textSecondary),
              ),
            ],
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip, color: colors.textSecondary),
            title: const Text('Privacy Policy'),
            trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.description, color: colors.textSecondary),
            title: const Text('Terms of Service'),
            trailing: Icon(Icons.chevron_right, color: colors.textSecondary),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
              );
            },
          ),
          const Divider(
            height: AppSpacing.xl * 2, // 40 = 20*2
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await authProvider.logout();
                // Optionally show a success message
                // Note: We cannot use ScaffoldMessenger after logout because the widget may be disposed.
                // Instead, we rely on the logout action to update the UI.
              },
              style: elevatedButtonStyle(context, backgroundColor: colors.danger),
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}