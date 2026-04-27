import 'package:flutter/material.dart';
import 'Filterhomescreencourses.dart'; // Import the home screen

class CreateProfileScreen extends StatefulWidget {
  @override
  _CreateProfileScreenState createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _selectedGender;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  "assets/images/3.png",
                ), // Add your background image to assets
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Gradient overlay
          Container(color: Colors.black.withOpacity(0.6)),

          // Form
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      "Create Your Profile",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(height: 30),

                    _buildTextField(
                      "Name",
                      _nameController,
                      "Please enter your name",
                    ),
                    _buildTextField(
                      "User name",
                      _usernameController,
                      "Please enter a username",
                    ),
                    _buildGenderDropdown(),
                    _buildTextField(
                      "Phone Number",
                      _phoneController,
                      "Please enter your phone number",
                      isPhone: true,
                    ),
                    _buildTextField(
                      "Email",
                      _emailController,
                      "Please enter a valid email",
                      isEmail: true,
                    ),

                    SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Profile created successfully!"),
                              duration: Duration(
                                seconds: 1,
                              ), // Short duration so it doesn't stay too long
                            ),
                          );

                          // Navigate to the home page after a short delay
                          Future.delayed(Duration(milliseconds: 1200), () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const LearningPartnerPage(), // Assuming LearningPartnerPage is your home screen
                              ),
                            );
                          });
                        }
                      },
                      child: Text("Save"),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String errorMsg, {
    bool isEmail = false,
    bool isPhone = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return errorMsg;
          }
          if (isEmail && !RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
            return 'Please enter a valid email';
          }
          if (isPhone && !RegExp(r'^\+?\d{10,15}$').hasMatch(value)) {
            return 'Enter valid phone number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        value: _selectedGender,
        dropdownColor: Colors.black87,
        decoration: InputDecoration(
          labelText: 'Gender',
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        style: TextStyle(color: Colors.white),
        items:
            ['Male', 'Female', 'Other']
                .map(
                  (gender) => DropdownMenuItem(
                    value: gender.toLowerCase(),
                    child: Text(gender),
                  ),
                )
                .toList(),
        onChanged: (value) {
          setState(() {
            _selectedGender = value;
          });
        },
        validator: (value) => value == null ? 'Please select a gender' : null,
      ),
    );
  }
}
