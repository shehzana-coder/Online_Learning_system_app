import 'package:flutter/material.dart';
import 'changepassword.dart';
import 'about_page.dart';
import '../homesetting/setting_profile.dart';
import '../screens/welcome_screen.dart';
import 'package:flutter/services.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({Key? key}) : super(key: key);

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final String _name = 'User';
  final String _email = '';
  bool _isDarkMode = false;

  void _shareApp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.share, color: Color(0xFF0F1A54)),
            SizedBox(width: 8),
            Text('Share TeachUp'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share this app with your friends and colleagues:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                'Download TeachUp – Find your perfect tutor!\nhttps://teachup.app',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(const ClipboardData(
                text: 'Download TeachUp – Find your perfect tutor!\nhttps://teachup.app',
              ));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link copied to clipboard!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F1A54),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1A54),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile & Settings',
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Profile Header
          Container(
            color: const Color(0xFF0F1A54),
            padding: const EdgeInsets.only(bottom: 30, top: 10),
            child: Column(
              children: [
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingProfilePage(),
                            ),
                          );
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.deepPurple,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingProfilePage(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Profile'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // General Settings
          _sectionTitle('General Settings'),
          _settingsTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            subtitle: _isDarkMode ? 'Enabled' : 'Disabled',
            trailing: Switch(
              value: _isDarkMode,
              onChanged: (value) => setState(() => _isDarkMode = value),
              activeColor: const Color(0xFF0F1A54),
            ),
          ),
          _settingsTile(
            icon: Icons.vpn_key,
            title: 'Change Password',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
            ),
          ),
          _settingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LanguageSettingsPage(),
              ),
            ),
          ),
          _settingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationSettingsPage(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Information
          _sectionTitle('Information'),
          _settingsTile(
            icon: Icons.info,
            title: 'About App',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
          ),
          _settingsTile(
            icon: Icons.description,
            title: 'Terms & Conditions',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TermsAndConditionsPage(),
              ),
            ),
          ),
          _settingsTile(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PrivacyPolicyPage(),
              ),
            ),
          ),
          _settingsTile(
            icon: Icons.share,
            title: 'Share This App',
            onTap: () => _shareApp(),
          ),

          const SizedBox(height: 16),

          // Logout
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Logout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade200,
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1A54).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF0F1A54), size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ??
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}

// Language Settings Page
class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({Key? key}) : super(key: key);

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  String _selectedLanguage = 'English';

  final List<Map<String, String>> _languages = [
    {'name': 'English', 'native': 'English'},
    {'name': 'Urdu', 'native': 'اردو'},
    {'name': 'Arabic', 'native': 'العربية'},
    {'name': 'Hindi', 'native': 'हिन्दी'},
    {'name': 'French', 'native': 'Français'},
    {'name': 'Spanish', 'native': 'Español'},
    {'name': 'German', 'native': 'Deutsch'},
    {'name': 'Chinese', 'native': '中文'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language'),
        backgroundColor: const Color(0xFF0F1A54),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select your preferred language',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          ..._languages.map((lang) => RadioListTile<String>(
                title: Text(lang['name']!),
                subtitle: Text(lang['native']!),
                value: lang['name']!,
                groupValue: _selectedLanguage,
                activeColor: const Color(0xFF0F1A54),
                onChanged: (value) {
                  setState(() => _selectedLanguage = value!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Language set to ${lang['name']}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              )),
        ],
      ),
    );
  }
}

// Notification Settings Page
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _enrollmentNotifs = true;
  bool _messageNotifs = true;
  bool _reminderNotifs = false;
  bool _updateNotifs = true;
  bool _promotionalNotifs = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF0F1A54),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Manage your notification preferences',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          _notifTile(
            title: 'Enrollment Updates',
            subtitle: 'Get notified when a student enrolls with you',
            value: _enrollmentNotifs,
            onChanged: (v) => setState(() => _enrollmentNotifs = v),
          ),
          _notifTile(
            title: 'New Messages',
            subtitle: 'Receive alerts for new messages',
            value: _messageNotifs,
            onChanged: (v) => setState(() => _messageNotifs = v),
          ),
          _notifTile(
            title: 'Class Reminders',
            subtitle: 'Reminders before your scheduled classes',
            value: _reminderNotifs,
            onChanged: (v) => setState(() => _reminderNotifs = v),
          ),
          _notifTile(
            title: 'App Updates',
            subtitle: 'Be informed about new features and updates',
            value: _updateNotifs,
            onChanged: (v) => setState(() => _updateNotifs = v),
          ),
          _notifTile(
            title: 'Promotions & Offers',
            subtitle: 'Receive promotional content and special offers',
            value: _promotionalNotifs,
            onChanged: (v) => setState(() => _promotionalNotifs = v),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification preferences saved!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F1A54),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Preferences'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _notifTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF0F1A54),
    );
  }
}

