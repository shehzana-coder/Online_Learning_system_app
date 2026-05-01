// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'aboutinfo1.dart';

class TeacherSignUpScreen extends StatefulWidget {
  const TeacherSignUpScreen({super.key});

  @override
  _TeacherSignUpScreenState createState() => _TeacherSignUpScreenState();
}

class _TeacherSignUpScreenState extends State<TeacherSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    final email = value.trim().toLowerCase();
    if (!EmailValidator.validate(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<bool> _checkEmailExists(String email) async {
    try {
      final notVerifiedQuery = await _firestore
          .collection('teachers_not_verified')
          .where('aboutInfo.email', isEqualTo: email)
          .get();

      final verifiedQuery = await _firestore
          .collection('teachers')
          .where('aboutInfo.email', isEqualTo: email)
          .get();

      return notVerifiedQuery.docs.isNotEmpty || verifiedQuery.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email existence: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _initializeTeacherInDatabase(
      UserCredential userCredential) async {
    try {
      final String uid = userCredential.user!.uid;
      final String email = _emailController.text.trim().toLowerCase();
      final String name = _nameController.text.trim();

      final nameParts = name.split(' ');
      final String firstName = nameParts.first;
      final String lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      final Map<String, dynamic> teacherData = {
        'uid': uid,
        'aboutInfo': {
          'firstName': firstName,
          'lastName': lastName,
          'country': null,
          'email': email,
          'phoneNumber': null,
          'teachingCourse': null,
        },
        'profilePhotoUrl': null,
        'certifications': [],
        'education': [],
        'description': {
          'intro': null,
          'experience': null,
          'motivation': null,
        },
        'videoUrl': null,
        'availability': {
          'timezone': null,
          'days': {
            'Monday': {'enabled': false, 'slots': []},
            'Tuesday': {'enabled': false, 'slots': []},
            'Wednesday': {'enabled': false, 'slots': []},
            'Thursday': {'enabled': false, 'slots': []},
            'Friday': {'enabled': false, 'slots': []},
            'Saturday': {'enabled': false, 'slots': []},
            'Sunday': {'enabled': false, 'slots': []},
          },
        },
        'pricing': {
          'standardRate': null,
          'introRate': null,
        },
        'status': 'not_verified',
        'emailVerified': userCredential.user!.emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'emailVerificationSentAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('teachers_not_verified')
          .doc(uid)
          .set(teacherData);

      await _firestore.collection('admin_logs').add({
        'action': 'teacher_registration',
        'teacherId': uid,
        'teacherEmail': email,
        'teacherName': name,
        'phoneNumber': null,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'not_verified',
        'details': 'New teacher registered, awaiting verification',
      });
    } catch (e) {
      throw e;
    }
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _emailController.text.trim().toLowerCase();
        final emailExists = await _checkEmailExists(email);
        if (emailExists) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'An account already exists with this email.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }

        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: email,
          password: _passwordController.text.trim(),
        );

        await userCredential.user!
            .updateDisplayName(_nameController.text.trim());
        await _initializeTeacherInDatabase(userCredential);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        final nameParts = _nameController.text.trim().split(' ');
        final String firstName = nameParts.first;
        final String lastName =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

        await prefs.setString('teacherId', userCredential.user!.uid);
        await prefs.setString('accountStatus', 'not_verified');

        await prefs.setString('aboutInfo.firstName', firstName);
        await prefs.setString('aboutInfo.lastName', lastName);
        await prefs.setString('aboutInfo.country', '');
        await prefs.setString('aboutInfo.email', _emailController.text.trim());
        await prefs.setString('aboutInfo.phoneNumber', '');
        await prefs.setString('aboutInfo.teachingCourse', '');

        await prefs.setString('profilePhotoUrl', '');

        await prefs.setStringList('certifications', []);

        await prefs.setStringList('education', []);

        await prefs.setString('description.intro', '');
        await prefs.setString('description.experience', '');
        await prefs.setString('description.motivation', '');

        await prefs.setString('videoUrl', '');

        await prefs.setString('availability.timezone', '');
        const days = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ];
        for (String day in days) {
          await prefs.setBool('availability.days.$day.enabled', false);
          await prefs.setStringList('availability.days.$day.slots', []);
        }

        await prefs.setDouble('pricing.standardRate', 0.0);
        await prefs.setDouble('pricing.introRate', 0.0);

        await userCredential.user!.sendEmailVerification();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account created successfully! Please check your email for verification and complete your profile.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            duration: Duration(seconds: 4),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AboutTutorForm(
              id: userCredential.user!.uid,
              firstName: firstName,
              lastName: lastName,
              email: _emailController.text.trim(),
            ),
          ),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'An error occurred. Please try again.';
        switch (e.code) {
          case 'weak-password':
            errorMessage = 'The password provided is too weak.';
            break;
          case 'email-already-in-use':
            errorMessage = 'An account already exists with this email.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is not valid.';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Email/password accounts are not enabled.';
            break;
          default:
            errorMessage = e.message ?? 'An error occurred during sign up.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: GoogleFonts.poppins()),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            duration: Duration(seconds: 4),
          ),
        );
      } catch (e) {
        print('Error during sign up: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'An unexpected error occurred. Please try again.',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
            ),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      32,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: Colors.black, size: 28),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Sign up',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 26),
                      Text(
                        'Name',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.poppins(
                            fontSize: 16, color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Enter your name',
                          hintStyle: GoogleFonts.poppins(
                              fontSize: 16, color: Colors.grey[500]),
                          prefixIcon: Icon(Icons.person, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: const Color.fromARGB(255, 255, 144, 187),
                                width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 18),
                          filled: true,
                          fillColor: Color.fromARGB(255, 255, 255, 255),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 26),
                      Text(
                        'Email',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.poppins(
                            fontSize: 16, color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Enter email address',
                          hintStyle: GoogleFonts.poppins(
                              fontSize: 16, color: Colors.grey[500]),
                          prefixIcon: Icon(Icons.email, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 255, 144, 187),
                                width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 18),
                          filled: true,
                          fillColor: const Color.fromARGB(255, 255, 255, 255),
                        ),
                        validator: _validateEmail,
                      ),
                      SizedBox(height: 26),
                      Text(
                        'Password',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: GoogleFonts.poppins(
                            fontSize: 16, color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          hintStyle: GoogleFonts.poppins(
                              fontSize: 16, color: Colors.grey[500]),
                          prefixIcon: Icon(Icons.lock, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 255, 144, 187),
                                width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 18),
                          filled: true,
                          fillColor: const Color.fromARGB(255, 255, 255, 255),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Color.fromARGB(255, 255, 144, 187),
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      Expanded(child: Container()),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF90BB),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            side: BorderSide(
                              color: Colors.transparent, // Default border
                              width: 2,
                            ),
                          ).copyWith(
                            // Add focus border using overlayColor
                            overlayColor:
                                WidgetStateProperty.resolveWith<Color?>(
                              (Set<WidgetState> states) {
                                if (states.contains(WidgetState.focused)) {
                                  return Colors.pink.withOpacity(
                                      0.2); // Pink focus border effect
                                }
                                return null;
                              },
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(255, 255, 144, 187)),
                                  ),
                                )
                              : Text(
                                  'Sign up',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
