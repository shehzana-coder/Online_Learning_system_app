import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/studentsscreens/ssigninselectionscreen.dart'; // Replace with your actual dashboard screen
import 'Teacheremailsignin.dart';
import 'package:myproject/ADMINSCREENS/adminscreen1.dart';
import 'package:myproject/studentsscreens/tutorhomescreen.dart';

class TeacherSignInScreen extends StatelessWidget {
  const TeacherSignInScreen({super.key});

  // ✅ Check if user is admin by verifying credentials
  Future<bool> checkAdminCredentials(String email, String password) async {
    try {
      // Query Firestore to check if user exists with admin password
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection(
              'Adminpasswords') // Assuming admins are stored in 'admins' collection
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      return result.docs.isNotEmpty;
    } catch (e) {
      print('Error checking admin credentials: $e');
      return false;
    }
  }

  // ✅ Email Sign-In with Admin Check
  Future<void> signInWithEmailAndPassword(
      BuildContext context, String email, String password) async {
    try {
      // First, check if user is admin
      bool isAdmin = await checkAdminCredentials(email, password);

      if (isAdmin) {
        // Sign in with Firebase Auth for admin
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Navigate to admin dashboard or appropriate screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  AdminDashboardScreen()), // Replace with your admin screen
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome Admin!')),
        );
      } else {
        // Check if user is faculty/teacher
        // ignore: unused_local_variable
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Navigate to teacher/tutor screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TutorScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome Faculty!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: ${e.toString()}')),
      );
    }
  }

  // ✅ Google Sign-In Function with Admin Check
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // Cancelled by user

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      String userEmail = userCredential.user?.email ?? '';

      // Check if Google user is admin (you might need to check by email only for Google sign-in)
      bool isAdmin = await checkAdminByEmail(userEmail);

      if (isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  AdminDashboardScreen()), // Replace with your admin screen
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome Admin!')),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TutorScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome Faculty!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: $e')),
      );
    }
  }

  // ✅ Check admin by email only (for Google sign-in)
  Future<bool> checkAdminByEmail(String email) async {
    try {
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('admins')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return result.docs.isNotEmpty;
    } catch (e) {
      print('Error checking admin by email: $e');
      return false;
    }
  }

  // ✅ Show Email/Password Dialog
  void showEmailPasswordDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sign In', style: GoogleFonts.poppins()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                signInWithEmailAndPassword(
                  context,
                  emailController.text.trim(),
                  passwordController.text.trim(),
                );
              },
              child: const Text('Sign In'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Good to see\nyou again.',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Get access to find the top English tutor today',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.email_outlined, color: Colors.black),
                  label: Text(
                    'Sign in with email',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    // Option 1: Use the existing email sign-in screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const Teacheremailsignin(),
                      ),
                    );

                    // Option 2: Use the dialog (uncomment to use this instead)
                    // showEmailPasswordDialog(context);
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.google,
                      color: Colors.black),
                  label: Text(
                    'Sign in with Google',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => signInWithGoogle(context),
                ),
              ),
              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SelectionScreen()),
                    );
                  },
                  child: Text(
                    'Sign up for new account',
                    style: GoogleFonts.poppins(
                      decoration: TextDecoration.underline,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ Placeholder for Admin Dashboard (replace with your actual admin screen)
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: const Center(
        child: Text('Welcome to Admin Dashboard!'),
      ),
    );
  }
}
