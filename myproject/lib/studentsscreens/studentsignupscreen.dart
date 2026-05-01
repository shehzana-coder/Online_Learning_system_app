import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'findtutor.dart';

class StudentSignupScreen extends StatefulWidget {
  const StudentSignupScreen({Key? key}) : super(key: key);

  @override
  State<StudentSignupScreen> createState() => _StudentSignupScreenState();
}

class _StudentSignupScreenState extends State<StudentSignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  Future<void> _saveStudentToFirestore(User user, String name) async {
    try {
      final batch = _firestore.batch();

      final userRef = _firestore.collection('users').doc(user.uid);
      batch.set(userRef, {
        'uid': user.uid,
        'name': name,
        'email': user.email,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      final studentRef = _firestore.collection('students').doc(user.uid);
      batch.set(studentRef, {
        'uid': user.uid,
        'name': name,
        'email': user.email,
        'userType': 'student',
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'profileComplete': false,
        'isActive': true,
        'enrolledCourses': [],
        'preferredSubjects': [],
        'learningGoals': '',
        'profileImageUrl': '',
        'phoneNumber': '',
        'dateOfBirth': null,
        'address': '',
        'educationLevel': '',
        'institution': '',
        'preferredTutorGender': '',
        'preferredLanguage': 'English',
        'availabilitySchedule': {},
        'budget': {'min': 0, 'max': 0, 'currency': 'USD'},
        'completedSessions': 0,
        'totalHoursLearned': 0,
        'averageRating': 0.0,
        'achievements': [],
        'notificationSettings': {'email': true, 'push': true, 'sms': false},
      });

      await batch.commit();
    } catch (e) {
      print('Error saving student data: $e');
      throw Exception('Failed to save student data');
    }
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final passwordRegex =
        RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[\W_]).{8,}$');

    if (name.isEmpty || name.length < 2) {
      _showErrorDialog('Name must be at least 2 characters.');
      return;
    }
    if (!emailRegex.hasMatch(email)) {
      _showErrorDialog('Please enter a valid email address.');
      return;
    }
    if (!passwordRegex.hasMatch(password)) {
      _showErrorDialog(
          'Password must be 8+ characters, include uppercase, lowercase, number, and special character.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final existingStudent = await _firestore
          .collection('students')
          .where('email', isEqualTo: email)
          .get();

      if (existingStudent.docs.isNotEmpty) {
        _showErrorDialog('An account with this email already exists.');
        setState(() => _isLoading = false);
        return;
      }

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await userCredential.user?.updateDisplayName(name);
      await _saveStudentToFirestore(userCredential.user!, name);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Account created successfully!'),
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FindTutorScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(
          'Signup failed: ${e.message ?? 'Unknown error occurred'}');
    } catch (e) {
      _showErrorDialog('An unexpected error occurred. Please try again.');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Join our learning community and find amazing tutors',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromRGBO(77, 77, 77, 1),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 30),
                _buildTextField('Name', 'Enter your name', _nameController),
                const SizedBox(height: 20),
                _buildTextField(
                    'Email', 'Enter email address', _emailController,
                    inputType: TextInputType.emailAddress),
                const SizedBox(height: 20),
                _buildPasswordField(),
                const SizedBox(height: 8),
                const Text(
                  'Password must contain: uppercase, lowercase, number, and special character',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 144, 187),
                      padding: const EdgeInsets.symmetric(
                          vertical: 17, horizontal: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ).copyWith(
                      side: MaterialStateProperty.resolveWith<BorderSide>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.focused)) {
                            return const BorderSide(
                                color: Color.fromARGB(255, 255, 144, 187));
                          }
                          return const BorderSide(color: Colors.grey);
                        },
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              fontFamily: 'Poppins',
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

  Widget _buildTextField(
      String label, String hint, TextEditingController controller,
      {TextInputType inputType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: inputType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color.fromARGB(255, 255, 144, 187)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
            prefixIcon: Icon(
              inputType == TextInputType.emailAddress
                  ? Icons.email_outlined
                  : Icons.person_outline,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color.fromARGB(255, 255, 144, 187)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
            prefixIcon: const Icon(Icons.lock_outlined, color: Colors.grey),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
