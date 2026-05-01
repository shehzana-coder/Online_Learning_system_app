import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'aboutinfo1.dart';
import 'certification3.dart';

class ProfilePhotoScreen extends StatefulWidget {
  final String id; // Firebase UID
  const ProfilePhotoScreen({super.key, required this.id});

  @override
  _ProfilePhotoScreenState createState() => _ProfilePhotoScreenState();
}

class _ProfilePhotoScreenState extends State<ProfilePhotoScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _teacherName;
  String? _teachesSubject;
  List<String> _speaksLanguages = [];
  String? _profileImageUrl;

  // Languages list synced with AboutTutorForm
  final List<String> validLanguages = [
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

  @override
  void initState() {
    super.initState();
    _loadTeacherData().then((_) {
      setState(() {}); // Ensure UI updates after data load
    }).catchError((e) {
      print('Error in initState: $e');
    });
  }

  Future<void> _loadTeacherData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final firstName = prefs.getString('firstName') ?? '';
      final lastName = prefs.getString('lastName') ?? '';
      final languagesJson = prefs.getStringList('languages') ?? [];
      final teachingLanguage = prefs.getString('teachingLanguage') ?? 'lessons';
      final profilePhotoUrl = prefs.getString('photo_url') ??
          'https://firebasestorage.googleapis.com/v0/b/speakora-2b8c6.appspot.com/o/teacher_profile_photos%2Fdefault.png?alt=media&token=default-token';

      final languages = languagesJson.map((json) {
        final Map<String, String> entry =
            Map<String, String>.from(jsonDecode(json));
        return '${entry['language']} (${entry['level']})';
      }).toList();

      if (mounted) {
        setState(() {
          _teacherName = '$firstName $lastName'.trim();
          _speaksLanguages = languages;
          _teachesSubject = validLanguages.contains(teachingLanguage)
              ? 'Teaches $teachingLanguage'
              : 'Teaches lessons';
          _profileImageUrl = profilePhotoUrl;
        });
      }
    } catch (e) {
      print('Error loading teacher data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile data: $e',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
    }
  }

  Future<bool> _ensureGalleryPermission() async {
    var status = await Permission.photos.status;
    if (!status.isGranted) {
      if (status.isDenied) {
        final result = await Permission.photos.request();
        status = result;
      } else if (status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please enable gallery access in settings',
                  style:
                      GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        return false;
      }
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gallery permission denied',
                  style:
                      GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            ),
          );
        }
        return false;
      }
    }
    return true;
  }

  Future<bool> _ensureCameraPermission() async {
    var status = await Permission.camera.status;
    print('Camera permission status: $status');
    if (!status.isGranted) {
      if (status.isDenied) {
        final result = await Permission.camera.request();
        print('Camera permission request result: $result');
        status = result;
      } else if (status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please enable camera access in settings',
                  style:
                      GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        return false;
      }
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Camera permission denied',
                  style:
                      GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            ),
          );
        }
        return false;
      }
    }
    return true;
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    bool hasPermission = false;
    if (source == ImageSource.gallery) {
      hasPermission = await _ensureGalleryPermission();
    } else if (source == ImageSource.camera) {
      hasPermission = await _ensureCameraPermission();
    }
    if (!hasPermission) {
      print('Permission not granted for $source, aborting image picking');
      return;
    }

    print('Opening $source to pick image');
    XFile? image;
    try {
      image = await _picker.pickImage(source: source);
    } catch (e) {
      print('Error picking image from $source: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing $source: ${e.toString()}',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
      setState(() {
        _selectedImage = null;
      });
      return;
    }

    if (image == null) {
      print('No image selected from $source');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No image selected from $source',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
      return;
    }

    final file = File(image.path);
    print('Selected file path: ${file.path}');
    // Validate image size and format
    try {
      final sizeInMB = await file.length() / (1024 * 1024);
      print('Image size: $sizeInMB MB');
      if (sizeInMB > 6) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image size must be less than 6MB',
                  style:
                      GoogleFonts.poppins(color: Colors.white, fontSize: 18)),
              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            ),
          );
        }
        return;
      }
      final extension = image.path.trim().toLowerCase().split('.').last;
      print('Image extension: $extension');
      if (!['jpg', 'jpeg', 'png'].contains(extension)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Only JPG or PNG images are allowed',
                  style:
                      GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            ),
          );
        }
        return;
      }
    } catch (e) {
      print('Error validating image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing image: $e',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
      return;
    }

    setState(() {
      _selectedImage = file;
      _isLoading = true;
    });

    try {
      print('Starting upload to Firebase Storage');
      final extension =
          image.path.toLowerCase().split('.').last; // Dynamic extension
      final storageRef = FirebaseStorage.instance.ref().child(
          'teacher_profile_photos/${widget.id}/${DateTime.now().millisecondsSinceEpoch}.$extension');
      final uploadTask = storageRef.putFile(_selectedImage!);
      print('Upload task initiated');
      await uploadTask
          .whenComplete(() => print('Upload completed'))
          .timeout(const Duration(seconds: 120));
      final imageUrl = await storageRef.getDownloadURL();
      print('Download URL: $imageUrl');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('photo_url', imageUrl);
      if (mounted) {
        setState(() {
          _profileImageUrl = imageUrl;
          _selectedImage = null; // Clear selected image after successful upload
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile photo uploaded successfully!',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on TimeoutException catch (e) {
      print('Upload timeout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload timed out, please try again',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
            backgroundColor: Colors.black,
          ),
        );
      }
    } on FirebaseException catch (e) {
      print('Firebase error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firebase error: ${e.message ?? e.toString()}',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
            backgroundColor: Colors.black,
          ),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $e',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
            backgroundColor: Colors.black,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleBackNavigation() async {
    if (mounted) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final firstName = prefs.getString('firstName') ?? '';
      final lastName = prefs.getString('lastName') ?? '';
      final email = prefs.getString('email') ?? '';
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AboutTutorForm(
            id: widget.id,
            firstName: firstName,
            lastName: lastName,
            email: email,
          ),
        ),
      );
    }
  }

  Future<void> _handleNextNavigation() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      // Define the default URL for comparison
      const String defaultProfileUrl =
          'https://firebasestorage.googleapis.com/v0/b/speakora-2b8c6.appspot.com/o/teacher_profile_photos%2Fdefault.png?alt=media&token=default-token';
      // Check if a non-default profile photo URL exists in SharedPreferences
      final updatedProfileUrl = prefs.getString('photo_url');

      // If no photo is uploaded (i.e., URL is null or still the default), show error
      if (updatedProfileUrl == null || updatedProfileUrl == defaultProfileUrl) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please upload a photo before continuing',
                  style:
                      GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
              backgroundColor: Colors.black,
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CertificationScreen(id: widget.id),
          ),
        );
      }
    } catch (e) {
      print('Error navigating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error proceeding: $e',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    if (_selectedImage != null && _profileImageUrl == null) {
      _selectedImage!.deleteSync(); // Clean up temporary file if not uploaded
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Photo',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 1,
                          color: Color.fromARGB(255, 255, 144, 187),
                          width: double.infinity,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select and upload the photo that will appear to your students',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: _selectedImage != null
                                    ? Image.file(
                                        _selectedImage!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      )
                                    : _profileImageUrl != null
                                        ? Image.network(
                                            _profileImageUrl!,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Image.asset(
                                              'assets/images/3.png',
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Image.asset(
                                            'assets/images/3.png',
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _teacherName ?? 'Loading...',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      _teachesSubject ?? '',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildLanguageText(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                  content: Container(
                                    width: MediaQuery.of(context).size.width *
                                        0.95, // Increased width
                                    height: MediaQuery.of(context).size.height *
                                        0.45, // Increased height
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color.fromARGB(
                                              255, 171, 249, 255), // Light pink
                                          Color.fromARGB(
                                              255, 199, 185, 185), // White
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(12)),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              24, 24, 24, 8),
                                          child: Text(
                                            'Select Image Source',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize:
                                                  20, // Slightly larger title
                                            ),
                                          ),
                                        ),
                                        const Divider(
                                            color: Colors.grey, height: 1),
                                        ListTile(
                                          leading: const Icon(Icons.image,
                                              color: Colors.teal,
                                              size: 30), // Larger icon
                                          title: Text(
                                            'Gallery',
                                            style: GoogleFonts.poppins(
                                                fontSize: 18), // Larger text
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _pickAndUploadImage(
                                                ImageSource.gallery);
                                          },
                                        ),
                                        const Divider(
                                            color: Colors.grey, height: 1),
                                        ListTile(
                                          leading: const Icon(Icons.camera_alt,
                                              color: Colors.purple,
                                              size: 30), // Larger icon
                                          title: Text(
                                            'Camera',
                                            style: GoogleFonts.poppins(
                                                fontSize: 18), // Larger text
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _pickAndUploadImage(
                                                ImageSource.camera);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30,
                                  vertical: 14), // Adjusted padding
                              side: BorderSide(
                                  color: Colors.grey.shade500,
                                  width: 2), // Thicker border
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    12), // Match dialog radius
                              ),
                            ),
                            child: Text(
                              _selectedImage != null
                                  ? 'Update your photo'
                                  : 'Upload your photo',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 18, // Slightly larger text
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'Photo Requirements',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildExamplePhoto('assets/images/2.png'),
                              _buildExamplePhoto('assets/images/3.png'),
                              _buildExamplePhoto('assets/images/4.png'),
                              _buildExamplePhoto('assets/images/5.png'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ..._buildRequirementsList(),
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
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLanguageText() {
    if (_speaksLanguages.isEmpty) {
      return Text('No languages specified', style: GoogleFonts.poppins());
    }
    final int middleIndex = (_speaksLanguages.length / 2).ceil();
    final List<String> firstRow = _speaksLanguages.sublist(0, middleIndex);
    final List<String> secondRow = _speaksLanguages.length > middleIndex
        ? _speaksLanguages.sublist(middleIndex)
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Speaks ${firstRow.join(", ")},',
          style: GoogleFonts.poppins(),
        ),
        if (secondRow.isNotEmpty)
          Text(
            secondRow.join(", "),
            style: GoogleFonts.poppins(),
          ),
      ],
    );
  }

  Widget _buildExamplePhoto(String assetPath) {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  List<Widget> _buildRequirementsList() {
    final requirements = [
      'You should be facing forward',
      'Frame your head and shoulders',
      'You should be centered and upright',
      'Your face and eyes should be visible (except for religious reasons)',
      'You should be the only person in the photo',
      'Use a color photo with high resolution and no filters',
      'Avoid logos or contact information',
    ];

    return requirements.map((requirement) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 255, 144, 187),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                requirement,
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
