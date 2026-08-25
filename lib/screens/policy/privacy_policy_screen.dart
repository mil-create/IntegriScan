import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import '../../theme/spacing.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<ThemeProvider>().colors;

    return Scaffold(
  backgroundColor: colors.background,
  appBar: AppBar(
    backgroundColor: colors.background,
    elevation: 0,
    iconTheme: IconThemeData(color: colors.textPrimary),
    title: Text(
      'Privacy Policy',
      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700),
    ),
  ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Last updated: August 23, 2026',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Introduction',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'IntegriScan ("we", "our", or "us") is committed to protecting your privacy. '
              'This Privacy Policy explains how we collect, use, disclose, and safeguard your information '
              'when you use our mobile application, IntegriScan (the "Service"). '
              'By accessing or using the Service, you agree to the terms of this Privacy Policy. '
              'If you do not agree with the terms of this policy, please do not access or use the Service.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Information We Collect',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'While using our Service, we may ask you to provide us with certain personally identifiable '
              'information that can be used to contact or identify you. Personally identifiable information '
              'may include, but is not limited to:',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              '• Email address\n'
              '• First name and last name\n'
              '• Phone number\n'
              '• Address, state, province, ZIP/Postal code, city\n'
              '• Usage data\n'
              '• Images uploaded for analysis',
              style: TextStyle(
                fontSize: 14,
                height: 1.8,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'How We Use Your Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'We may use the information we collect for various purposes, including:',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              '• To provide and maintain our Service\n'
              '• To manage your account\n'
              '• For performance monitoring and analysis\n'
              '• To contact you with updates and notifications\n'
              '• To improve and personalize your experience\n'
              '• To comply with legal obligations\n'
              '• For fraud detection and prevention\n'
              '• For business analytics and marketing',
              style: TextStyle(
                fontSize: 14,
                height: 1.8,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Data Security',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'The security of your data is important to us, but remember that no method of transmission '
              'over the Internet, or method of electronic storage is 100% secure. '
              'While we strive to use commercially acceptable means to protect your Personal Information, '
              'we cannot guarantee its absolute security.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Changes to This Privacy Policy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'We may update our Privacy Policy from time to time. '
              'We will notify you of any changes by posting the new Privacy Policy on this page. '
              'You are advised to review this Privacy Policy periodically for any changes. '
              'Changes to this Privacy Policy are effective when they are posted on this page.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'If you have any questions about this Privacy Policy, please contact us:',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Email: privacy@integriScan.com\n'
              'Phone: +1 (555) 123-4567\n'
              'Address: 123 Health Tech Ave, San Francisco, CA 94107, USA',
              style: TextStyle(
                fontSize: 14,
                height: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}