import 'package:flutter/material.dart';
import '/COURSES/addcourses.dart'; // Create this file for the form to add courses
import 'allcourses.dart';

class TeacherOptionsScreen extends StatelessWidget {
  const TeacherOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/4.png', // You can use a different image if desired
              fit: BoxFit.cover,
            ),
          ),

          // Container with purple overlay
          Positioned.fill(
            child: Container(
              color: Colors.deepPurple.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Teacher Portal',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Select an option to continue',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),

                const SizedBox(height: 50),

                // Option buttons
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Add Course Button
                        _buildOptionButton(
                          context,
                          'Add New Course',
                          Icons.add_circle_outline,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TeacherAddForm(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 25),

                        // Go to Home Screen Button
                        _buildOptionButton(
                          context,
                          'View Courses',
                          Icons.home,
                          () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const FullCoursePage(isTeacher: true),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 25),

                        // View Students Button
                        _buildOptionButton(
                          context,
                          'View Students',
                          Icons.people,
                          () {
                            // Add navigation to student list screen
                            // You'll need to create this screen
                          },
                        ),

                        const SizedBox(height: 25),

                        // Logout Button
                        TextButton.icon(
                          onPressed: () {
                            // Handle logout
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text(
                            'Logout',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: 300,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.deepPurple,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 10,
          shadowColor: Colors.black,
        ),
        icon: Icon(icon, size: 24),
        label: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
