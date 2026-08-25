import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import '../../theme/spacing.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
      'Terms of Service',
      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700),
    ),
  ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
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
              'Acceptance of Terms',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'By accessing or using the IntegriScan mobile application (the "Service"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to all of the terms, then you may not access or use the Service.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Description of Service',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'IntegriScan provides an AI-powered skin and scalp pathology assistant designed to help users analyze images for potential health concerns. The Service uses artificial intelligence to provide risk assessments and recommendations based on uploaded images.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'User Accounts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'To access certain features of the Service, you may need to create an account. You agree to provide accurate, current, and complete information during the registration process and to update such information to keep it accurate, current, and complete.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'User Responsibilities',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'You are responsible for all activity that occurs under your account, including any actions taken by unauthorized users who gain access to your account through your security credentials. You must maintain the security of your account credentials and promptly notify us of any unauthorized use.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Intellectual Property',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'The Service and its original content, features, and functionality are and will remain the exclusive property of IntegriScan and its licensors. The Service is protected by copyright, trademark, and other laws of both the United States and foreign countries.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Disclaimer of Warranties',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE," WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT. '
              'INTEGRISCAN DOES NOT WARRANT THAT THE SERVICE WILL BE UNINTERRUPTED OR ERROR-FREE, THAT DEFECTS WILL BE CORRECTED, OR THAT THE SERVICE WILL BE FREE OF VIRUSES OR OTHER HARMFUL COMPONENTS.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Limitation of Liability',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'IN NO EVENT SHALL INTEGRISCAN, NOR ITS DIRECTORS, EMPLOYEES, PARTNERS, AGENTS, SUBSIDIARIES, OR AFFILIATES, BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR EXEMPLARY DAMAGES ARISING OUT OF OR IN ANY WAY RELATED TO YOUR USE OF THE SERVICE, WHETHER OR NOT WE HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Changes to Terms',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material, we will provide at least 30 days notice prior to any new terms taking effect. What constitutes a material change will be determined at our sole discretion.',
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
              'If you have any questions about these Terms of Service, please contact us:',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Email: legal@integriScan.com\n'
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