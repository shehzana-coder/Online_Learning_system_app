import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms and Conditions',
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
              'Speakora Terms and Conditions',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
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
            _buildSectionTitle('1. Acceptance of Terms'),
            _buildSectionContent(
              'By accessing or using the Speakora mobile application, you agree to be bound by these Terms and Conditions. If you do not agree with any part of these terms, you may not use the app.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('2. Use of the App'),
            _buildSectionContent(
              'You agree to use Speakora only for lawful purposes and in a way that does not infringe the rights of others or restrict their use of the app. Prohibited activities include:\n'
              '- Unauthorized access to our systems.\n'
              '- Posting or transmitting harmful or illegal content.\n'
              '- Interfering with the app’s functionality.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('3. User Accounts'),
            _buildSectionContent(
              'To access certain features, you may need to create an account. You are responsible for maintaining the confidentiality of your account information and for all activities under your account.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('4. Intellectual Property'),
            _buildSectionContent(
              'All content, trademarks, and other intellectual property within Speakora are owned by or licensed to Speakora Inc. You may not copy, modify, or distribute any content without prior written permission.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('5. Limitation of Liability'),
            _buildSectionContent(
              'Speakora is provided "as is" without warranties of any kind. We are not liable for any damages arising from your use of the app, including but not limited to direct, indirect, or consequential damages.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('6. Termination'),
            _buildSectionContent(
              'We may terminate or suspend your access to Speakora at any time, without notice, for conduct that violates these Terms or is harmful to other users or us.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('7. Changes to Terms'),
            _buildSectionContent(
              'We may update these Terms and Conditions from time to time. Continued use of the app after changes constitutes acceptance of the new terms.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('8. Contact Us'),
            _buildSectionContent(
              'If you have any questions about these Terms and Conditions, please contact us at:\n'
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
