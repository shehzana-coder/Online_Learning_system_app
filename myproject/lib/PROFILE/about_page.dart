import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.white70;
    final headingColor = Colors.white;
    final accentColor = Colors.blue[300];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 18, 40, 73),
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Icon with Animation
              Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(70),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: Image.asset(
                      'assets/app_logo.png', // Replace with your actual logo
                      width: 80,
                      height: 80,
                      errorBuilder:
                          (context, error, stackTrace) => Icon(
                            Icons.school,
                            color: const Color(0xFF122849),
                            size: 60,
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // App Name
              Center(
                child: Text(
                  'TeachUp',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: headingColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Your Academic Companion',
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // App Info Card
              Card(
                elevation: 4,
                color: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: accentColor),
                          const SizedBox(width: 10),
                          Text(
                            'App Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: headingColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This app allows students to manage their profiles, update passwords, and access course-related information securely and easily.',
                        style: TextStyle(fontSize: 16, color: textColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Features Card
              Card(
                elevation: 4,
                color: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: accentColor),
                          const SizedBox(width: 10),
                          Text(
                            'Key Features',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: headingColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FeatureItem(
                        icon: Icons.person,
                        text: 'Student Profile Management',
                        color: accentColor!,
                      ),
                      FeatureItem(
                        icon: Icons.book,
                        text: 'Course Information Access',
                        color: accentColor,
                      ),
                      FeatureItem(
                        icon: Icons.notifications,
                        text: 'Important Announcements',
                        color: accentColor,
                      ),
                      FeatureItem(
                        icon: Icons.calendar_today,
                        text: 'Academic Calendar',
                        color: accentColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Version & Developer Card
              Card(
                elevation: 4,
                color: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.code, color: accentColor),
                          const SizedBox(width: 10),
                          Text(
                            'Technical Info',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: headingColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.numbers, color: textColor, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Version:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: headingColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '1.0.0',
                            style: TextStyle(fontSize: 16, color: textColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.people, color: textColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Developed By:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: headingColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'TeachUp Development Team\nDepartment of Computer Science',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Contact & Support Card
              Card(
                elevation: 4,
                color: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.contact_support, color: accentColor),
                          const SizedBox(width: 10),
                          Text(
                            'Contact & Support',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: headingColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.email, color: textColor, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Email:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: headingColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'support@teachup.app',
                            style: TextStyle(fontSize: 16, color: accentColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.web, color: textColor, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Website:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: headingColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'www.teachup.app',
                            style: TextStyle(fontSize: 16, color: accentColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Social Media Icons
              Center(
                child: Wrap(
                  spacing: 20,
                  children: [
                    _buildSocialIcon(Icons.facebook, 'Facebook'),
                    _buildSocialIcon(Icons.android, 'GitHub'),
                    _buildSocialIcon(Icons.telegram, 'Telegram'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      '© ${DateTime.now().year} Student Portal. All rights reserved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Privacy Policy',
                          style: TextStyle(color: accentColor),
                        ),
                        SizedBox(width: 8),
                        Text('|', style: TextStyle(color: textColor)),
                        SizedBox(width: 8),
                        Text(
                          'Terms of Service',
                          style: TextStyle(color: accentColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const FeatureItem({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
