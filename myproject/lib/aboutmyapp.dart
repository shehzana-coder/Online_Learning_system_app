import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About Speakora',
          style: TextStyle(
              color: Color.fromARGB(255, 0, 0, 0),
              fontWeight: FontWeight.bold,
              fontSize: 24),
        ),
        backgroundColor: Color.fromARGB(255, 255, 144, 187),
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Speakora',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Our Mission'),
            _buildSectionContent(
              'Speakora is dedicated to empowering users to communicate effectively and confidently. Our app provides innovative tools and features to enhance your communication experience, whether for personal, professional, or creative purposes.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('What We Offer'),
            _buildSectionContent(
              'Speakora offers a range of features designed to make communication seamless and engaging, including:\n'
              '- Real-time voice and text interaction.\n'
              '- Customizable settings for a personalized experience.\n'
              '- Tools to improve language skills and expression.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Our Commitment'),
            _buildSectionContent(
              'We are committed to providing a secure, user-friendly, and accessible platform for all users. Your feedback helps us improve, and we strive to deliver updates that enhance your experience with Speakora.',
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Contact Us'),
            _buildSectionContent(
              'Have questions or suggestions? Reach out to us at:\n'
              'Email: support@speakora.com\n'
              'Address: Speakora Inc., 123 Privacy Lane, App City, AC 12345\n'
              'Website: www.speakora.com',
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
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'poppins',
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
