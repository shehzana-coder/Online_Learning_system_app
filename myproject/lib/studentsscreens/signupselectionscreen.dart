import 'package:flutter/material.dart';
import 'package:myproject/Teachersscreen/teachersignup.dart';
import 'studentsignupscreen.dart'; // Import the student signup screen
import 'ssigninselectionscreen.dart'; // Import the sign-in screen

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  static const routeName = '/signup';

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isStudent = true; // Default selection

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color.fromARGB(255, 255, 144, 187), // Pink background color
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Logo
                Row(
                  children: [
                    // Image logo instead of custom painter
                    Image.asset(
                      'assets/images/logo.png', // Make sure to add this asset to your pubspec.yaml
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'speakora',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                // Main Heading
                const Text(
                  'Empower\nyour\nSkills.',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                // Subtitle
                Text(
                  'Mastering language course is the first step to mastering global opportunities.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 60),
                // Sign Up Options
                _buildSignInButton(
                  title: 'Signup as a Tutor',
                  isSelected: !_isStudent,
                  onTap: () {
                    setState(() {
                      _isStudent = false;
                    });
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TeacherSignUpScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildSignInButton(
                  title: 'Signup as a Student',
                  isSelected: _isStudent,
                  onTap: () {
                    setState(() {
                      _isStudent = true;
                    });
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const StudentSignupScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Log in link
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SelectionScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.arrow_forward,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
