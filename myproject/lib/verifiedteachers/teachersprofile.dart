import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'homescreen.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  _TeacherProfileScreenState createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  bool _isEditing = false;
  Map<String, dynamic> _editableData = {};
  String? _teacherId;
  String? _teacherEmail;

  // Material Design color scheme
  final _primaryColor = const Color.fromARGB(255, 255, 144, 187);
  final _secondaryColor = const Color(0xFF00C853);
  final _errorColor = const Color(0xFFD32F2F);
  final _warningColor = const Color(0xFFF57C00);
  final _surfaceColor = const Color(0xFFFAFAFA);
  final _backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _getCurrentTeacherId();
  }

  Future<void> _getCurrentTeacherId() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _teacherEmail = user.email ?? 'No email available';
      });
      print('Teacher Email: $_teacherEmail');

      try {
        final querySnapshot = await _firestore
            .collection('teachers')
            .where('authUid', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            _teacherId = querySnapshot.docs.first.id;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('No teacher profile found. Please create a profile.'),
              backgroundColor: _warningColor,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching profile: $e'),
            backgroundColor: _errorColor,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please sign in to view your profile.'),
          backgroundColor: _errorColor,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _toggleEditMode(Map<String, dynamic> teacherData) async {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _editableData = {
          'about': Map<String, dynamic>.from(teacherData['about'] ?? {}),
          'description':
              Map<String, dynamic>.from(teacherData['description'] ?? {}),
          'pricing': Map<String, dynamic>.from(teacherData['pricing'] ?? {}),
          'availability': {
            'timezone': teacherData['availability']?['timezone'] ?? '',
            'days': Map<String, dynamic>.from(
                teacherData['availability']?['days'] ?? {}),
          },
          'video': Map<String, dynamic>.from(teacherData['video'] ?? {}),
          'certifications': List<Map<String, dynamic>>.from(
              (teacherData['certifications'] as List<dynamic>?)
                      ?.map((cert) => Map<String, dynamic>.from(cert ?? {})) ??
                  []),
          'education': List<Map<String, dynamic>>.from(
              (teacherData['education'] as List<dynamic>?)
                      ?.map((edu) => Map<String, dynamic>.from(edu ?? {})) ??
                  []),
          'profilePhoto': {
            'profilePhotoUrl':
                teacherData['profilePhoto']?['profilePhotoUrl'] ?? '',
          },
        };
      } else {
        _editableData = {};
      }
    });
  }

  Future<void> _saveChanges() async {
    if (_teacherId == null) return;

    try {
      await _firestore.collection('teachers').doc(_teacherId).update({
        'about': _editableData['about'],
        'description': _editableData['description'],
        'pricing': _editableData['pricing'],
        'availability': _editableData['availability'],
        'video': _editableData['video'],
        'certifications': _editableData['certifications'],
        'education': _editableData['education'],
        'profilePhoto': _editableData['profilePhoto'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isEditing = false;
        _editableData = {};
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully!',
              style: GoogleFonts.poppins()),
          backgroundColor: _secondaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error updating profile: $e', style: GoogleFonts.poppins()),
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  Future<void> _pickAndUploadProfilePicture() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      try {
        final storageRef = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('teacher_profiles/$_teacherId/profile.jpg');
        await storageRef.putFile(File(pickedFile.path));
        final downloadUrl = await storageRef.getDownloadURL();

        setState(() {
          _editableData['profilePhoto']['profilePhotoUrl'] = downloadUrl;
        });

        if (_teacherId != null) {
          await _firestore.collection('teachers').doc(_teacherId).update({
            'profilePhoto.profilePhotoUrl': downloadUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture updated successfully!',
                style: GoogleFonts.poppins()),
            backgroundColor: _secondaryColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading profile picture: $e',
                style: GoogleFonts.poppins()),
            backgroundColor: _errorColor,
          ),
        );
      }
    }
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required IconData icon,
    required String fieldPath,
    bool isMultiline = false,
  }) {
    if (_isEditing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              initialValue: value,
              maxLines: isMultiline ? 3 : 1,
              decoration: InputDecoration(
                prefixIcon: Icon(icon),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (newValue) {
                final parts = fieldPath.split('.');
                setState(() {
                  if (parts.length == 2) {
                    _editableData[parts[0]][parts[1]] = newValue;
                  } else if (parts.length == 3) {
                    _editableData[parts[0]][parts[1]][parts[2]] = newValue;
                  }
                });
              },
            ),
          ],
        ),
      );
    } else {
      return _buildDetailItem(label, value, icon);
    }
  }

  Widget _buildEditableNumberField({
    required String label,
    required double value,
    required IconData icon,
    required String fieldPath,
  }) {
    if (_isEditing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              initialValue: value.toString(),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
              ],
              decoration: InputDecoration(
                prefixIcon: Icon(icon),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (newValue) {
                final parts = fieldPath.split('.');
                setState(() {
                  if (parts.length == 2) {
                    _editableData[parts[0]][parts[1]] =
                        double.tryParse(newValue) ?? value;
                  }
                });
              },
            ),
          ],
        ),
      );
    } else {
      return _buildDetailItem(label, '\$$value/hr', icon);
    }
  }

  Widget _buildCertificationEditor(
      List<Map<String, dynamic>> certifications, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Certification ${index + 1}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                IconButton(
                    icon: Icon(Icons.delete, color: _errorColor),
                    onPressed: () {
                      setState(() {
                        _editableData['certifications'].removeAt(index);
                      });
                    }),
              ],
            ),
            TextFormField(
              initialValue: certifications[index]['certification'] ?? '',
              decoration: InputDecoration(labelText: 'Certification Name'),
              onChanged: (value) => _editableData['certifications'][index]
                  ['certification'] = value,
            ),
            TextFormField(
              initialValue: certifications[index]['subject'] ?? '',
              decoration: InputDecoration(labelText: 'Subject'),
              onChanged: (value) =>
                  _editableData['certifications'][index]['subject'] = value,
            ),
            TextFormField(
              initialValue: certifications[index]['description'] ?? '',
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 2,
              onChanged: (value) =>
                  _editableData['certifications'][index]['description'] = value,
            ),
            TextFormField(
              initialValue: certifications[index]['issuedBy'] ?? '',
              decoration: InputDecoration(labelText: 'Issued By'),
              onChanged: (value) =>
                  _editableData['certifications'][index]['issuedBy'] = value,
            ),
            TextFormField(
              initialValue:
                  certifications[index]['startYear']?.toString() ?? '',
              decoration: InputDecoration(labelText: 'Start Year'),
              keyboardType: TextInputType.number,
              onChanged: (value) => _editableData['certifications'][index]
                  ['startYear'] = int.tryParse(value),
            ),
            TextFormField(
              initialValue: certifications[index]['endYear']?.toString() ?? '',
              decoration: InputDecoration(labelText: 'End Year'),
              keyboardType: TextInputType.number,
              onChanged: (value) => _editableData['certifications'][index]
                  ['endYear'] = int.tryParse(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationEditor(
      List<Map<String, dynamic>> education, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Education ${index + 1}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                IconButton(
                    icon: Icon(Icons.delete, color: _errorColor),
                    onPressed: () {
                      setState(() {
                        _editableData['education'].removeAt(index);
                      });
                    }),
              ],
            ),
            TextFormField(
              initialValue: education[index]['degree'] ?? '',
              decoration: InputDecoration(labelText: 'Degree'),
              onChanged: (value) =>
                  _editableData['education'][index]['degree'] = value,
            ),
            TextFormField(
              initialValue: education[index]['degree_type'] ?? '',
              decoration: InputDecoration(labelText: 'Degree Type'),
              onChanged: (value) =>
                  _editableData['education'][index]['degree_type'] = value,
            ),
            TextFormField(
              initialValue: education[index]['specialization'] ?? '',
              decoration: InputDecoration(labelText: 'Specialization'),
              onChanged: (value) =>
                  _editableData['education'][index]['specialization'] = value,
            ),
            TextFormField(
              initialValue: education[index]['university'] ?? '',
              decoration: InputDecoration(labelText: 'University'),
              onChanged: (value) =>
                  _editableData['education'][index]['university'] = value,
            ),
            TextFormField(
              initialValue: education[index]['start_year']?.toString() ?? '',
              decoration: InputDecoration(labelText: 'Start Year'),
              keyboardType: TextInputType.number,
              onChanged: (value) => _editableData['education'][index]
                  ['start_year'] = int.tryParse(value),
            ),
            TextFormField(
              initialValue: education[index]['end_year']?.toString() ?? '',
              decoration: InputDecoration(labelText: 'End Year'),
              keyboardType: TextInputType.number,
              onChanged: (value) => _editableData['education'][index]
                  ['end_year'] = int.tryParse(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityEditor(Map<String, dynamic> days) {
    return Column(
      children: days.entries.map((entry) {
        final day = entry.key;
        final dayData = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: _surfaceColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(day,
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    Switch(
                      value: dayData['enabled'] ?? false,
                      onChanged: (value) {
                        setState(() {
                          _editableData['availability']['days'][day]
                              ['enabled'] = value;
                        });
                      },
                    ),
                  ],
                ),
                if (dayData['enabled']) ...[
                  const SizedBox(height: 8),
                  ...List<Widget>.generate(
                      (dayData['slots'] as List<dynamic>? ?? []).length,
                      (index) {
                    return Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: (dayData['slots'] as List<dynamic>? ??
                                    [])[index]['from'] ??
                                '',
                            decoration: InputDecoration(labelText: 'From'),
                            onChanged: (value) => _editableData['availability']
                                ['days'][day]['slots'][index]['from'] = value,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: (dayData['slots'] as List<dynamic>? ??
                                    [])[index]['to'] ??
                                '',
                            decoration: InputDecoration(labelText: 'To'),
                            onChanged: (value) => _editableData['availability']
                                ['days'][day]['slots'][index]['to'] = value,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: _errorColor),
                          onPressed: () {
                            setState(() {
                              _editableData['availability']['days'][day]
                                      ['slots']
                                  .removeAt(index);
                            });
                          },
                        ),
                      ],
                    );
                  }),
                  TextButton.icon(
                    icon: Icon(Icons.add, color: _primaryColor),
                    label: Text('Add Slot',
                        style: GoogleFonts.poppins(color: _primaryColor)),
                    onPressed: () {
                      setState(() {
                        _editableData['availability']['days'][day]['slots']
                            .add({'from': '', 'to': ''});
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          primary: _primaryColor,
          secondary: _secondaryColor,
          error: _errorColor,
          surface: _surfaceColor,
          background: _backgroundColor,
        ),
      ),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: _teacherId == null
            ? _buildLoadingState()
            : StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('teachers')
                    .doc(_teacherId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState(snapshot.error.toString());
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return _buildEmptyState();
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final about = data['about'] as Map<String, dynamic>? ?? {};
                  final firstName = about['firstName']?.toString() ?? 'Unknown';
                  final lastName = about['lastName']?.toString() ?? '';
                  final fullName = '$firstName $lastName'.trim();
                  final certifications =
                      (data['certifications'] as List<dynamic>?)
                              ?.map((cert) => cert as Map<String, dynamic>)
                              .toList() ??
                          [];
                  final education = (data['education'] as List<dynamic>?)
                          ?.map((edu) => edu as Map<String, dynamic>)
                          .toList() ??
                      [];
                  final description =
                      data['description'] as Map<String, dynamic>? ?? {};
                  final video = data['video'] as Map<String, dynamic>? ?? {};
                  final availability =
                      data['availability'] as Map<String, dynamic>? ?? {};
                  final days = (availability['days'] as Map<String, dynamic>?)
                          ?.map((day, dayData) {
                        final slots = (dayData['slots'] as List<dynamic>?)
                                ?.map((slot) => slot as Map<String, dynamic>)
                                .toList() ??
                            [];
                        return MapEntry(day, {
                          'enabled': dayData['enabled'] as bool? ?? false,
                          'slots': slots,
                        });
                      }) ??
                      {};
                  final pricing =
                      data['pricing'] as Map<String, dynamic>? ?? {};
                  final profilePhotoUrl =
                      data['profilePhoto']?['profilePhotoUrl']?.toString() ??
                          '';

                  final teacher = {
                    'uid': _teacherId,
                    'fullName': fullName.isNotEmpty ? fullName : 'Unknown',
                    'email': _teacherEmail ??
                        about['email']?.toString() ??
                        'No email',
                    'teachingCourse': about['teachingCourse']?.toString() ?? '',
                    'createdAt': data['createdAt'] ?? Timestamp.now(),
                    'profileComplete': about.isNotEmpty &&
                        profilePhotoUrl.isNotEmpty &&
                        certifications.isNotEmpty &&
                        education.isNotEmpty &&
                        description.isNotEmpty &&
                        video.isNotEmpty &&
                        availability.isNotEmpty &&
                        pricing.isNotEmpty,
                    'data': {
                      'about': {
                        'firstName': firstName,
                        'lastName': lastName,
                        'country': about['country']?.toString() ?? '',
                        'email':
                            _teacherEmail ?? about['email']?.toString() ?? '',
                        'phoneNumber': about['phoneNumber']?.toString() ?? '',
                        'teachingCourse':
                            about['teachingCourse']?.toString() ?? '',
                      },
                      'profilePhoto': {
                        'profilePhotoUrl': profilePhotoUrl,
                      },
                      'certifications': certifications,
                      'education': education,
                      'description': {
                        'intro': description['intro']?.toString() ?? '',
                        'experience':
                            description['experience']?.toString() ?? '',
                        'motivation':
                            description['motivation']?.toString() ?? '',
                      },
                      'video': {
                        'videoUrl': video['videoUrl']?.toString() ?? '',
                      },
                      'availability': {
                        'timezone': availability['timezone']?.toString() ?? '',
                        'days': days,
                      },
                      'pricing': {
                        'standardRate':
                            pricing['standardRate']?.toDouble() ?? 0.0,
                        'introRate': pricing['introRate']?.toDouble(),
                      },
                      'status': data['status']?.toString() ?? 'verified',
                      'createdAt': data['createdAt'],
                      'updatedAt': data['updatedAt'],
                    },
                  };

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _buildSliverAppBar(),
                      SliverToBoxAdapter(
                        child: _buildTeacherDetailsContent(teacher),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 110,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: _primaryColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TutorScreen()),
          );
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'My Profile',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 21,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _primaryColor,
                Color.lerp(_primaryColor, Colors.black, 0.2)!,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text('Loading profile...',
              style:
                  GoogleFonts.poppins(color: Colors.grey[700], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: _errorColor, size: 64),
          const SizedBox(height: 16),
          Text('Oops! Something went wrong',
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900])),
          const SizedBox(height: 8),
          Text(error,
              style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 16),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: Text('Try Again',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, color: Colors.grey[400], size: 80),
          const SizedBox(height: 24),
          Text('Profile not found',
              style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900])),
          const SizedBox(height: 8),
          Text('Your teacher profile could not be loaded',
              style:
                  GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTeacherDetailsContent(Map<String, dynamic> teacher) {
    final data = _isEditing ? _editableData : teacher['data'];
    final createdAt = (teacher['createdAt'] as Timestamp?)?.toDate();
    final certifications = data['certifications'] as List<dynamic>;
    final education = data['education'] as List<dynamic>;
    final availability = data['availability']['days'] as Map<String, dynamic>;
    final profilePhotoUrl =
        data['profilePhoto']['profilePhotoUrl']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Hero(
                      tag: 'avatar-${teacher['uid']}',
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: _primaryColor,
                        backgroundImage: profilePhotoUrl.isNotEmpty
                            ? NetworkImage(profilePhotoUrl)
                            : null,
                        child: profilePhotoUrl.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                    if (_isEditing)
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: _primaryColor,
                          child: IconButton(
                            icon: Icon(Icons.camera_alt,
                                size: 15, color: Colors.white),
                            onPressed: _pickAndUploadProfilePicture,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  teacher['fullName'],
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(
                    teacher['profileComplete']
                        ? 'Profile Complete'
                        : 'Profile Incomplete',
                    style: GoogleFonts.poppins(
                      color: teacher['profileComplete']
                          ? _secondaryColor
                          : _warningColor,
                    ),
                  ),
                  backgroundColor: teacher['profileComplete']
                      ? _secondaryColor.withOpacity(0.1)
                      : _warningColor.withOpacity(0.1),
                  avatar: Icon(
                    teacher['profileComplete']
                        ? Icons.check_circle
                        : Icons.warning,
                    color: teacher['profileComplete']
                        ? _secondaryColor
                        : _warningColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('About'),
          _buildEditableField(
            label: 'First Name',
            value: data['about']['firstName'] ?? 'Not provided',
            icon: Icons.person,
            fieldPath: 'about.firstName',
          ),
          _buildEditableField(
            label: 'Last Name',
            value: data['about']['lastName'] ?? 'Not provided',
            icon: Icons.person,
            fieldPath: 'about.lastName',
          ),
          _buildEditableField(
            label: 'Email',
            value: data['about']['email'] ?? 'Not provided',
            icon: Icons.email,
            fieldPath: 'about.email',
          ),
          _buildEditableField(
            label: 'Phone',
            value: data['about']['phoneNumber'] ?? 'Not provided',
            icon: Icons.phone,
            fieldPath: 'about.phoneNumber',
          ),
          _buildEditableField(
            label: 'Country',
            value: data['about']['country'] ?? 'Not specified',
            icon: Icons.location_on,
            fieldPath: 'about.country',
          ),
          _buildEditableField(
            label: 'Teaching Course',
            value: data['about']['teachingCourse'] ?? 'Not specified',
            icon: Icons.subject,
            fieldPath: 'about.teachingCourse',
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Profile Photo'),
          _buildEditableField(
            label: 'Photo URL',
            value: data['profilePhoto']['profilePhotoUrl'] ?? 'Not provided',
            icon: Icons.image,
            fieldPath: 'profilePhoto.profilePhotoUrl',
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Description'),
          _buildEditableField(
            label: 'Introduction',
            value: data['description']['intro'] ?? 'Not provided',
            icon: Icons.info,
            fieldPath: 'description.intro',
            isMultiline: true,
          ),
          _buildEditableField(
            label: 'Experience',
            value: data['description']['experience'] ?? 'Not provided',
            icon: Icons.work,
            fieldPath: 'description.experience',
            isMultiline: true,
          ),
          _buildEditableField(
            label: 'Motivation',
            value: data['description']['motivation'] ?? 'Not provided',
            icon: Icons.star,
            fieldPath: 'description.motivation',
            isMultiline: true,
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Certifications'),
          if (_isEditing) ...[
            ...List.generate(
                certifications.length,
                (index) => _buildCertificationEditor(
                    List<Map<String, dynamic>>.from(certifications), index)),
            TextButton.icon(
              icon: Icon(Icons.add, color: _primaryColor),
              label: Text('Add Certification',
                  style: GoogleFonts.poppins(color: _primaryColor)),
              onPressed: () {
                setState(() {
                  _editableData['certifications'].add({
                    'certification': '',
                    'subject': '',
                    'description': '',
                    'issuedBy': '',
                    'startYear': null,
                    'endYear': null,
                  });
                });
              },
            ),
          ] else ...[
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                child: Column(
                  children: certifications
                      .map((cert) => Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            color: const Color.fromARGB(255, 243, 243, 243),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Text(
                                            cert['certification'] ??
                                                'Unknown Certification',
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    Expanded(
                                        child: _buildDetailRow('Subject',
                                            cert['subject'] ?? 'N/A'))
                                  ]),
                                  Row(children: [
                                    Expanded(
                                        child: _buildDetailRow('Description',
                                            cert['description'] ?? 'N/A'))
                                  ]),
                                  Row(children: [
                                    Expanded(
                                        child: _buildDetailRow('Issued By',
                                            cert['issuedBy'] ?? 'N/A'))
                                  ]),
                                  Row(children: [
                                    Expanded(
                                        child: _buildDetailRow('Years',
                                            '${cert['startYear'] ?? 'N/A'} - ${cert['endYear'] ?? 'N/A'}'))
                                  ]),
                                  if (cert['fileName'] != null &&
                                      cert['fileName'].isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: TextButton.icon(
                                        onPressed: () {},
                                        icon: Icon(Icons.file_present,
                                            color: _primaryColor, size: 20),
                                        label: Text('View Document',
                                            style: GoogleFonts.poppins(
                                                color: _primaryColor)),
                                      ),
                                    ),
                                  if (cert['fileUrl'] != null &&
                                      cert['fileUrl'].isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: TextButton.icon(
                                        onPressed: () {},
                                        icon: Icon(Icons.link,
                                            color: _primaryColor, size: 20),
                                        label: Text('View File URL',
                                            style: GoogleFonts.poppins(
                                                color: _primaryColor)),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildSectionTitle('Education'),
          if (_isEditing) ...[
            ...List.generate(
                education.length,
                (index) => _buildEducationEditor(
                    List<Map<String, dynamic>>.from(education), index)),
            TextButton.icon(
              icon: Icon(Icons.add, color: _primaryColor),
              label: Text('Add Education',
                  style: GoogleFonts.poppins(color: _primaryColor)),
              onPressed: () {
                setState(() {
                  _editableData['education'].add({
                    'degree': '',
                    'degree_type': '',
                    'specialization': '',
                    'university': '',
                    'start_year': null,
                    'end_year': null,
                  });
                });
              },
            ),
          ] else ...[
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                child: Column(
                  children: education
                      .map((edu) => Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            color: const Color.fromARGB(255, 243, 243, 243),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Text(
                                            '${edu['degree'] ?? 'Unknown'} (${edu['degree_type'] ?? ''})',
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if ((edu['specialization'] ?? '')
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Text(
                                              'in ${edu['specialization']}',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.grey[600]),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    Expanded(
                                        child: _buildDetailRow('University',
                                            edu['university'] ?? 'N/A'))
                                  ]),
                                  Row(children: [
                                    Expanded(
                                        child: _buildDetailRow('Degree Type',
                                            edu['degree_type'] ?? 'N/A'))
                                  ]),
                                  Row(children: [
                                    Expanded(
                                        child: _buildDetailRow('Specialization',
                                            edu['specialization'] ?? 'N/A'))
                                  ]),
                                  Row(children: [
                                    Expanded(
                                        child: _buildDetailRow('Duration',
                                            '${edu['start_year'] ?? 'N/A'} - ${edu['end_year'] ?? 'N/A'}'))
                                  ]),
                                  if (edu['file_name'] != null &&
                                      edu['file_name'].isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: TextButton.icon(
                                        onPressed: () {},
                                        icon: Icon(Icons.file_present,
                                            color: _primaryColor, size: 20),
                                        label: Text('View Document',
                                            style: GoogleFonts.poppins(
                                                color: _primaryColor)),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildSectionTitle('Video'),
          _buildEditableField(
            label: 'Video URL',
            value: data['video']['videoUrl'] ?? 'Not provided',
            icon: Icons.video_library,
            fieldPath: 'video.videoUrl',
          ),
          const SizedBox(height: 16),
          _buildSectionTitle('Availability'),
          _buildEditableField(
            label: 'Timezone',
            value: data['availability']['timezone'] ?? 'Not specified',
            icon: Icons.access_time,
            fieldPath: 'availability.timezone',
          ),
          if (_isEditing)
            _buildAvailabilityEditor(availability)
          else
            SizedBox(
              height: 150,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: availability.entries
                      .where((entry) => entry.value['enabled'] ?? false)
                      .map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: Card(
                          elevation: 1,
                          color: const Color.fromARGB(255, 234, 234, 234),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: (entry.value['slots']
                                                  as List<dynamic>? ??
                                              [])
                                          .map((slot) => Text(
                                                '${slot['from'] ?? ''} - ${slot['to'] ?? ''}',
                                                style: GoogleFonts.poppins(
                                                    color: Colors.black,
                                                    fontSize: 12),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 16),
          _buildSectionTitle('Pricing'),
          _buildEditableNumberField(
            label: 'Standard Rate',
            value: data['pricing']['standardRate']?.toDouble() ?? 0.0,
            icon: Icons.monetization_on,
            fieldPath: 'pricing.standardRate',
          ),
          _buildEditableNumberField(
            label: 'Intro Rate',
            value: data['pricing']['introRate']?.toDouble() ?? 0.0,
            icon: Icons.monetization_on,
            fieldPath: 'pricing.introRate',
          ),
          if (createdAt != null) ...[
            const SizedBox(height: 16),
            _buildSectionTitle('Registration'),
            _buildDetailItem(
              'Created At',
              '${createdAt.day}/${createdAt.month}/${createdAt.year}',
              Icons.calendar_today,
            ),
          ],
          const SizedBox(height: 24),
          _buildSectionTitle('Actions'),
          const SizedBox(height: 12),
          if (_isEditing) ...[
            ElevatedButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save, size: 20),
              label: Text('Save Changes',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _toggleEditMode(teacher['data']),
              icon: const Icon(Icons.cancel, size: 20),
              label: Text('Cancel',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[700]!),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: () => _toggleEditMode(teacher['data']),
              icon: const Icon(Icons.edit, size: 20),
              label: Text('Edit Profile',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[900]),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                      fontSize: 16, color: Colors.grey[900]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ',
              style:
                  GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14)),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(value,
                  style: GoogleFonts.poppins(
                      color: Colors.grey[900], fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
