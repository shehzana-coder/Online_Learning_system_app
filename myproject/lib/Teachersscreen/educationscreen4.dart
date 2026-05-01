import 'dart:async';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'certification3.dart';
import 'descriptionscreen5.dart'; // Adjust import path as needed

class EducationForm {
  final TextEditingController universityController = TextEditingController();
  final TextEditingController degreeController = TextEditingController();
  final TextEditingController degreeTypeController = TextEditingController();
  final TextEditingController specializationController =
      TextEditingController();
  String? selectedStartYear;
  String? selectedEndYear;
  String? selectedFilePath; // Renamed from certificateLocalPath
  String? fileName;
  bool hasUnsavedChanges = false;

  EducationForm() {
    _addChangeListeners();
  }

  void _addChangeListeners() {
    universityController.addListener(() => hasUnsavedChanges = true);
    degreeController.addListener(() => hasUnsavedChanges = true);
    degreeTypeController.addListener(() => hasUnsavedChanges = true);
    specializationController.addListener(() => hasUnsavedChanges = true);
  }

  void markAsSaved() {
    hasUnsavedChanges = false;
  }

  bool hasData() {
    return universityController.text.trim().isNotEmpty ||
        degreeController.text.trim().isNotEmpty ||
        degreeTypeController.text.trim().isNotEmpty ||
        specializationController.text.trim().isNotEmpty ||
        selectedStartYear != null ||
        selectedEndYear != null ||
        selectedFilePath != null;
  }

  void dispose() {
    universityController.dispose();
    degreeController.dispose();
    degreeTypeController.dispose();
    specializationController.dispose();
  }
}

