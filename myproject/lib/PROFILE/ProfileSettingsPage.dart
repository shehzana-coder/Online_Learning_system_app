import 'package:flutter/material.dart';
// Import or create these pages accordingly
import 'changepassword.dart';
// import 'language_page.dart';
import 'about_page.dart';
// import 'terms_page.dart';
// import 'privacy_page.dart';
// import 'share_app_page.dart';

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1A54),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),

          // Profile Header
          Center(
            child: Stack(
              children: [
                const CircleAvatar(
                  radius: 45,
                  backgroundImage: NetworkImage(
                    'https://via.placeholder.com/150',
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF0F1A54),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              "Jonathan Patterson",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const Center(
            child: Text(
              "hello@reallygreatsite.com",
              style: TextStyle(color: Colors.grey),
            ),
          ),

          const SizedBox(height: 30),

          sectionTitle("General Settings"),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Mode"),
            subtitle: const Text("Dark & Light"),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // Add logic for mode toggle
              },
              activeColor: const Color(0xFF0F1A54),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.vpn_key),
            title: const Text("Change Password"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("Language"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaceholderPage(title: "Language Settings"),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          sectionTitle("Information"),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("About App"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AboutPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text("Terms & Conditions"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaceholderPage(title: "Terms & Conditions"),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text("Privacy Policy"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaceholderPage(title: "Privacy Policy"),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text("Share This App"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlaceholderPage(title: "Share This App"),
                ),
              );
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade200,
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }
}

// Placeholder Page for navigation targets
class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF0F1A54),
      ),
      body: Center(
        child: Text('$title Page', style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
