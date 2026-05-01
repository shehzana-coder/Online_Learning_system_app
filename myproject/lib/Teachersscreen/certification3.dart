import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import 'profilephotoscreen2.dart';
import 'educationscreen4.dart';

class CertificationScreen extends StatefulWidget {
  final String id; // Firebase UID
  const CertificationScreen({super.key, required this.id});

  @override
  _CertificationScreenState createState() => _CertificationScreenState();
}

class _CertificationScreenState extends State<CertificationScreen> {
  bool _noCertificate = false;
  bool _isLoading = false;

  // File selection and status
  final Map<int, String?> _selectedFileNames = {};
  final Map<int, File?> _selectedFiles = {};
  final Map<int, String?> _fileUrls = {};
  final Map<int, String?> _fileErrors = {};

  // Controllers for capturing form data
  final Map<int, TextEditingController> _subjectControllers = {};
  final Map<int, TextEditingController> _certificateControllers = {};
  final Map<int, TextEditingController> _descriptionControllers = {};
  final Map<int, TextEditingController> _issuedByControllers = {};
  final Map<int, String?> _startYears = {};
  final Map<int, String?> _endYears = {};

  // List to store multiple certification entries
  List<bool> _certificationForms = [true];

  // ignore: prefer_final_fields
  List<String> _years =
      List.generate(50, (index) => (DateTime.now().year - index).toString());

  @override
  void initState() {
    super.initState();
    _initializeControllers(0);
    _loadExistingData();
    _years = [
      DateTime.now().year.toString(),
      ..._years
    ]; // Include current year
  }

  void _initializeControllers(int index) {
    _subjectControllers[index] = TextEditingController()
      ..addListener(_saveDataLocally);
    _certificateControllers[index] = TextEditingController()
      ..addListener(_saveDataLocally);
    _descriptionControllers[index] = TextEditingController()
      ..addListener(_saveDataLocally);
    _issuedByControllers[index] = TextEditingController()
      ..addListener(_saveDataLocally);
    _startYears[index] = null; // Initialize with null
    _endYears[index] = null; // Initialize with null
  }