// Terms and Conditions Page
class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: const Color(0xFF0F1A54),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms & Conditions',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Last updated: ${DateTime.now().year}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _section(
              '1. Acceptance of Terms',
              'By accessing and using TeachUp, you accept and agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the application.',
            ),
            _section(
              '2. User Accounts',
              'You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorized use of your account. TeachUp is not liable for any loss resulting from unauthorized use of your account.',
            ),
            _section(
              '3. User Conduct',
              'You agree to use TeachUp only for lawful purposes. You must not post false, misleading, or fraudulent information. Harassment, abuse, or harmful behavior toward other users is strictly prohibited.',
            ),
            _section(
              '4. Teacher Profiles',
              'Teachers are responsible for the accuracy of their profile information, qualifications, and course details. TeachUp does not verify credentials and is not responsible for the quality of tutoring services provided.',
            ),
            _section(
              '5. Student Enrollment',
              'Enrollment through TeachUp connects students with teachers. Any agreements, payments, or arrangements made between students and teachers are solely between those parties. TeachUp is not a party to such agreements.',
            ),
            _section(
              '6. Content',
              'All content provided on TeachUp, including notes and video lectures, is for educational purposes only. Users may not reproduce, distribute, or commercially exploit this content without permission.',
            ),
            _section(
              '7. Privacy',
              'Your use of TeachUp is also governed by our Privacy Policy. By using the app, you consent to the collection and use of your information as described in the Privacy Policy.',
            ),
            _section(
              '8. Modifications',
              'TeachUp reserves the right to modify these terms at any time. Continued use of the application after changes constitutes acceptance of the new terms.',
            ),
            _section(
              '9. Termination',
              'TeachUp reserves the right to terminate or suspend your account at any time for violations of these terms or for any other reason at our sole discretion.',
            ),
            _section(
              '10. Contact',
              'For questions about these Terms & Conditions, please contact us at support@teachup.app.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F1A54),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

// Privacy Policy Page
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: const Color(0xFF0F1A54),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Last updated: ${DateTime.now().year}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _section(
              '1. Information We Collect',
              'We collect information you provide directly, such as your name, email address, phone number, and profile details. We also collect usage data to improve the app experience.',
            ),
            _section(
              '2. How We Use Your Information',
              'We use your information to provide and improve TeachUp services, connect students with teachers, send important notifications, and ensure the security of your account.',
            ),
            _section(
              '3. Data Storage',
              'Your data is stored securely using Firebase (Google Cloud). We implement industry-standard security measures to protect your personal information from unauthorized access.',
            ),
            _section(
              '4. Data Sharing',
              'We do not sell your personal information. Teacher profile information (name, qualifications, courses) is visible to students. Student information is only shared with teachers you enroll with.',
            ),
            _section(
              '5. Cookies and Analytics',
              'We may use analytics tools to understand how users interact with TeachUp. This data is anonymized and used solely to improve the application.',
            ),
            _section(
              '6. Your Rights',
              'You have the right to access, correct, or delete your personal data at any time through your profile settings. You may also request account deletion by contacting our support team.',
            ),
            _section(
              '7. Children\'s Privacy',
              'TeachUp is not intended for children under 13. We do not knowingly collect personal information from children under 13. If you believe a child has provided us with personal information, please contact us.',
            ),
            _section(
              '8. Changes to This Policy',
              'We may update this Privacy Policy periodically. We will notify you of significant changes through the app or via email.',
            ),
            _section(
              '9. Contact Us',
              'If you have questions about this Privacy Policy or how we handle your data, please contact us at support@teachup.app.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F1A54),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
