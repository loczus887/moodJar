import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF2D2D2D);
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: January 2026',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            _buildPolicySection(
              '1. Introduction',
              'Welcome to Mood Jar ("we," "our," or "us"). We are committed to protecting your privacy and ensuring the security of your personal data. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application, Mood Jar.',
              textColor,
            ),
            _buildPolicySection(
              '2. Information We Collect',
              'We may collect the following types of information:\n\n'
                  '• Personal Data: When you create an account, we may collect personal information such as your name, email address, and profile picture.\n'
                  '• Mood Data: We collect the mood entries, notes, and timestamps you record within the app.\n'
                  '• Usage Data: We may collect information about how you access and use the app, including your device type, operating system, and usage patterns.',
              textColor,
            ),
            _buildPolicySection(
              '3. How We Use Your Information',
              'We use the information we collect for the following purposes:\n\n'
                  '• To provide and maintain our service.\n'
                  '• To personalize your experience and provide insights into your mood patterns.\n'
                  '• To improve our app and develop new features.\n'
                  '• To communicate with you, including sending updates and notifications.\n'
                  '• To ensure the security of your account and data.',
              textColor,
            ),
            _buildPolicySection(
              '4. Data Security',
              'We implement appropriate technical and organizational measures to protect your personal data against unauthorized access, alteration, disclosure, or destruction. However, please be aware that no method of transmission over the internet or method of electronic storage is 100% secure.',
              textColor,
            ),
            _buildPolicySection(
              '5. Third-Party Services',
              'We may use third-party services, such as Firebase, to facilitate our service, provide analysis, or assist us in analyzing how our service is used. These third parties have access to your personal data only to perform these tasks on our behalf and are obligated not to disclose or use it for any other purpose.',
              textColor,
            ),
            _buildPolicySection(
              '6. Your Rights',
              'You have the right to access, correct, or delete your personal data. You can manage your data within the app settings or contact us for assistance. You may also have the right to restrict or object to certain processing of your data.',
              textColor,
            ),
            _buildPolicySection(
              '7. Changes to This Privacy Policy',
              'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page. You are advised to review this Privacy Policy periodically for any changes.',
              textColor,
            ),
            _buildPolicySection(
              '8. Contact Us',
              'If you have any questions about this Privacy Policy, please contact us at support@moodjar.app.',
              textColor,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection(String title, String content, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: textColor.withOpacity(0.8),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
