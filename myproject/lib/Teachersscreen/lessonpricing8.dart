import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'availability7.dart';
import 'thankyouscreen.dart'; // Adjust import path as needed

class LessonPricingScreen extends StatefulWidget {
  final String id;
  const LessonPricingScreen({super.key, required this.id});

  @override
  State<LessonPricingScreen> createState() => _LessonPricingScreenState();
}

class _LessonPricingScreenState extends State<LessonPricingScreen> {
  final TextEditingController _standardRateController = TextEditingController();
  final TextEditingController _introRateController = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final pricingJson = prefs.getString('pricing');
    if (pricingJson != null) {
      final pricingData = jsonDecode(pricingJson);
      _standardRateController.text =
          pricingData['standardRate']?.toString() ?? '';
      _introRateController.text = pricingData['introRate']?.toString() ?? '';
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveData({bool navigateToThankYou = false}) async {
    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (!_validatePricing()) {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final pricingData = {
        'standardRate': double.parse(_standardRateController.text.trim()),
        'introRate': _introRateController.text.trim().isNotEmpty
            ? double.parse(_introRateController.text.trim())
            : null,
      };
      await prefs.setString('pricing', jsonEncode(pricingData));

      if (navigateToThankYou) {
        // Collect all data from Shared Preferences
        // About Info
        final aboutInfo = {
          'firstName': prefs.getString('firstName') ?? '',
          'lastName': prefs.getString('lastName') ?? '',
          'country': prefs.getString('country') ?? '',
          'email': prefs.getString('email') ?? '',
          'phoneNumber': prefs.getString('phoneNumber') ?? '',
          'teachingCourse': prefs.getString('teachingCourse') ?? '',
        };

        // Profile Photo
        final profilePhotoUrl = prefs.getString('profilePhotoUrl') ?? '';

        // Certifications
        final certificationsJson = prefs.getStringList('certifications') ?? [];
        final certifications = certificationsJson.map((jsonString) {
          final data = jsonDecode(jsonString);
          return {
            'subject': data['subject'] ?? '',
            'certification': data['certification'] ?? '',
            'description': data['description'] ?? '',
            'issuedBy': data['issuedBy'] ?? '',
            'startYear': data['startYear'] ?? '',
            'endYear': data['endYear'] ?? '',
            'fileName': data['fileName'] ?? '',
            'fileUrl': data['fileUrl'] ?? '',
          };
        }).toList();

        // Education
        final educationJson = prefs.getStringList('education') ?? [];
        final education = educationJson.map((jsonString) {
          final data = jsonDecode(jsonString);
          return {
            'university': data['university'] ?? '',
            'degree': data['degree'] ?? '',
            'degreeType': data['degreeType'] ?? '',
            'specialization': data['specialization'] ?? '',
            'startYear': data['startYear'] ?? '',
            'endYear': data['endYear'] ?? '',
            'fileName': data['fileName'] ?? '',
          };
        }).toList();

        // Description
        final description = {
          'intro': prefs.getString('description.intro') ?? '',
          'experience': prefs.getString('description.experience') ?? '',
          'motivation': prefs.getString('description.motivation') ?? '',
        };

        // Video
        final videoUrl = prefs.getString('video_url') ?? '';

        // Availability
        final availabilityJson = prefs.getString('availability');
        final Map<String, dynamic> availability = {};
        if (availabilityJson != null) {
          final data = jsonDecode(availabilityJson);
          final days = data['days'] as Map<String, dynamic>? ?? {};
          final formattedDays = <String, dynamic>{};
          days.forEach((day, dayData) {
            final slots = (dayData['slots'] as List<dynamic>?)?.map((slot) {
                  return {'from': slot['from'], 'to': slot['to']};
                }).toList() ??
                [];
            formattedDays[day] = {
              'enabled': dayData['enabled'] ?? false,
              'slots': slots,
            };
          });
          availability['timezone'] = data['timezone'];
          availability['days'] = formattedDays;
        } else {
          availability['timezone'] = null;
          availability['days'] = {
            'Monday': {'enabled': false, 'slots': []},
            'Tuesday': {'enabled': false, 'slots': []},
            'Wednesday': {'enabled': false, 'slots': []},
            'Thursday': {'enabled': false, 'slots': []},
            'Friday': {'enabled': false, 'slots': []},
            'Saturday': {'enabled': false, 'slots': []},
            'Sunday': {'enabled': false, 'slots': []},
          };
        }

        // Pricing
        final pricing = {
          'standardRate': pricingData['standardRate'],
          'introRate': pricingData['introRate'],
        };

        // Construct teacher data
        final teacherData = {
          'uid': widget.id,
          'about': aboutInfo,
          'profilePhoto': {
            'profilePhotoUrl': profilePhotoUrl,
            'profileImageUrl': profilePhotoUrl,
          },
          'certifications': certifications,
          'education': education,
          'description': description,
          'video': {
            'videoUrl': videoUrl,
          },
          'availability': availability,
          'pricing': pricing,
          'status': 'not_verified',
          'emailVerified': prefs.getBool('emailVerified') ?? false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'emailVerificationSentAt': FieldValue.serverTimestamp(),
        };

        // Save to Firestore
        await _firestore
            .collection('teachers_not_verified')
            .doc(widget.id)
            .set(teacherData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pricing saved successfully!',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving pricing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving pricing: $e',
                  style:
                      GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
              backgroundColor: const Color.fromARGB(255, 0, 0, 0)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  bool _validatePricing() {
    if (!mounted) return false;

    final standardRateText = _standardRateController.text.trim();
    if (standardRateText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please enter a standard lesson rate',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0)),
      );
      return false;
    }

    final standardRate = double.tryParse(standardRateText);
    if (standardRate == null || standardRate < 3.00 || standardRate > 100.00) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Standard rate must be between \$3.00 and \$100.00 USD',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        ),
      );
      return false;
    }

    final introRateText = _introRateController.text.trim();
    if (introRateText.isNotEmpty) {
      final introRate = double.tryParse(introRateText);
      if (introRate == null || introRate < 0 || introRate > standardRate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Introductory rate must be between \$0.00 and the standard rate',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.white, // Changed to white background
          ),
          child: const Center(
              child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 255, 144, 187))),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white, // Changed to white background
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 29.0, left: 16.0, right: 16.0, bottom: 8.0),
                  child: Text(
                    "Speakora Lesson Pricing",
                    style: GoogleFonts.poppins(
                        fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildDivider(),
                _buildIntroSection(),
                _buildPricingInputSection(),
                _buildRecommendationsSection(),
                _buildCommissionSection(),
                _buildCommissionTiersTable(),
                _buildCommissionNote(),
                _buildIntroductorySessionsSection(),
                _buildBottomButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
        color: Color.fromARGB(255, 255, 144, 187), thickness: 1.0, height: 1.0);
  }

  Widget _buildIntroSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        "On Speakora, tutors have the freedom to set their own lesson rates. Each session is 50 minutes long. To help you gain momentum:",
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[800]),
      ),
    );
  }

  Widget _buildPricingInputSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Set Your Lesson Rates",
            style:
                GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            "Standard Lesson Rate (50 minutes, USD)",
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _standardRateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              hintText: "e.g., 5.00",
              hintStyle: GoogleFonts.poppins(
                  color: const Color.fromRGBO(158, 158, 158, 1)),
              border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8)),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                    color: Color.fromARGB(255, 255, 144, 187), width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              prefixText: '\$ ',
              prefixStyle:
                  GoogleFonts.poppins(color: Colors.black, fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Introductory Session Rate (25 minutes, USD, optional)",
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _introRateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.poppins(color: Colors.black, fontSize: 14),
            decoration: InputDecoration(
              hintText: "e.g., 2.50 (leave blank if free or not offered)",
              hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
              border: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 214, 207, 207),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                    color: Color.fromARGB(255, 255, 144, 187), width: 1),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              prefixText: '\$ ',
              prefixStyle:
                  GoogleFonts.poppins(color: Colors.black, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecommendationItem(
              "We recommend new tutors start with a standard rate between \$3.00 and \$7.00 USD."),
          const SizedBox(height: 16),
          _buildRecommendationItem(
            "As you complete more lessons and build a strong profile, you can increase your price at any time based on your performance and student feedback.",
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          child: const Icon(Icons.check_circle,
              color: Color.fromARGB(255, 255, 144, 187), size: 20),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(
                    fontSize: 16, color: Colors.grey[800]))),
      ],
    );
  }

  Widget _buildCommissionSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Speakora Commission Structure",
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            "Speakora charges a commission to support platform development, marketing, and student engagement tools. Our model rewards your teaching commitment.",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[800]),
          ),
          const SizedBox(height: 16),
          Text("Commission Tiers:",
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCommissionTiersTable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 144, 187),
            borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Table(
            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1)},
            children: [
              _buildTableHeader(),
              _buildTableRow("0-100 hours", "25%"),
              _buildTableRow("101-200 hours", "23%"),
              _buildTableRow("201-350 hours", "20%"),
              _buildTableRow("351-500 hours", "18%"),
              _buildTableRow("501+ hours", "15%"),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildTableHeader() {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text("Total Teaching Hours",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text("Commission Rate",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.right),
        ),
      ],
    );
  }

  TableRow _buildTableRow(String hours, String rate) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(hours, style: GoogleFonts.poppins(fontSize: 16)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(rate,
              style: GoogleFonts.poppins(fontSize: 16),
              textAlign: TextAlign.right),
        ),
      ],
    );
  }

  Widget _buildCommissionNote() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("※",
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  color: Colors.green,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "The more hours you teach, the more you earn per hour.",
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[800],
                  fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroductorySessionsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Introductory Sessions (Optional)",
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(
            "You have the option to offer a free or discounted 25-minute intro session to attract new students. This can help increase bookings and build trust.",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: _isSaving
                ? null
                : () async {
                    await _saveData();
                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                AvailabilityScreen(id: widget.id)),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.black)),
              backgroundColor: Color.fromARGB(
                  255, 255, 144, 187), // Changed to white background
              foregroundColor: Colors.black,
              shadowColor: Colors.transparent,
            ),
            child: Text(
              'Back',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _isSaving
                ? null
                : () async {
                    if (_validatePricing()) {
                      await _saveData(navigateToThankYou: true);
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  ThankYouScreen(id: widget.id)),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.black)),
              backgroundColor: Color.fromARGB(
                  255, 255, 144, 187), // Changed to white background
              foregroundColor: Colors.black,
              shadowColor: Colors.transparent,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black),
                  )
                : Text(
                    'Save and register',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _standardRateController.dispose();
    _introRateController.dispose();
    super.dispose();
  }
}
