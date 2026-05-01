import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:email_validator/email_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'profilephotoscreen2.dart';

class AboutTutorForm extends StatefulWidget {
  final String id; // Firebase UID
  final String firstName; // First name from signup
  final String lastName; // Last name from signup
  final String email; // Email from signup
  const AboutTutorForm({
    super.key,
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  @override
  _AboutTutorFormState createState() => _AboutTutorFormState();
}

class _AboutTutorFormState extends State<AboutTutorForm> {
  final Map<String, Map<String, dynamic>> countryData = {
    'Afghanistan': {
      'code': '+93',
      'pattern': r'^\d{9}$',
      'example': '701234567'
    },
    'Algeria': {'code': '+213', 'pattern': r'^\d{9}$', 'example': '551234567'},
    'Argentina': {
      'code': '+54',
      'pattern': r'^\d{10,11}$',
      'example': '1123456789'
    },
    'Australia': {'code': '+61', 'pattern': r'^\d{9}$', 'example': '412345678'},
    'Austria': {
      'code': '+43',
      'pattern': r'^\d{10,11}$',
      'example': '6641234567'
    },
    'Bangladesh': {
      'code': '+880',
      'pattern': r'^\d{10}$',
      'example': '1712345678'
    },
    'Belgium': {'code': '+32', 'pattern': r'^\d{9}$', 'example': '471234567'},
    'Brazil': {
      'code': '+55',
      'pattern': r'^\d{10,11}$',
      'example': '11987654321'
    },
    'Canada': {'code': '+1', 'pattern': r'^\d{10}$', 'example': '4161234567'},
    'China': {'code': '+86', 'pattern': r'^\d{11}$', 'example': '13812345678'},
    'Denmark': {'code': '+45', 'pattern': r'^\d{8}$', 'example': '12345678'},
    'Egypt': {'code': '+20', 'pattern': r'^\d{9}$', 'example': '1001234567'},
    'Finland': {'code': '+358', 'pattern': r'^\d{9}$', 'example': '401234567'},
    'France': {'code': '+33', 'pattern': r'^\d{9}$', 'example': '612345678'},
    'Germany': {
      'code': '+49',
      'pattern': r'^\d{10,11}$',
      'example': '1701234567'
    },
    'Greece': {'code': '+30', 'pattern': r'^\d{10}$', 'example': '6912345678'},
    'India': {'code': '+91', 'pattern': r'^\d{10}$', 'example': '9876543210'},
    'Indonesia': {
      'code': '+62',
      'pattern': r'^\d{9,12}$',
      'example': '8123456789'
    },
    'Iran': {'code': '+98', 'pattern': r'^\d{10}$', 'example': '9123456789'},
    'Iraq': {'code': '+964', 'pattern': r'^\d{10}$', 'example': '7901234567'},
    'Ireland': {'code': '+353', 'pattern': r'^\d{9}$', 'example': '851234567'},
    'Italy': {'code': '+39', 'pattern': r'^\d{9,10}$', 'example': '3123456789'},
    'Japan': {
      'code': '+81',
      'pattern': r'^\d{10,11}$',
      'example': '9012345678'
    },
    'Kenya': {'code': '+254', 'pattern': r'^\d{9}$', 'example': '712345678'},
    'Malaysia': {
      'code': '+60',
      'pattern': r'^\d{9,10}$',
      'example': '123456789'
    },
    'Mexico': {'code': '+52', 'pattern': r'^\d{10}$', 'example': '5512345678'},
    'Nepal': {'code': '+977', 'pattern': r'^\d{10}$', 'example': '9841234567'},
    'Netherlands': {
      'code': '+31',
      'pattern': r'^\d{9}$',
      'example': '612345678'
    },
    'New Zealand': {
      'code': '+64',
      'pattern': r'^\d{8,9}$',
      'example': '211234567'
    },
    'Nigeria': {
      'code': '+234',
      'pattern': r'^\d{10}$',
      'example': '8012345678'
    },
    'Norway': {'code': '+47', 'pattern': r'^\d{8}$', 'example': '12345678'},
    'Pakistan': {
      'code': '+92',
      'pattern': r'^\d{10}$',
      'example': '3001234567'
    },
    'Philippines': {
      'code': '+63',
      'pattern': r'^\d{10}$',
      'example': '9171234567'
    },
    'Poland': {'code': '+48', 'pattern': r'^\d{9}$', 'example': '512345678'},
    'Portugal': {'code': '+351', 'pattern': r'^\d{9}$', 'example': '912345678'},
    'Qatar': {'code': '+974', 'pattern': r'^\d{8}$', 'example': '33123456'},
    'Russia': {'code': '+7', 'pattern': r'^\d{10}$', 'example': '9123456789'},
    'Saudi Arabia': {
      'code': '+966',
      'pattern': r'^\d{9}$',
      'example': '501234567'
    },
    'Singapore': {'code': '+65', 'pattern': r'^\d{8}$', 'example': '81234567'},
    'South Africa': {
      'code': '+27',
      'pattern': r'^\d{9}$',
      'example': '821234567'
    },
    'South Korea': {
      'code': '+82',
      'pattern': r'^\d{10,11}$',
      'example': '1012345678'
    },
    'Spain': {'code': '+34', 'pattern': r'^\d{9}$', 'example': '612345678'},
    'Sri Lanka': {'code': '+94', 'pattern': r'^\d{9}$', 'example': '712345678'},
    'Sweden': {'code': '+46', 'pattern': r'^\d{9}$', 'example': '701234567'},
    'Switzerland': {
      'code': '+41',
      'pattern': r'^\d{9}$',
      'example': '791234567'
    },
    'Thailand': {'code': '+66', 'pattern': r'^\d{9}$', 'example': '812345678'},
    'Turkey': {'code': '+90', 'pattern': r'^\d{10}$', 'example': '5321234567'},
    'UAE': {'code': '+971', 'pattern': r'^\d{9}$', 'example': '501234567'},
    'UK': {'code': '+44', 'pattern': r'^\d{10}$', 'example': '7123456789'},
    'Ukraine': {'code': '+380', 'pattern': r'^\d{9}$', 'example': '671234567'},
    'USA': {'code': '+1', 'pattern': r'^\d{10}$', 'example': '2125551234'},
    'Vietnam': {
      'code': '+84',
      'pattern': r'^\d{9,10}$',
      'example': '912345678'
    },
  };

  final List<String> countries = [
    'Afghanistan',
    'Algeria',
    'Argentina',
    'Australia',
    'Austria',
    'Bangladesh',
    'Belgium',
    'Brazil',
    'Canada',
    'China',
    'Denmark',
    'Egypt',
    'Finland',
    'France',
    'Germany',
    'Greece',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland',
    'Italy',
    'Japan',
    'Kenya',
    'Malaysia',
    'Mexico',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Nigeria',
    'Norway',
    'Pakistan',
    'Philippines',
    'Poland',
    'Portugal',
    'Qatar',
    'Russia',
    'Saudi Arabia',
    'Singapore',
    'South Africa',
    'South Korea',
    'Spain',
    'Sri Lanka',
    'Sweden',
    'Switzerland',
    'Thailand',
    'Turkey',
    'UAE',
    'UK',
    'Ukraine',
    'USA',
    'Vietnam'
  ];

  final List<String> languages = [
    'Arabic',
    'Chinese (Mandarin)',
    'Dutch',
    'English',
    'French',
    'German',
    'Hebrew',
    'Hindi',
    'Italian',
    'Japanese',
    'Korean',
    'Polish',
    'Portuguese',
    'Russian',
    'Spanish',
    'Swedish',
    'Thai',
    'Turkish',
    'Ukrainian',
    'Vietnamese'
  ];

  final List<String> levels = ['Beginner', 'Intermediate', 'Advanced'];

  bool isConfirmed = false;
  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _selectedCountry;
  String? _selectedTeachingCourse;
  List<Map<String, String>> languageEntries = [
    {'language': '', 'level': ''}
  ];

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  void _initializeUserData() async {
    // Set first name, last name, and email from widget parameters
    _firstNameController.text = widget.firstName;
    _lastNameController.text = widget.lastName;
    _emailController.text = widget.email;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCountry = prefs.getString('country');
      _phoneController.text =
          prefs.getString('phoneNumber')?.replaceAll(getCountryCode(), '') ??
              '';
      _selectedTeachingCourse = prefs.getString('teachingCourse');
      final languagesJson = prefs.getStringList('languages') ?? [];
      languageEntries = languagesJson
          .map((jsonString) => jsonDecode(jsonString) as Map<String, dynamic>)
          .map((data) => {
                'language': data['language'] as String,
                'level': data['level'] as String
              })
          .toList();
      if (languageEntries.isEmpty) {
        languageEntries = [
          {'language': '', 'level': ''}
        ];
      }
    });
  }

