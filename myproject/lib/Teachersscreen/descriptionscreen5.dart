import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'educationscreen4.dart';
import 'videoportion6.dart'; // Adjust import path as needed

class ProfileDescriptionScreen extends StatefulWidget {
  final String id;
  const ProfileDescriptionScreen({super.key, required this.id});

  @override
  State<ProfileDescriptionScreen> createState() =>
      _ProfileDescriptionScreenState();
}

class _ProfileDescriptionScreenState extends State<ProfileDescriptionScreen> {
  final TextEditingController introController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController motivationController = TextEditingController();
  bool showExperienceSection = false;
  bool showMotivationSection = false;
  bool isLoading = false;
  bool isDataLoaded = false;

  // Keys for scrolling to sections
  final GlobalKey _experienceSectionKey = GlobalKey();
  final GlobalKey _motivationSectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    await _loadData();
    if (mounted) {
      setState(() {
        isDataLoaded = true;
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final descriptionJson = prefs.getString('description');
      if (descriptionJson != null) {
        final data = jsonDecode(descriptionJson);
        introController.text = data['intro'] ?? '';
        experienceController.text = data['experience'] ?? '';
        motivationController.text = data['motivation'] ?? '';
        if (mounted) {
          setState(() {
            showExperienceSection = introController.text.isNotEmpty;
            showMotivationSection =
                showExperienceSection && experienceController.text.isNotEmpty;
          });
        }
      }
    } catch (e) {
      _showError('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        ),
      );
    }
  }

  Future<void> _saveData({bool navigateToNext = false}) async {
    setState(() {
      isLoading = true;
    });

    try {
      if (navigateToNext) {
        if (introController.text.trim().isEmpty ||
            experienceController.text.trim().isEmpty ||
            motivationController.text.trim().isEmpty) {
          _showError('Please complete all sections before continuing');
          setState(() {
            isLoading = false;
          });
          return;
        }
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final descriptionData = {
        'intro': introController.text.trim(),
        'experience': experienceController.text.trim(),
        'motivation': motivationController.text.trim(),
      };
      await prefs.setString('description', jsonEncode(descriptionData));

      if (!mounted) return;

      if (navigateToNext) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoUploadScreen(id: widget.id),
          ),
        );
      }
    } catch (e) {
      _showError('Error saving data: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _handleTextChange(String text) {
    _debounceAutoSave();
  }

  Timer? _debounceTimer;

  void _debounceAutoSave() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      _saveData(navigateToNext: false);
    });
  }

  void _continueToExperienceSection() {
    if (introController.text.trim().isNotEmpty) {
      _saveData(navigateToNext: false);
      setState(() {
        showExperienceSection = true;
      });
      Future.delayed(
          const Duration(milliseconds: 100), _scrollToExperienceSection);
    } else {
      _showError('Please fill the introduction before continuing');
    }
  }

  void _continueToMotivationSection() {
    if (experienceController.text.trim().isNotEmpty) {
      _saveData(navigateToNext: false);
      setState(() {
        showMotivationSection = true;
      });
      Future.delayed(
          const Duration(milliseconds: 100), _scrollToMotivationSection);
    } else {
      _showError('Please fill the experience before continuing');
    }
  }

  void _scrollToExperienceSection() {
    Scrollable.ensureVisible(
      _experienceSectionKey.currentContext!,
      alignment: 0.3,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _scrollToMotivationSection() {
    Scrollable.ensureVisible(
      _motivationSectionKey.currentContext!,
      alignment: 0.3,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _saveData(navigateToNext: false);
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white, // Changed background color to white
        body: isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading...'),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      "Profile description",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 28),
                    ),
                    const SizedBox(height: 8),
                    Container(
                        height: 1,
                        color: Color.fromARGB(255, 255, 144, 187),
                        width: double.infinity),
                    const SizedBox(height: 20),
                    Text(
                      "This information will appear on your public profile. Please write it in the language you plan to teach, and follow our guidelines to ensure your profile gets approved.",
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "1. Introduce yourself",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Provide a brief introduction highlighting your teaching experience, dedication to education, and a few personal interests to help students connect with you.",
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    _buildTextArea(
                      hintText: "Enter your introduction here...",
                      controller: introController,
                      onChanged: _handleTextChange,
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: introController.text.trim().isEmpty
                              ? Colors.grey[300]
                              : const Color.fromARGB(255, 255, 144, 187),
                          foregroundColor: introController.text.trim().isEmpty
                              ? Colors.grey[600]
                              : Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _continueToExperienceSection,
                        child: Text("Continue", style: GoogleFonts.poppins()),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (showExperienceSection) ...[
                      Text(
                        "2. Teaching experience",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 18),
                        key: _experienceSectionKey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Provide a comprehensive overview of your teaching experience, highlighting your educational background, certifications, subject expertise, and instructional methods. Be sure to explain how your approach supports effective learning and student success.",
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      _buildTextArea(
                        hintText: "Enter your experience here...",
                        controller: experienceController,
                        onChanged: _handleTextChange,
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                experienceController.text.trim().isEmpty
                                    ? Colors.grey[300]
                                    : const Color.fromARGB(255, 255, 144, 187),
                            foregroundColor:
                                experienceController.text.trim().isEmpty
                                    ? Colors.grey[600]
                                    : Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _continueToMotivationSection,
                          child: Text("Continue", style: GoogleFonts.poppins()),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    if (showMotivationSection) ...[
                      Text(
                        "3. Motivate potential students",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 18),
                        key: _motivationSectionKey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Invite students to book their first lesson by emphasizing the value of your teaching approach and the benefits they can gain from learning with you.",
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      _buildTextArea(
                        hintText:
                            "e.g., Book your first lesson with me, and let's start your journey toward mastering math together!",
                        controller: motivationController,
                        onChanged: _handleTextChange,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              await _saveData(navigateToNext: false);
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EducationScreen(id: widget.id),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 255, 144, 187),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Colors.black),
                              ),
                            ),
                            child: Text(
                              'Back',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              _saveData(navigateToNext: true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 255, 144, 187),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Colors.black),
                              ),
                            ),
                            child: Text(
                              'Save and continue',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 100),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTextArea({
    required String hintText,
    required TextEditingController controller,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: 5,
      style: GoogleFonts.poppins(color: Colors.black, fontSize: 12),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: Color.fromARGB(255, 214, 207, 207)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide:
              BorderSide(color: Color.fromARGB(255, 255, 144, 187), width: 2),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  void dispose() {
    introController.dispose();
    experienceController.dispose();
    motivationController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
