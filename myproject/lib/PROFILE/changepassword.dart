import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  bool _isLoading = false;

  // Password strength indicators
  double _passwordStrength = 0;
  String _passwordStrengthText = 'Weak';
  Color _passwordStrengthColor = Colors.red;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _changePassword() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      setState(() {
        _errorMessage = 'User not logged in.';
        _isLoading = false;
      });
      return;
    }

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      setState(() {
        _errorMessage = 'New passwords do not match.';
        _isLoading = false;
      });
      return;
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      if (mounted) {
        _showSuccessDialog();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An error occurred.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _checkPasswordStrength(String password) {
    // Simple password strength checker
    setState(() {
      if (password.isEmpty) {
        _passwordStrength = 0;
        _passwordStrengthText = 'Weak';
        _passwordStrengthColor = Colors.red;
        return;
      }

      double strength = 0;
      // Length check
      if (password.length >= 8) strength += 0.25;
      // Contains uppercase
      if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
      // Contains number
      if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
      // Contains special character
      if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')))
        strength += 0.25;

      _passwordStrength = strength;

      if (strength <= 0.25) {
        _passwordStrengthText = 'Weak';
        _passwordStrengthColor = Colors.red;
      } else if (strength <= 0.5) {
        _passwordStrengthText = 'Moderate';
        _passwordStrengthColor = Colors.orange;
      } else if (strength <= 0.75) {
        _passwordStrengthText = 'Good';
        _passwordStrengthColor = Colors.yellow.shade800;
      } else {
        _passwordStrengthText = 'Strong';
        _passwordStrengthColor = Colors.green;
      }
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Text('Success'),
              ],
            ),
            content: const Text('Your password has been updated successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to previous screen
                },
                child: const Text('OK', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() {
      _checkPasswordStrength(_newPasswordController.text);
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback toggle,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: Colors.grey),
      hintStyle: const TextStyle(color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF0F1A54), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      prefixIcon:
          prefixIcon != null ? Icon(prefixIcon, color: Colors.grey) : null,
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey,
        ),
        onPressed: toggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF0F1A54),
                    strokeWidth: 3,
                  ),
                )
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),
                          // Lock icon illustration
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F1A54).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_reset,
                              size: 50,
                              color: Color(0xFF0F1A54),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Title and description
                          const Text(
                            'Update Your Password',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F1A54),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a strong password that you don\'t use elsewhere',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),

                          // Form card
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 8,
                            shadowColor: Colors.black.withOpacity(0.1),
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.9,
                              padding: const EdgeInsets.all(24.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_errorMessage != null)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline,
                                              color: Colors.red,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                _errorMessage!,
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (_errorMessage != null)
                                      const SizedBox(height: 20),

                                    TextFormField(
                                      controller: _currentPasswordController,
                                      obscureText: _obscureCurrent,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      decoration: _inputDecoration(
                                        label: 'Current Password',
                                        hint: 'Enter your current password',
                                        obscure: _obscureCurrent,
                                        toggle:
                                            () => setState(
                                              () =>
                                                  _obscureCurrent =
                                                      !_obscureCurrent,
                                            ),
                                        prefixIcon: Icons.lock_outline,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your current password';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    TextFormField(
                                      controller: _newPasswordController,
                                      obscureText: _obscureNew,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      decoration: _inputDecoration(
                                        label: 'New Password',
                                        hint: 'Create a strong password',
                                        obscure: _obscureNew,
                                        toggle:
                                            () => setState(
                                              () => _obscureNew = !_obscureNew,
                                            ),
                                        prefixIcon: Icons.lock,
                                      ),
                                      validator: (value) {
                                        if (value == null || value.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 10),

                                    // Password strength indicator
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Password Strength: $_passwordStrengthText',
                                              style: TextStyle(
                                                color: _passwordStrengthColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              '${(_passwordStrength * 100).toInt()}%',
                                              style: TextStyle(
                                                color: _passwordStrengthColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        LinearProgressIndicator(
                                          value: _passwordStrength,
                                          backgroundColor: Colors.grey.shade200,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                _passwordStrengthColor,
                                              ),
                                          minHeight: 6,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Use 8+ characters with a mix of uppercase, lowercase, numbers & symbols',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      obscureText: _obscureConfirm,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      decoration: _inputDecoration(
                                        label: 'Confirm New Password',
                                        hint: 'Re-enter your new password',
                                        obscure: _obscureConfirm,
                                        toggle:
                                            () => setState(
                                              () =>
                                                  _obscureConfirm =
                                                      !_obscureConfirm,
                                            ),
                                        prefixIcon: Icons.lock_reset,
                                      ),
                                      validator: (value) {
                                        if (value !=
                                            _newPasswordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 30),

                                    // Update button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 55,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            _changePassword();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF0F1A54,
                                          ),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          elevation: 2,
                                        ),
                                        child: const Text(
                                          'Update Password',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Cancel button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 55,
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF0F1A54,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFF0F1A54),
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Security note
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.security, color: Colors.blue),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'After changing your password, you\'ll be logged out of all other devices.',
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}