class EducationScreen extends StatefulWidget {
  final String id; // Renamed from teacherId
  const EducationScreen({super.key, required this.id});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  bool noHigherEducation = false;
  bool isLoading = false;
  List<EducationForm> educationForms = [EducationForm()];
  List<String> years =
      List.generate(50, (index) => (DateTime.now().year - index).toString());
  String? fileError;
  int currentFormIndex = 0;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    years = [DateTime.now().year.toString(), ...years]; // Include current year
    _loadExistingData();
  }

  @override
  void dispose() {
    for (var form in educationForms) {
      if (form.selectedFilePath != null && form.fileName == null) {
        File(form.selectedFilePath!).deleteSync(); // Clean up temporary files
      }
      form.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      noHigherEducation = prefs.getBool('noHigherEducation') ?? false;
      final educationJson = prefs.getStringList('education') ?? [];
      if (educationJson.isNotEmpty && mounted) {
        setState(() {
          educationForms = [];
          for (int i = 0; i < educationJson.length; i++) {
            final form = EducationForm();
            final edu = jsonDecode(educationJson[i]);
            form.universityController.text = edu['university'] ?? '';
            form.degreeController.text = edu['degree'] ?? '';
            form.degreeTypeController.text = edu['degreeType'] ?? '';
            form.specializationController.text = edu['specialization'] ?? '';
            form.selectedStartYear = edu['startYear'];
            form.selectedEndYear = edu['endYear'];
            form.fileName = edu['fileName'];
            educationForms.add(form);
          }
        });
      }
    } catch (e) {
      print('Error loading education data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading education data: $e',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
    }
  }

  void _onFormDataChanged() {
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  bool _validateEducationData() {
    if (noHigherEducation) return true;

    bool hasValidData = false;
    for (int i = 0; i < educationForms.length; i++) {
      final form = educationForms[i];
      final university = form.universityController.text.trim();
      final degree = form.degreeController.text.trim();
      final degreeType = form.degreeTypeController.text.trim();
      final specialization = form.specializationController.text.trim();

      if (university.isNotEmpty ||
          degree.isNotEmpty ||
          degreeType.isNotEmpty ||
          specialization.isNotEmpty) {
        hasValidData = true;
        if (university.isEmpty ||
            degree.isEmpty ||
            degreeType.isEmpty ||
            specialization.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Please fill University, Degree, Degree Type, and Specialization for education ${i + 1}',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: const Color.fromARGB(255, 0, 0, 0),
              ),
            );
          }
          return false;
        }
        if (form.selectedStartYear == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Please select Start Year for education ${i + 1}',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: const Color.fromARGB(255, 0, 0, 0),
              ),
            );
          }
          return false;
        }
        if (form.selectedEndYear == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Please select End Year for education ${i + 1}',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: const Color.fromARGB(255, 0, 0, 0),
              ),
            );
          }
          return false;
        }
        if (form.selectedEndYear != 'Present') {
          final start = int.tryParse(form.selectedStartYear!);
          final end = int.tryParse(form.selectedEndYear!);
          if (start != null && end != null && end < start) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'End Year cannot be earlier than Start Year for education ${i + 1}',
                    style:
                        GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                ),
              );
            }
            return false;
          }
        }
        if (form.selectedFilePath == null && form.fileName == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Please upload a certificate for education ${i + 1}',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: const Color.fromARGB(255, 0, 0, 0),
              ),
            );
          }
          return false;
        }
      }
    }

    if (!hasValidData) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please add at least one valid education entry or select "I don\'t have a higher education degree"',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
            ),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
    }
    return hasValidData;
  }

  Future<void> _saveEducationData() async {
    if (!_validateEducationData()) return;

    setState(() {
      isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> educationJson = [];

      if (!noHigherEducation) {
        for (var form in educationForms) {
          final university = form.universityController.text.trim();
          final degree = form.degreeController.text.trim();
          final degreeType = form.degreeTypeController.text.trim();
          if (university.isEmpty || degree.isEmpty || degreeType.isEmpty)
            continue;

          String? fileUrl;
          if (form.selectedFilePath != null) {
            final file = File(form.selectedFilePath!);
            if (!await file.exists()) {
              throw Exception('Selected file does not exist');
            }
            final storageRef = FirebaseStorage.instance.ref().child(
                'teacher_education_certificates/${widget.id}/${DateTime.now().millisecondsSinceEpoch}_${form.fileName ?? path.basename(file.path)}');
            await storageRef.putFile(file).timeout(const Duration(seconds: 30));
            fileUrl = await storageRef.getDownloadURL();
          } else if (form.fileName != null) {
            // Preserve existing file URL if no new file was uploaded
            final existingEdu = (prefs.getStringList('education') ?? [])
                .asMap()
                .entries
                .firstWhere(
                    (entry) =>
                        jsonDecode(entry.value)['file_name'] == form.fileName,
                    orElse: () => MapEntry(-1, '{}'));
            if (existingEdu.key != -1) {
              fileUrl = jsonDecode(existingEdu.value)['file_url'];
            }
          }

          final eduData = {
            'university': university,
            'degree': degree,
            'degree_type': degreeType,
            'specialization': form.specializationController.text.trim(),
            'start_year': form.selectedStartYear,
            'end_year': form.selectedEndYear,
            'file_name': form.fileName ??
                (form.selectedFilePath != null
                    ? path.basename(form.selectedFilePath!)
                    : null),
            'file_url': fileUrl,
          };
          educationJson.add(jsonEncode(eduData));
          form.markAsSaved();
        }
      }

      await prefs.setStringList('education', educationJson);
      await prefs.setBool('noHigherEducation', noHigherEducation);

      if (mounted) {
        setState(() {
          _hasUnsavedChanges = false;
        });
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileDescriptionScreen(id: widget.id),
          ),
        );
      }
    } on TimeoutException catch (e) {
      print('Upload timeout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload timed out, please try again',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
    } catch (e) {
      print('Error saving education data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving education data: $e',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Unsaved Changes',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text(
              'You have unsaved changes. Would you like to save them before leaving?',
              style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Discard',
                  style: GoogleFonts.poppins(
                      color: const Color.fromARGB(255, 0, 0, 0))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child:
                  Text('Save', style: GoogleFonts.poppins(color: Colors.green)),
            ),
          ],
        ),
      );

      if (shouldSave == true) {
        await _saveEducationData();
      }
    }
    return true;
  }

  Future<void> _pickFile(int formIndex) async {
    setState(() {
      currentFormIndex = formIndex;
      fileError = null;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        int fileSizeInBytes = await file.length();
        double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        if (fileSizeInMB > 20) {
          setState(() {
            fileError = 'File size exceeds 20MB limit.';
            educationForms[formIndex].selectedFilePath = null;
            educationForms[formIndex].fileName = null;
          });
          return;
        }

        setState(() {
          educationForms[formIndex].selectedFilePath = file.path;
          educationForms[formIndex].fileName = path.basename(file.path);
          _hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      setState(() {
        fileError = 'Error picking file: $e';
        educationForms[formIndex].selectedFilePath = null;
        educationForms[formIndex].fileName = null;
      });
    }
  }

  void _addAnotherEducation() {
    setState(() {
      educationForms.add(EducationForm());
      _hasUnsavedChanges = true;
    });
  }

  void _removeEducation(int index) {
    if (educationForms.length <= 1) return;

    setState(() {
      educationForms[index].dispose();
      educationForms.removeAt(index);
      _hasUnsavedChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white, // Set background color to white
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Education",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, fontSize: 28),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                            height: 1,
                            color: Color.fromARGB(255, 255, 144, 187),
                            width: double.infinity),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          "Tell students more about the higher education that you've completed or are working on.",
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: noHigherEducation,
                                onChanged: (value) {
                                  setState(() {
                                    noHigherEducation = value!;
                                    _hasUnsavedChanges = true;
                                  });
                                },
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(3)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "I don't have a higher education degree",
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (!noHigherEducation)
                          ...List.generate(educationForms.length, (index) {
                            final form = educationForms[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (index > 0)
                                  const Divider(height: 40, thickness: 1),
                                if (index > 0)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 16, bottom: 24),
                                        child: Text(
                                          "Education ${index + 1}",
                                          style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color:
                                                Color.fromARGB(255, 0, 0, 0)),
                                        onPressed: () =>
                                            _removeEducation(index),
                                      ),
                                    ],
                                  ),
                                Text("University",
                                    style: GoogleFonts.poppins(fontSize: 16)),
                                const SizedBox(height: 8),
                                _buildTextField("", "e.g., Namal University",
                                    form.universityController),
                                const SizedBox(height: 16),
                                Text("Degree",
                                    style: GoogleFonts.poppins(fontSize: 16)),
                                const SizedBox(height: 8),
                                _buildTextField("", "e.g., Degree in English",
                                    form.degreeController),
                                const SizedBox(height: 16),
                                Text("Degree Type",
                                    style: GoogleFonts.poppins(fontSize: 16)),
                                const SizedBox(height: 8),
                                _buildTextField(
                                    "",
                                    "e.g., Bachelor's, Master's, PhD",
                                    form.degreeTypeController),
                                const SizedBox(height: 16),
                                Text("Specialization",
                                    style: GoogleFonts.poppins(fontSize: 16)),
                                const SizedBox(height: 8),
                                _buildTextField(
                                    "",
                                    "e.g., Computer Science, Literature",
                                    form.specializationController),
                                const SizedBox(height: 16),
                                Text("Year of Study",
                                    style: GoogleFonts.poppins(fontSize: 16)),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildYearDropdown(
                                          "Start Year", form.selectedStartYear,
                                          (val) {
                                        setState(() {
                                          form.selectedStartYear = val;
                                          _hasUnsavedChanges = true;
                                        });
                                      }, false),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildYearDropdown(
                                          "End Year", form.selectedEndYear,
                                          (val) {
                                        setState(() {
                                          form.selectedEndYear = val;
                                          _hasUnsavedChanges = true;
                                        });
                                      }, true),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                        255, 255, 144, 187),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Earn a Certificate Verified Badge",
                                        style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Upload your diploma to boost your credibility! Our team will verify its authenticity and award you a verified badge. After the review process, your uploaded files will be permanently removed for privacy and security.",
                                        style:
                                            GoogleFonts.poppins(fontSize: 14),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "Accepted formats: JPG or PNG (up to 20MB)",
                                        style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 12),
                                      if (form.selectedFilePath != null ||
                                          form.fileName != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Certificate uploaded ✓",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Under verification review",
                                                style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontStyle:
                                                        FontStyle.italic),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (currentFormIndex == index &&
                                          fileError != null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: Text(
                                            fileError!,
                                            style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: const Color.fromARGB(
                                                    255, 244, 56, 56),
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      Center(
                                        child: ElevatedButton(
                                          onPressed: () => _pickFile(index),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 14),
                                            side: const BorderSide(
                                                color: Colors.black,
                                                width: 1.5),
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    255, 255, 144, 187),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                          ),
                                          child: Text(
                                            form.selectedFilePath != null ||
                                                    form.fileName != null
                                                ? "Certificate Uploaded"
                                                : "Upload Certificate",
                                            style: GoogleFonts.poppins(
                                                color: Colors.black,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        const SizedBox(height: 20),
                        if (!noHigherEducation)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _addAnotherEducation,
                              icon: const Icon(Icons.add_circle_outline,
                                  color: Color.fromARGB(255, 0, 0, 0)),
                              label: Text(
                                'Add Another Education',
                                style: GoogleFonts.poppins(
                                    color: const Color.fromARGB(255, 0, 0, 0),
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: _handleBackNavigation,
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
                              onPressed: _handleNextNavigation,
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
                        const SizedBox(height: 20),
                      ],
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

  void _handleBackNavigation() async {
    if (_hasUnsavedChanges) {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Unsaved Changes',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text(
              'You have unsaved changes. Would you like to save them before leaving?',
              style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Discard',
                  style: GoogleFonts.poppins(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child:
                  Text('Save', style: GoogleFonts.poppins(color: Colors.green)),
            ),
          ],
        ),
      );

      if (shouldSave == true) {
        await _saveEducationData();
      }
    }
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CertificationScreen(id: widget.id),
        ),
      );
    }
  }

  void _handleNextNavigation() async {
    await _saveEducationData();
  }

  Widget _buildTextField(
      String label, String hint, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.poppins(fontSize: 16, color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color.fromARGB(255, 186, 186, 186))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color.fromARGB(255, 166, 166, 166))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Color.fromARGB(255, 255, 144, 187)),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
      onChanged: (value) => _onFormDataChanged(),
    );
  }

  Widget _buildYearDropdown(String label, String? selectedValue,
      ValueChanged<String?> onChanged, bool includePresent) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      hint: Text(label, style: GoogleFonts.poppins(color: Colors.grey[400])),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.black),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color.fromARGB(255, 190, 190, 190))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: Color.fromARGB(255, 210, 210, 210))),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Color.fromARGB(255, 255, 144, 187)),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
      dropdownColor: Colors.white,
      style: GoogleFonts.poppins(fontSize: 16, color: Colors.black),
      items: [
        if (includePresent)
          DropdownMenuItem<String>(
            value: 'Present',
            child: Text('Present',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black)),
          ),
        ...years.map((String year) {
          return DropdownMenuItem<String>(
            value: year,
            child: Text(year,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black)),
          );
        }),
      ],
      onChanged: onChanged,
    );
  }
}
