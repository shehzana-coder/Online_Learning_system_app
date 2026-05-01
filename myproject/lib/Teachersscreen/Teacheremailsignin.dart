// ignore_for_file: library_private_types_in_public_api

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myproject/studentsscreens/changepassword.dart';
import 'package:myproject/ADMINSCREENS/adminscreen1.dart';
import 'package:myproject/verifiedteachers/homescreen.dart';

class Teacheremailsignin extends StatefulWidget {
  const Teacheremailsignin({Key? key}) : super(key: key);

  @override
  State<Teacheremailsignin> createState() => _TeacheremailsigninState();
}

class _TeacheremailsigninState extends State<Teacheremailsignin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> _checkIfAdmin(String email, String password) async {
    try {
      DocumentSnapshot adminDoc =
          await _firestore.collection('Adminpasswords').doc('1').get();

      if (adminDoc.exists) {
        final data = adminDoc.data() as Map<String, dynamic>?;
        if (data != null &&
            data['email'] == email &&
            data['password'] == password) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking admin credentials: $e');
      return false;
    }
  }

  Future<bool> _checkIfVerifiedTeacher(String email) async {
    try {
      QuerySnapshot teacherQuery = await _firestore
          .collection('teachers')
          .where('about.email', isEqualTo: email)
          .get();
      return teacherQuery.docs.isNotEmpty;
    } catch (e) {
      print('Error checking teacher verification: $e');
      return false;
    }
  }

  void _signInWithEmail() async {
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email and password must not be empty',
              style: GoogleFonts.poppins()),
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      bool isAdmin = await _checkIfAdmin(email, password);
      if (isAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome Admin!', style: GoogleFonts.poppins()),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
        return;
      }

      await _auth.signInWithEmailAndPassword(email: email, password: password);

      bool isVerifiedTeacher = await _checkIfVerifiedTeacher(email);
      if (isVerifiedTeacher) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome Teacher!', style: GoogleFonts.poppins()),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TutorScreen()),
        );
        return;
      }

      await _auth.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'You are not verified. Please contact the administrator.',
              style: GoogleFonts.poppins()),
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'user-not-found':
          errorMsg = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMsg = 'Wrong password provided.';
          break;
        case 'invalid-email':
          errorMsg = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMsg = 'This account has been disabled.';
          break;
        default:
          errorMsg = 'Authentication failed: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg, style: GoogleFonts.poppins()),
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign in failed. Please try again.',
              style: GoogleFonts.poppins()),
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sign in',
                  style: GoogleFonts.poppins(
                      fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Teacher or Admin Login',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                Text('Email', style: GoogleFonts.poppins(fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter email address',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey),
                    prefixIcon: Icon(Icons.email, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.0),
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 255, 144, 187), width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.0),
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 255, 144, 187), width: 2),
                    ),
                  ),
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 20),
                Text('Password', style: GoogleFonts.poppins(fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter password',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey),
                    prefixIcon: Icon(Icons.lock, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.0),
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 255, 144, 187), width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6.0),
                      borderSide: BorderSide(
                          color: Color.fromARGB(255, 255, 144, 187), width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signInWithEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 144, 187),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      side: BorderSide(
                        color: Colors.transparent,
                        width: 2,
                      ),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith<Color?>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.focused)) {
                            return Color.fromARGB(255, 255, 144, 187)
                                .withOpacity(0.2);
                          }
                          return null;
                        },
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : Text(
                            'Sign In',
                            style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Forgot your password?',
                      style: GoogleFonts.poppins(
                          color: Colors.black87, fontWeight: FontWeight.w500),
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
}