  String getCountryCode() {
    if (_selectedCountry != null && countryData.containsKey(_selectedCountry)) {
      return countryData[_selectedCountry]!['code'];
    }
    return '+1';
  }

  String getPhoneExample() {
    if (_selectedCountry != null && countryData.containsKey(_selectedCountry)) {
      return countryData[_selectedCountry]!['example'];
    }
    return '1234567890';
  }

  String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    if (_selectedCountry == null) {
      return 'Please select your country first';
    }
    String cleanedValue = value.replaceAll(RegExp(r'\D'), '');
    if (countryData.containsKey(_selectedCountry)) {
      String pattern = countryData[_selectedCountry]!['pattern'];
      RegExp regExp = RegExp(pattern);
      if (!regExp.hasMatch(cleanedValue)) {
        String example = getPhoneExample();
        return 'Please enter a valid phone number\nExample: $example';
      }
    }
    return null;
  }

  String getFormattedPhoneNumber() {
    String countryCode = getCountryCode();
    String phoneNumber = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return '$countryCode$phoneNumber';
  }

  bool validateLanguageEntries() {
    for (var entry in languageEntries) {
      if (entry['language'] == null ||
          entry['language']!.isEmpty ||
          !languages.contains(entry['language']) ||
          entry['level'] == null ||
          entry['level']!.isEmpty ||
          !levels.contains(entry['level'])) {
        return false;
      }
    }
    return true;
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate() ||
        !validateLanguageEntries() ||
        _selectedTeachingCourse == null ||
        _selectedTeachingCourse!.isEmpty ||
        !languages.contains(_selectedTeachingCourse)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please fill all required fields correctly',
                style: GoogleFonts.poppins())),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // Save updated data to SharedPreferences
      await prefs.setString('signup_firstName', widget.firstName);
      await prefs.setString('signup_lastName', widget.lastName);
      await prefs.setString('signup_email', widget.email);
      await prefs.setString('firstName', _firstNameController.text.trim());
      await prefs.setString('lastName', _lastNameController.text.trim());
      await prefs.setString('email', _emailController.text.trim());
      await prefs.setString('country', _selectedCountry ?? '');
      await prefs.setString('phoneNumber', getFormattedPhoneNumber());
      await prefs.setString('teachingLanguage', _selectedTeachingCourse!);
      // Convert language entries to JSON strings
      List<String> languagesJson = languageEntries
          .where((entry) =>
              entry['language']!.isNotEmpty && entry['level']!.isNotEmpty)
          .map((entry) => jsonEncode(
              {'language': entry['language'], 'level': entry['level']}))
          .toList();
      await prefs.setStringList('languages', languagesJson);
      await prefs.setBool('isOver18', isConfirmed);

      // Navigate to ProfilePhotoScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePhotoScreen(id: widget.id),
        ),
      );
    } catch (e) {
      print('Error saving data: $e');
      if (e is FormatException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Invalid data format, please try again',
                  style: GoogleFonts.poppins())),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving profile: $e',
                  style: GoogleFonts.poppins())),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              SizedBox(width: 16),
                              Text(
                                "About",
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 16),
                            child: Divider(
                              color: Color.fromARGB(255, 255, 144, 187),
                              thickness: 1.0,
                            ),
                          ),
                          Text(
                            "Create your tutor profile and showcase your skills to students around the world. Your information will be saved as you go, so you can complete it whenever you're ready. Start now and take the first step toward becoming a trusted tutor!",
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          const SizedBox(height: 30),
                          _buildTextFormField(_firstNameController,
                              "First name", "Enter your name", readOnly: true,
                              (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your first name';
                            }
                            return null;
                          }),
                          _buildTextFormField(_lastNameController, "Last name",
                              "Enter your name",
                              readOnly: true, (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your last name';
                            }
                            return null;
                          }),
                          _buildTextFormField(
                              _emailController, "Email", "Enter email address",
                              readOnly: true, (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!EmailValidator.validate(value.trim())) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          }),
                          const SizedBox(height: 16),
                          Text("Country of birth",
                              style: GoogleFonts.poppins(color: Colors.black)),
                          const SizedBox(height: 8),
                          _buildCountryDropdown(),
                          const SizedBox(height: 20),
                          Text("Languages you speak",
                              style: GoogleFonts.poppins(color: Colors.black)),
                          const SizedBox(height: 8),
                          ...List.generate(
                            languageEntries.length,
                            (index) => Column(
                              children: [
                                if (index > 0) const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _buildDropdown(
                                        languages,
                                        "Language",
                                        (value) {
                                          setState(() {
                                            languageEntries[index]['language'] =
                                                value!;
                                          });
                                        },
                                        initialValue: languageEntries[index]
                                            ['language'],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildDropdown(
                                        levels,
                                        "Level",
                                        (value) {
                                          setState(() {
                                            languageEntries[index]['level'] =
                                                value!;
                                          });
                                        },
                                        initialValue: languageEntries[index]
                                            ['level'],
                                      ),
                                    ),
                                    if (index > 0)
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.black),
                                        onPressed: () {
                                          setState(() {
                                            languageEntries.removeAt(index);
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              if (!languageEntries
                                  .any((entry) => entry['language']!.isEmpty)) {
                                setState(() {
                                  languageEntries
                                      .add({'language': '', 'level': ''});
                                });
                              }
                            },
                            child: Text(
                              "Add another language",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text("Language course you offer",
                              style: GoogleFonts.poppins(color: Colors.black)),
                          const SizedBox(height: 8),
                          _buildDropdown(
                            languages,
                            "Select a language",
                            (value) {
                              setState(() {
                                _selectedTeachingCourse = value;
                              });
                            },
                            initialValue: _selectedTeachingCourse,
                          ),
                          const SizedBox(height: 20),
                          _buildPhoneNumberField(),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Checkbox(
                                value: isConfirmed,
                                onChanged: (value) {
                                  setState(() {
                                    isConfirmed = value!;
                                  });
                                },
                              ),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: 'I confirm that I am over 18 ',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 200,
                              height: 50,
                              child: ElevatedButton(
                                onPressed:
                                    isConfirmed ? _saveAndContinue : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isConfirmed
                                      ? const Color.fromARGB(255, 255, 144, 187)
                                      : const Color.fromARGB(
                                          255, 255, 255, 255),
                                  foregroundColor: Colors.black,
                                  alignment: Alignment.center,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    side: const BorderSide(color: Colors.black),
                                  ),
                                ),
                                child: isLoading
                                    ? CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 2.0,
                                      )
                                    : Text(
                                        "Save and continue",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text("Phone number", style: GoogleFonts.poppins(color: Colors.black)),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border:
                    Border.all(color: const Color.fromARGB(255, 196, 188, 188)),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                color: const Color.fromARGB(255, 255, 144, 187),
              ),
              child: Text(
                getCountryCode(),
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.poppins(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Enter your number (${getPhoneExample()})",
                  hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[500], fontSize: 12),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    borderSide:
                        BorderSide(color: Color.fromARGB(255, 206, 201, 201)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    borderSide: BorderSide(
                        color: Color.fromARGB(255, 255, 144, 187), width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  errorStyle: GoogleFonts.poppins(color: Colors.red),
                ),
                validator: validatePhoneNumber,
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ],
        ),
        if (_phoneController.text.isNotEmpty && _selectedCountry != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Full number: ${getFormattedPhoneNumber()}",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Color.fromARGB(255, 0, 0, 0),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String label,
      String hint, String? Function(String?) validator,
      {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(label, style: GoogleFonts.poppins(color: Colors.black)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: GoogleFonts.poppins(color: Colors.black),
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.black54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: const Color.fromARGB(255, 204, 198, 198), width: 1),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            errorStyle: GoogleFonts.poppins(color: Colors.red),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCountryDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color.fromARGB(255, 204, 198, 198)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color.fromARGB(255, 204, 198, 198)),
        ),
        hintStyle: GoogleFonts.poppins(color: Colors.black54),
        errorStyle: GoogleFonts.poppins(color: Colors.red),
      ),
      hint: Text("Select a country",
          style: GoogleFonts.poppins(color: Colors.black)),
      value: _selectedCountry,
      items: countries
          .map((item) => DropdownMenuItem(
                value: item,
                child:
                    Text(item, style: GoogleFonts.poppins(color: Colors.black)),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedCountry = value;
          _phoneController.clear();
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select your country';
        }
        return null;
      },
      menuMaxHeight: 300.0,
      isExpanded: true,
      dropdownColor: Colors.white,
    );
  }

  Widget _buildDropdown(
      List<String> items, String hint, Function(String?) onChanged,
      {String? initialValue}) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color.fromARGB(255, 204, 198, 198)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color.fromARGB(255, 204, 198, 198)),
        ),
        hintStyle: GoogleFonts.poppins(color: Colors.black54),
      ),
      hint: Text(hint, style: GoogleFonts.poppins(color: Colors.black)),
      value:
          initialValue != null && initialValue.isNotEmpty ? initialValue : null,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child:
                    Text(item, style: GoogleFonts.poppins(color: Colors.black)),
              ))
          .toList(),
      onChanged: onChanged,
      menuMaxHeight: 200.0,
      isExpanded: true,
      dropdownColor: Colors.white,
    );
  }
}
