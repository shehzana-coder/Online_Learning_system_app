import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '/studentsscreens/ssigninselectionscreen.dart'; // Replace with your actual dashboard screen

class ThankYouScreen extends StatefulWidget {
  final String id; // Firebase UID
  const ThankYouScreen({super.key, required this.id});

  @override
  State<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends State<ThankYouScreen> {
  Timer? _timer;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _saveTeacherData();
  }

  Future<void> _saveTeacherData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Retrieve data from SharedPreferences
      final profilePhoto = prefs.getString('photo_url');
      final certificationsList = prefs.getStringList('certifications');
      final educationList = prefs.getStringList('education');
      final descriptionJson = prefs.getString('description');
      final videoJson = prefs.getString('video');
      final availabilityJson = prefs.getString('availability');
      final pricingJson = prefs.getString('pricing');
      final teachingCourse = prefs.getString('teachingCourse');
      final languagesList = prefs.getStringList('languages');

      // Parse JSON data
      final certifications = certificationsList ?? [];
      final education = educationList ?? [];
      final description =
          descriptionJson != null ? jsonDecode(descriptionJson) : {};
      final video = videoJson != null ? jsonDecode(videoJson) : {};
      final availability =
          availabilityJson != null ? jsonDecode(availabilityJson) : {};
      final pricing = pricingJson != null ? jsonDecode(pricingJson) : {};

      // Parse languages
      final languages = languagesList != null
          ? languagesList
              .map((jsonString) =>
                  jsonDecode(jsonString) as Map<String, dynamic>)
              .map((data) => {
                    'language': data['language'] as String,
                    'level': data['level'] as String
                  })
              .toList()
          : [];

      final teacherData = {
        'uid': widget.id,
        'about': {
          'firstName': prefs.getString('signup_firstName') ?? '',
          'lastName': prefs.getString('signup_lastName') ?? '',
          'country': prefs.getString('country') ?? '',
          'email': prefs.getString('signup_email') ?? '',
          'phoneNumber': prefs.getString('phoneNumber') ?? '',
          'teachingCourse': teachingCourse ?? '',
          'languages': languages,
        },
        'profilePhoto': {
          'profilePhotoUrl': profilePhoto ?? '',
        },
        'certifications': certifications.map((certJson) {
          final cert = jsonDecode(certJson) as Map<String, dynamic>;
          return {
            'subject': cert['subject'] ?? '',
            'certification': cert['certification'] ?? '',
            'description': cert['description'] ?? '',
            'issuedBy': cert['issuedBy'] ?? '',
            'startYear': cert['startYear'] ?? '',
            'endYear': cert['endYear'] ?? '',
            'fileName': cert['fileName'] ?? '',
            'fileUrl': cert['fileUrl'] ?? '',
          };
        }).toList(),
        'education': education.map((eduJson) {
          final edu = jsonDecode(eduJson) as Map<String, dynamic>;
          return {
            'university': edu['university'] ?? '',
            'degree': edu['degree'] ?? '',
            'degree_type': edu['degree_type'] ?? '',
            'specialization': edu['specialization'] ?? '',
            'start_year': edu['start_year'] ?? '',
            'end_year': edu['end_year'] ?? '',
            'file_name': edu['file_name'] ?? '',
            'file_url': edu['file_url'] ?? '',
          };
        }).toList(),
        'description': {
          'intro': description['intro'] ?? '',
          'experience': description['experience'] ?? '',
          'motivation': description['motivation'] ?? '',
        },
        'video': {
          'videoUrl': video['video_url'] ?? '',
        },
        'availability': {
          'timezone': availability['timezone'] ?? '',
          'days': availability['days'] ?? {},
        },
        'pricing': {
          'standardRate': pricing['standardRate'] ?? 0.0,
          'introRate': pricing['introRate'],
        },
      };

      // Save to teachers_not_verified collection
      await _firestore
          .collection('teachers_not_verified')
          .doc(widget.id)
          .set(teacherData, SetOptions(merge: true));

      // Save essential fields to teachers_not_verified collection
      await _firestore.collection('teachers_not_verified').doc(widget.id).set({
        'uid': widget.id,
        'email':
            (teacherData['about'] as Map<String, dynamic>?)?['email'] ?? '',
        'about': teacherData['about'],
        'description': teacherData['description'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Extract email and name for logging
      final about = teacherData['about'] as Map<String, dynamic>? ?? {};
      final email = about['email'] ?? '';
      final name = '${about['firstName'] ?? ''} ${about['lastName'] ?? ''}';

      // Log profile completion
      await _firestore.collection('admin_logs').add({
        'teacherEmail': email,
        'teacherName': name,
        'phoneNumber': null,
        'teacherId': widget.id,
        'timestamp': FieldValue.serverTimestamp(),
        'details': 'Teacher completed profile setup, awaiting verification',
      });

      // Clear SharedPreferences after saving
      await prefs.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile submitted successfully!',
                style: GoogleFonts.poppins()),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }

      // Start timer for navigation
      _startTimer();
    } catch (e) {
      print('Error saving teacher data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => SelectionScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 255, 144, 187)))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 29.0, left: 20.0, right: 20.0, bottom: 8.0),
                    child: Text(
                      "Thank You for Completing\nYour Registration!",
                      style: GoogleFonts.poppins(
                          fontSize: 26, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Divider(
                      color: Color.fromARGB(255, 255, 144, 187),
                      thickness: 2,
                      height: 32),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "We've received your application with ID: ${widget.id}'. Our team is currently reviewing your profile. You will receive an email with the status of your application within 5 business days.",
                          style: GoogleFonts.poppins(
                              fontSize: 16, color: Colors.black87, height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "If your initial profile is approved, we will send you a follow-up email with a Google Meet link for a short interview. Completing this interview is the final step to meet Speakora's tutor onboarding requirements.",
                          style: GoogleFonts.poppins(
                              fontSize: 16, color: Colors.black87, height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "We appreciate your interest in joining Speakora and look forward to speaking with you soon!",
                          style: GoogleFonts.poppins(
                              fontSize: 16, color: Colors.black87, height: 1.5),
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