  @override
  void dispose() {
    _subjectControllers.forEach((key, controller) => controller.dispose());
    _certificateControllers.forEach((key, controller) => controller.dispose());
    _descriptionControllers.forEach((key, controller) => controller.dispose());
    _issuedByControllers.forEach((key, controller) => controller.dispose());
    _selectedFiles.forEach((key, file) {
      if (file != null && _fileUrls[key] == null) {
        file.deleteSync(); // Clean up temporary files
      }
    });
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final certificationsJson = prefs.getStringList('certifications') ?? [];
      _noCertificate = prefs.getBool('noCertificate') ?? false;
      if (certificationsJson.isNotEmpty && mounted) {
        setState(() {
          _certificationForms =
              List.generate(certificationsJson.length, (_) => true);
          for (int i = 0; i < certificationsJson.length; i++) {
            _initializeControllers(i);
            final cert = jsonDecode(certificationsJson[i]);
            _subjectControllers[i]?.text = cert['subject'] ?? '';
            _certificateControllers[i]?.text = cert['certificate'] ?? '';
            _descriptionControllers[i]?.text = cert['description'] ?? '';
            _issuedByControllers[i]?.text = cert['issued_by'] ?? '';
            _startYears[i] = cert['start_year'];
            _endYears[i] = cert['end_year'];
            _selectedFileNames[i] = cert['file_name'];
            _fileUrls[i] = cert['file_url'];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error loading certifications: $e',
            const Color.fromARGB(255, 255, 75, 75));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addAnotherCertification() {
    setState(() {
      int newIndex = _certificationForms.length;
      _certificationForms.add(true);
      _initializeControllers(newIndex);
    });
    _saveDataLocally();
  }

  void _removeCertification(int index) {
    if (_certificationForms.length <= 1) return;

    setState(() {
      _certificationForms.removeAt(index);
      _subjectControllers[index]?.dispose();
      _certificateControllers[index]?.dispose();
      _descriptionControllers[index]?.dispose();
      _issuedByControllers[index]?.dispose();
      _subjectControllers.remove(index);
      _certificateControllers.remove(index);
      _descriptionControllers.remove(index);
      _issuedByControllers.remove(index);
      _selectedFileNames.remove(index);
      _selectedFiles.remove(index);
      _fileUrls.remove(index);
      _fileErrors.remove(index);
      _startYears.remove(index);
      _endYears.remove(index);
    });
    _saveDataLocally();
  }

  Future<void> _pickFile(int index) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();
        const maxSize = 20 * 1024 * 1024; // 20MB

        if (fileSize > maxSize) {
          setState(() {
            _fileErrors[index] = 'File size exceeds 20MB limit';
            _selectedFileNames[index] = null;
            _selectedFiles[index] = null;
            _fileUrls[index] = null;
          });
        } else {
          // Check for duplicate file
          if (_selectedFiles.containsValue(file)) {
            setState(() {
              _fileErrors[index] = 'This file is already uploaded';
              _selectedFileNames[index] = null;
              _selectedFiles[index] = null;
              _fileUrls[index] = null;
            });
            return;
          }
          setState(() {
            _selectedFileNames[index] = result.files.single.name;
            _selectedFiles[index] = file;
            _fileErrors[index] = null;
            _fileUrls[index] = null;
          });
        }
        _saveDataLocally();
      }
    } catch (e) {
      setState(() {
        _fileErrors[index] = 'Error selecting file: $e';
        _selectedFileNames[index] = null;
        _selectedFiles[index] = null;
        _fileUrls[index] = null;
      });
      _saveDataLocally();
    }
  }

  bool _validateCertificationData() {
    if (_noCertificate) return true;

    bool hasValidData = false;
    for (int i = 0; i < _certificationForms.length; i++) {
      final subject = _subjectControllers[i]?.text.trim() ?? '';
      final certificate = _certificateControllers[i]?.text.trim() ?? '';
      final description = _descriptionControllers[i]?.text.trim() ?? '';
      final issuedBy = _issuedByControllers[i]?.text.trim() ?? '';
      final startYear = _startYears[i];
      final endYear = _endYears[i];
      final file = _selectedFiles[i];
      final fileUrl = _fileUrls[i];

      if (subject.isNotEmpty ||
          certificate.isNotEmpty ||
          description.isNotEmpty ||
          issuedBy.isNotEmpty ||
          startYear != null ||
          endYear != null ||
          file != null ||
          fileUrl != null) {
        hasValidData = true;
        if (subject.isEmpty) {
          _showSnackBar(
            'Please fill Subject for certification ${i + 1}',
            const Color.fromARGB(255, 0, 0, 0),
          );
          return false;
        }
        if (certificate.isEmpty) {
          _showSnackBar(
            'Please fill Certificate name for certification ${i + 1}',
            const Color.fromARGB(255, 0, 0, 0),
          );
          return false;
        }
        if (description.isEmpty) {
          _showSnackBar(
            'Please fill Description for certification ${i + 1}',
            const Color.fromARGB(255, 0, 0, 0),
          );
          return false;
        }
        if (issuedBy.isEmpty) {
          _showSnackBar(
            'Please fill Issued By for certification ${i + 1}',
            const Color.fromARGB(255, 0, 0, 0),
          );
          return false;
        }
        if (startYear == null ||
            !int.tryParse(startYear).toString().contains(startYear)) {
          _showSnackBar(
            'Please select a valid Start Year for certification ${i + 1}',
            const Color.fromARGB(255, 0, 0, 0),
          );
          return false;
        }
        if (endYear == null ||
            !int.tryParse(endYear).toString().contains(endYear)) {
          _showSnackBar(
            'Please select a valid End Year for certification ${i + 1}',
            const Color.fromARGB(255, 0, 0, 0),
          );
          return false;
        }
        if (endYear != 'Present') {
          final start = int.tryParse(startYear);
          final end = int.tryParse(endYear);
          if (start != null && end != null && end < start) {
            _showSnackBar(
              'End year cannot be earlier than start year for certification ${i + 1}',
              const Color.fromARGB(255, 0, 0, 0),
            );
            return false;
          }
        }
        if (file == null && fileUrl == null) {
          _showSnackBar(
            'Please upload a certificate file for certification ${i + 1}',
            const Color.fromARGB(255, 0, 0, 0),
          );
          return false;
        }
      }
    }

    if (!hasValidData && !_noCertificate) {
      _showSnackBar(
        'Please add at least one valid certification with all fields filled or select "I don\'t have a teaching certificate"',
        const Color.fromARGB(255, 0, 0, 0),
      );
    }

    return hasValidData || _noCertificate;
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _saveDataLocally() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> certificationsJson = [];

      if (!_noCertificate) {
        for (int i = 0; i < _certificationForms.length; i++) {
          final subject = _subjectControllers[i]?.text.trim();
          final certificate = _certificateControllers[i]?.text.trim();
          final description = _descriptionControllers[i]?.text.trim();
          final issuedBy = _issuedByControllers[i]?.text.trim();
          final startYear = _startYears[i];
          final endYear = _endYears[i];
          final fileName = _selectedFileNames[i];
          final fileUrl = _fileUrls[i];

          if (subject != null && subject.isNotEmpty ||
              certificate != null && certificate.isNotEmpty ||
              description != null && description.isNotEmpty ||
              issuedBy != null && issuedBy.isNotEmpty ||
              startYear != null ||
              endYear != null ||
              fileName != null ||
              fileUrl != null) {
            final certData = {
              'subject': subject ?? '',
              'certification': certificate ?? '',
              'description': description ?? '',
              'issuedBy': issuedBy ?? '',
              'startYear': startYear,
              'endYear': endYear,
              'fileName': fileName,
              'fileUrl': fileUrl,
            };
            certificationsJson.add(jsonEncode(certData));
          }
        }
      }

      await prefs.setStringList('certifications', certificationsJson);
      await prefs.setBool('noCertificate', _noCertificate);
    } catch (e) {
      print('Error saving certifications locally: $e');
    }
  }

