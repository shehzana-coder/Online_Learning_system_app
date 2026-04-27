import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🔥 Firebase import
import 'SignupScreen.dart';
import 'viewcoursesoption.dart'; // Adjust the path if needed
import 'teachers_otions_screen.dart'; // New import for teacher options

class LoginScreen extends StatefulWidget {
  final String userType; // Add userType parameter

  const LoginScreen({super.key, required this.userType});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isEmailValid(String email) {
    // Basic email format validation
    return RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);
  }

  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // Validation checks BEFORE hitting Firebase
    if (email.isEmpty) {
      _showError('Please enter your email.');
      return;
    }
    if (!_isEmailValid(email)) {
      _showError('Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      _showError('Please enter your password.');
      return;
    }
    if (password.length < 6) {
      _showError('Password must be at least 6 characters long.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Redirect based on user type
        if (widget.userType == 'teacher') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const TeacherOptionsScreen(),
            ),
          );
        } else {
          // For students, go directly to courses screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OptionCoursePage()),
          );
        }
      } else {
        _showError('Login failed. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password. Please try again.';
      } else {
        message = 'Login failed. Please check your credentials.';
      }

      _showError(message);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/4.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.deepPurple.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${widget.userType.capitalize()} Login',
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Log in to your account',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    const SizedBox(height: 40),

                    _buildTextField(
                      icon: Icons.person,
                      hint: 'Email',
                      controller: _emailController,
                    ),

                    const SizedBox(height: 20),

                    _buildTextField(
                      icon: Icons.lock,
                      hint: 'Password',
                      controller: _passwordController,
                      obscure: true,
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              activeColor: Colors.white,
                              checkColor: Colors.deepPurple,
                            ),
                            const Text(
                              'Remember me',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            // Forgot password logic
                          },
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 10,
                        shadowColor: Colors.black,
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.deepPurple,
                                ),
                              )
                              : const Text(
                                'Log in',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      '........ Or Login with ........',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialIcon('assets/images/9.png'),
                        const SizedBox(width: 20),
                        _buildSocialIcon('assets/images/10.png'),
                        const SizedBox(width: 20),
                        _buildSocialIcon('assets/images/11.png'),
                      ],
                    ),

                    const SizedBox(height: 25),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Signup',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(String assetPath) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      radius: 20,
      child: Image.asset(assetPath, width: 24, height: 24),
    );
  }
}

// Extension to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
