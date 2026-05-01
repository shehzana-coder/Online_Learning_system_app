import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 144, 187),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Speakora Privacy Policy',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Last Updated: June 20, 2025',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('1. Introduction'),
            _buildSectionContent(
              'Welcome to Speakora! We are committed to protecting your privacy and ensuring that your personal information is handled in a safe and responsible manner. This Privacy Policy explains how we collect, use, and safeguard your information when you use our mobile application.',
            ),
            const SizedBox(height: 14),
            _buildSectionTitle('2. Information We Collect'),
            _buildSectionContent(
              'We may collect the following types of information:\n'
              '- Personal Information: Name, email address, and other information you provide when registering or contacting us.\n'
              '- Usage Data: Information about how you interact with the app, such as features used and time spent.\n'
              '- Device Information: Device type, operating system, and unique device identifiers.',
            ),
            const SizedBox(height: 14),
            _buildSectionTitle('3. How We Use Your Information'),
            _buildSectionContent(
              'We use your information to:\n'
              '- Provide and improve the Speakora app.\n'
              '- Personalize your experience.\n'
              '- Communicate with you about updates or support.\n'
              '- Analyze usage to enhance app functionality.',
            ),
            const SizedBox(height: 14),
            _buildSectionTitle('4. Data Sharing'),
            _buildSectionContent(
              'We do not sell your personal information. We may share your information with:\n'
              '- Service providers who assist in app operations.\n'
              '- Legal authorities if required by law.',
            ),
            const SizedBox(height: 14),
            _buildSectionTitle('5. Data Security'),
            _buildSectionContent(
              'We implement industry-standard security measures to protect your data. However, no method of transmission over the internet is 100% secure, and we cannot guarantee absolute security.',
            ),
            const SizedBox(height: 14),
            _buildSectionTitle('6. Your Rights'),
            _buildSectionContent(
              'You have the right to:\n'
              '- Access and update your personal information.\n'
              '- Request deletion of your data.\n'
              '- Opt-out of certain data collection practices.\n'
              'Contact us at support@speakora.com to exercise these rights.',
            ),
            const SizedBox(height: 14),
            _buildSectionTitle('7. Contact Us'),
            _buildSectionContent(
              'If you have any questions about this Privacy Policy, please contact us at:\n'
              'Email: support@speakora.com\n'
              'Address: Speakora Inc., 123 Privacy Lane, App City, AC 12345',
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                        context); // Navigate back to the previous screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 144, 187),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(
      content,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
        height: 1.5,
      ),
    );
  }
}