  Future<void> _saveData() async {
    if (!_validateCertificationData()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> certificationsJson = [];

      if (!_noCertificate) {
        for (int i = 0; i < _certificationForms.length; i++) {
          final subject = _subjectControllers[i]?.text.trim();
          final certificate = _certificateControllers[i]?.text.trim();
          if (subject == null ||
              subject.isEmpty ||
              certificate == null ||
              certificate.isEmpty) {
            continue;
          }

          String? fileUrl = _fileUrls[i];
          if (_selectedFiles[i] != null) {
            final storageRef = FirebaseStorage.instance.ref().child(
                'teacher_certificates/${widget.id}/${DateTime.now().millisecondsSinceEpoch}_${_selectedFileNames[i]}');
            await storageRef
                .putFile(_selectedFiles[i]!)
                .timeout(const Duration(seconds: 30));
            fileUrl = await storageRef.getDownloadURL();
          }

          final certData = {
            'subject': subject,
            'certification': certificate,
            'description': _descriptionControllers[i]?.text.trim() ?? '',
            'issuedBy': _issuedByControllers[i]?.text.trim() ?? '',
            'startYear': _startYears[i],
            'endYear': _endYears[i],
            'fileName': _selectedFileNames[i],
            'fileUrl': fileUrl,
          };
          certificationsJson.add(jsonEncode(certData));
          if (mounted) {
            setState(() {
              _fileUrls[i] = fileUrl;
            });
          }
        }
      }

      await prefs.setStringList('certifications', certificationsJson);
      await prefs.setBool('noCertificate', _noCertificate);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EducationScreen(id: widget.id),
        ),
      );
    } on FirebaseException catch (e) {
      print('Firebase error saving file: $e');
      String errorMessage;
      switch (e.code) {
        case 'storage/unauthorized':
          errorMessage =
              'Unauthorized access to Firebase Storage. Please check your permissions.';
          break;
        case 'storage/quota-exceeded':
          errorMessage = 'Storage quota exceeded. Please contact support.';
          break;
        case 'storage/retry-limit-exceeded':
          errorMessage =
              'Upload failed due to network issues. Please try again.';
          break;
        default:
          errorMessage = 'Firebase error: ${e.message ?? e.toString()}';
      }
      if (mounted) {
        _showSnackBar(errorMessage, const Color.fromARGB(255, 0, 0, 0));
      }
    } on TimeoutException catch (e) {
      print('Upload timeout: $e');
      if (mounted) {
        _showSnackBar('Upload timed out, please try again',
            const Color.fromARGB(255, 0, 0, 0));
      }
    } catch (e) {
      print('Error saving certifications: $e');
      if (mounted) {
        _showSnackBar('Error saving certifications: $e',
            const Color.fromARGB(255, 0, 0, 0));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleBackNavigation() {
    _saveDataLocally();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePhotoScreen(id: widget.id),
        ),
      );
    }
  }

  void _handleNextNavigation() {
    if (_validateCertificationData()) {
      _saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Text(
                        'Teaching certification',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color.fromARGB(255, 255, 144, 187),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Do you have teaching certificates? If so, describe them to enhance your profile credibility.',
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _noCertificate,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _noCertificate = value ?? false;
                                    });
                                    _saveDataLocally();
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'I don\'t have a teaching certificate',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (!_noCertificate) ...[
                            ...List.generate(_certificationForms.length,
                                (index) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (index > 0)
                                    const Divider(height: 40, thickness: 1),
                                  if (index > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 16, bottom: 24),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Certificate ${index + 1}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Color.fromARGB(
                                                    255, 0, 0, 0)),
                                            onPressed: () =>
                                                _removeCertification(index),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Text('Subject',
                                      style: GoogleFonts.poppins(fontSize: 16)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _subjectControllers[index],
                                    style: GoogleFonts.poppins(
                                        color: Colors.black),
                                    decoration: InputDecoration(
                                      hintText: 'Choose subject...',
                                      hintStyle: GoogleFonts.poppins(
                                          color: Colors.black54),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade500),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 18),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text('Certificate',
                                      style: GoogleFonts.poppins(fontSize: 16)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _certificateControllers[index],
                                    style: GoogleFonts.poppins(
                                        color: Colors.black),
                                    decoration: InputDecoration(
                                      hintText: 'Certificate name',
                                      hintStyle: GoogleFonts.poppins(
                                          color: Colors.black54),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade500),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 18),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text('Description',
                                      style: GoogleFonts.poppins(fontSize: 16)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _descriptionControllers[index],
                                    style: GoogleFonts.poppins(
                                        color: Colors.black),
                                    minLines: 3,
                                    maxLines: 5,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Briefly describe your certification',
                                      hintStyle: GoogleFonts.poppins(
                                          color: Colors.black54),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade500),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 18),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text('Issued by',
                                      style: GoogleFonts.poppins(fontSize: 16)),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _issuedByControllers[index],
                                    style: GoogleFonts.poppins(
                                        color: Colors.black),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Institution or organization name',
                                      hintStyle: GoogleFonts.poppins(
                                          color: Colors.black54),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade500),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 18),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text('Start Year',
                                      style: GoogleFonts.poppins(fontSize: 16)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _startYears[index],
                                    hint: Text('Select Year',
                                        style: GoogleFonts.poppins(
                                            color: Colors.black54)),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade500),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 18),
                                    ),
                                    items: _years.map((String year) {
                                      return DropdownMenuItem<String>(
                                        value: year,
                                        child: Text(year,
                                            style: GoogleFonts.poppins(
                                                fontSize: 16)),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _startYears[index] = newValue;
                                      });
                                      _saveDataLocally();
                                    },
                                    dropdownColor: Colors.white,
                                  ),
                                  const SizedBox(height: 24),
                                  Text('End Year (or Present)',
                                      style: GoogleFonts.poppins(fontSize: 16)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _endYears[index],
                                    hint: Text('Select Year',
                                        style: GoogleFonts.poppins(
                                            color: Colors.black54)),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade500),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 18),
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: 'Present',
                                        child: Text('Present',
                                            style: GoogleFonts.poppins(
                                                fontSize: 12)),
                                      ),
                                      ..._years.map((String year) {
                                        return DropdownMenuItem(
                                          value: year,
                                          child: Text(year,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 16)),
                                        );
                                      }),
                                    ],
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _endYears[index] = newValue;
                                      });
                                      _saveDataLocally();
                                    },
                                    dropdownColor: Colors.white,
                                  ),
                                  const SizedBox(height: 24),
                                  Text('Upload Certificate (Max 20MB, JPG/PNG)',
                                      style: GoogleFonts.poppins(fontSize: 16)),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _pickFile(index),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.upload_file,
                                              color: Colors.black),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _selectedFileNames[index] ??
                                                  'No file selected',
                                              style: GoogleFonts.poppins(
                                                  color: Colors.black),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (_selectedFileNames[index] != null)
                                            const Icon(Icons.check_circle,
                                                color: Color.fromARGB(
                                                    255, 86, 186, 50)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_fileErrors[index] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        _fileErrors[index]!,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 12,
                                          backgroundColor: Colors.red,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 24),
                                ],
                              );
                            }),
                          ],
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _addAnotherCertification,
                              icon: const Icon(Icons.add_circle_outline,
                                  color: Color.fromARGB(255, 0, 0, 0)),
                              label: Text(
                                'Add Another Certificate',
                                style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
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
                                    side: const BorderSide(
                                        color: Color.fromARGB(255, 0, 0, 0)),
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
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
