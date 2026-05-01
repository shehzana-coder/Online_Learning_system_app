import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'changepassword.dart';
import 'tutorhomescreen.dart';
import 'togglebutton.dart';
import 'package:myproject/privacypolicy.dart';
import 'package:myproject/termsandcondition.dart';
import 'package:myproject/aboutmyapp.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final Function(bool)? toggleTheme; // Optional callback for theme toggle

  const ProfileSettingsScreen({super.key, this.toggleTheme});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _semesterController = TextEditingController();

  bool _isDarkMode = false;
  String _selectedLanguage = 'English';
  File? _selectedImage;
  String? _profileImageUrl;
  bool _isLoading = false;
  bool _isEditing = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadThemePreference();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _studentIdController.dispose();
    _departmentController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  // Load theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  // Toggle theme and save preference
  Future<void> _toggleTheme(bool isDark) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);

    setState(() {
      _isDarkMode = isDark;
    });

    // Call the theme toggle callback if provided
    if (widget.toggleTheme != null) {
      widget.toggleTheme!(isDark);
    }

    // Also save to Firestore for sync across devices
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('students').doc(user.uid).update({
          'isDarkMode': isDark,
        });
      }
    } catch (e) {
      print('Error saving theme preference to Firestore: $e');
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('students').doc(user.uid).get();

        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _emailController.text = data['email'] ?? user.email ?? '';
            _phoneController.text = data['phone'] ?? '';
            _studentIdController.text = data['studentId'] ?? '';
            _departmentController.text = data['department'] ?? '';
            _semesterController.text = data['semester'] ?? '';
            _selectedLanguage = data['language'] ?? 'English';
            _profileImageUrl = data['profileImageUrl'];

            // Load dark mode from Firestore if available
            if (data.containsKey('isDarkMode')) {
              _isDarkMode = data['isDarkMode'] ?? false;
            }
          });
        } else {
          _emailController.text = user.email ?? '';
        }
      }
    } catch (e) {
      _showSnackBar('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _profileImageUrl;

    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final ref =
          _storage.ref().child('profile_images').child('${user.uid}.jpg');
      await ref.putFile(_selectedImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      _showSnackBar('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showSnackBar('User not authenticated');
        return;
      }

      String? imageUrl = await _uploadImage();

      final studentData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'studentId': _studentIdController.text.trim(),
        'department': _departmentController.text.trim(),
        'semester': _semesterController.text.trim(),
        'isDarkMode': _isDarkMode,
        'language': _selectedLanguage,
        'profileImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': user.uid,
      };

      await _firestore.collection('students').doc(user.uid).set(
            studentData,
            SetOptions(merge: true),
          );

      setState(() {
        _isEditing = false;
        _profileImageUrl = imageUrl;
        _selectedImage = null;
      });

      _showSnackBar('Profile updated successfully!');
    } catch (e) {
      _showSnackBar('Error saving profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final headerColor =
        isDark ? Colors.grey[850] : const Color.fromARGB(255, 255, 144, 187);
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                Container(
                  color: headerColor,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: textColor),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TutorScreen(),
                            ),
                          );
                        },
                      ),
                      Text(
                        "Profile",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const Spacer(),
                      if (_isEditing)
                        TextButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          child: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        textColor),
                                  ),
                                )
                              : Text(
                                  'Save',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      IconButton(
                        icon: Icon(
                          _isEditing ? Icons.close : Icons.edit,
                          color: textColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _isEditing = !_isEditing;
                            if (!_isEditing) {
                              _loadUserData();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Profile Image with Edit Icon
                GestureDetector(
                  onTap: _isEditing ? _pickImage : null,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : _profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : const AssetImage('') as ImageProvider,
                      ),
                      if (_isEditing)
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: backgroundColor,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: Color.fromARGB(255, 255, 144, 187),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Personal Information Section
                _sectionTitle("Personal Information"),

                if (_isEditing) ...[
                  _buildEditableField(
                    controller: _nameController,
                    label: "Full Name",
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  _buildEditableField(
                    controller: _emailController,
                    label: "Email",
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  _buildEditableField(
                    controller: _phoneController,
                    label: "Phone Number",
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  _buildEditableField(
                    controller: _studentIdController,
                    label: "Student ID",
                    icon: Icons.badge,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Student ID is required';
                      }
                      return null;
                    },
                  ),
                  _buildEditableField(
                    controller: _departmentController,
                    label: "Department",
                    icon: Icons.school,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Department is required';
                      }
                      return null;
                    },
                  ),
                  _buildEditableField(
                    controller: _semesterController,
                    label: "Semester",
                    icon: Icons.calendar_today,
                  ),
                ] else ...[
                  _buildDisplayField(
                      "Name", _nameController.text, Icons.person),
                  _buildDisplayField(
                      "Email", _emailController.text, Icons.email),
                  if (_phoneController.text.isNotEmpty)
                    _buildDisplayField(
                        "Phone", _phoneController.text, Icons.phone),
                  if (_studentIdController.text.isNotEmpty)
                    _buildDisplayField(
                        "Student ID", _studentIdController.text, Icons.badge),
                  if (_departmentController.text.isNotEmpty)
                    _buildDisplayField(
                        "Department", _departmentController.text, Icons.school),
                  if (_semesterController.text.isNotEmpty)
                    _buildDisplayField("Semester", _semesterController.text,
                        Icons.calendar_today),
                ],

                // App Settings Section
                _sectionTitle("App Settings"),

                ListTile(
                  leading: IconButton(
                    icon: Icon(Icons.dark_mode, color: textColor),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ThemeToggleScreen(),
                        ),
                      );
                    },
                  ),
                  title: Text("Dark Mode", style: TextStyle(color: textColor)),
                  trailing: Switch(
                    value: _isDarkMode,
                    onChanged: _toggleTheme,
                    activeColor: const Color.fromARGB(255, 255, 144, 187),
                  ),
                ),

                ListTile(
                  tileColor: backgroundColor,
                  leading: Icon(Icons.language, color: textColor),
                  title: Text("Language", style: TextStyle(color: textColor)),
                  subtitle: Text(_selectedLanguage,
                      style: TextStyle(color: textColor.withOpacity(0.7))),
                  trailing: _isEditing
                      ? DropdownButton<String>(
                          dropdownColor: backgroundColor,
                          value: _selectedLanguage,
                          items:
                              ['English', 'Spanish', 'French', 'German', 'Urdu']
                                  .map((lang) => DropdownMenuItem(
                                        value: lang,
                                        child: Text(lang,
                                            style: TextStyle(color: textColor)),
                                      ))
                                  .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedLanguage = value);
                            }
                          },
                        )
                      : Icon(Icons.arrow_forward_ios,
                          size: 16, color: textColor),
                ),

                ListTile(
                  leading: Icon(Icons.vpn_key, color: textColor),
                  title: Text("Change Password",
                      style: TextStyle(color: textColor)),
                  trailing:
                      Icon(Icons.arrow_forward_ios, size: 16, color: textColor),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),

                // Information Section
                _sectionTitle("Information"),
                ListTile(
                  leading: Icon(Icons.phone_android, color: textColor),
                  title: Text("About App", style: TextStyle(color: textColor)),
                  trailing:
                      Icon(Icons.arrow_forward_ios, size: 16, color: textColor),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.description, color: textColor),
                  title: Text("Terms & Conditions",
                      style: TextStyle(color: textColor)),
                  trailing:
                      Icon(Icons.arrow_forward_ios, size: 16, color: textColor),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsConditionsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.privacy_tip, color: textColor),
                  title: Text("Privacy Policy",
                      style: TextStyle(color: textColor)),
                  trailing:
                      Icon(Icons.arrow_forward_ios, size: 16, color: textColor),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: textColor),
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color.fromARGB(255, 255, 144, 187)),
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayField(String label, String value, IconData icon) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(label, style: TextStyle(color: textColor)),
      subtitle: Text(
        value.isEmpty ? 'Not provided' : value,
        style: TextStyle(color: textColor.withOpacity(0.7)),
      ),
    );
  }

  Widget _buildNavigationTile(IconData icon, String title) {
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: textColor),
      onTap: () {
        _showSnackBar('$title clicked');
      },
    );
  }
}
