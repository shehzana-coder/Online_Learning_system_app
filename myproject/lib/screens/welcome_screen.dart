import 'package:flutter/material.dart';
import 'login_selection_screen.dart'; // Ensure this file contains the LoginScreen class
import 'SignupScreen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B0742), Color(0xFF1D2671)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // 💧 Golden splash background
            Positioned.fill(
              child: Image.asset(
                'assets/images/7.png',
                fit: BoxFit.cover,
                opacity: AlwaysStoppedAnimation(0.2),
              ),
            ),

            // Existing small droplets
            Positioned(
              top: 100,
              left: 20,
              child: Image.asset('assets/images/6.png', width: 40),
            ),
            Positioned(
              top: 400,
              right: 30,
              child: Image.asset('assets/images/6.png', width: 30),
            ),
            Positioned(
              bottom: 150,
              left: 50,
              child: Image.asset('assets/images/6.png', width: 25),
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/8.png', width: 200),
                  const SizedBox(height: 20),
                  const Text(
                    "TeachUp",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                    child: Text(
                      "Discover knowledgeable tutors near you with ease. Connect with qualified educators effortlessly.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Log In Button (matching Sign Up button size)
                  SizedBox(
                    width: 250,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginSelectionScreen(),
                          ),
                        );
                      },

                      style: ElevatedButton.styleFrom(
                        foregroundColor: const Color(0xFF1D2671),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        "Log In",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sign Up Button (matching Log In button size)
                  SizedBox(
                    width: 250,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
