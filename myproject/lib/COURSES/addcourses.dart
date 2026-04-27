import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherAddForm extends StatefulWidget {
  const TeacherAddForm({super.key});

  @override
  State<TeacherAddForm> createState() => _TeacherAddFormState();
}

class _TeacherAddFormState extends State<TeacherAddForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Teacher information controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _courseOfDegreeController =
      TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String? _qualification;
  String? _teachingMode;

  // Courses the teacher can teach
  List<Map<String, dynamic>> _teachingCoursesControllers = [];

  // Qualification levels
  final List<String> _qualificationLevels = ['Bachelor', 'Master', 'PhD'];

  // Teaching mode options
  final List<String> _teachingModes = ['Online', 'Offline', 'Both'];

  // Course levels
  final List<String> _courseLevels = [
    'Beginner',
    'Metric',
    'Intermediate',
    'Bachelor',
  ];

  // Class mapping
  final Map<String, List<String>> _classNamesByLevel = {
    'Beginner': ['7', '8'],
    'Metric': ['9', '10'],
    'Intermediate': ['11', '12'],
    'Bachelor': ['13', '14', '15', '16'],
  };

  // Stream options for higher levels
  final List<String> _streamOptions = [
    'ICS',
    'Mathematics',
    'Medical',
    'Commerce',
    'Arts',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _addNewTeachingCourse();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _courseOfDegreeController.dispose();
    _experienceController.dispose();
    _locationController.dispose();

    for (var course in _teachingCoursesControllers) {
      course['subjectTitle']!.dispose();
      course['duration']!.dispose();
      course['tutionHour']!.dispose();
    }

    super.dispose();
  }

  void _addNewTeachingCourse() {
    setState(() {
      _teachingCoursesControllers.add({
        'subjectTitle': TextEditingController(),
        'duration': TextEditingController(),
        'tutionHour': TextEditingController(),
        'courseLevel': null,
        'className': null,
        'stream': null,
      });
    });
  }

  Future<void> _submitTeacher() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // First, add the teacher to Firestore and get the document reference
        DocumentReference teacherRef = await FirebaseFirestore.instance
            .collection('teachers')
            .add({
              'name': _nameController.text.trim(),
              'qualification': _qualification,
              'courseOfDegree': _courseOfDegreeController.text.trim(),
              'teachingMode': _teachingMode,
              'experience': _experienceController.text.trim(),
              'location': _locationController.text.trim(),
              'createdAt': FieldValue.serverTimestamp(),
            });

        // Then add all the courses this teacher can teach
        List<Map<String, dynamic>> teachingCourses = [];
        for (var course in _teachingCoursesControllers) {
          teachingCourses.add({
            'subjectTitle': course['subjectTitle']!.text.trim(),
            'duration': course['duration']!.text.trim(),
            'tutionHour': course['tutionHour']!.text.trim(),
            'courseLevel': course['courseLevel'],
            'className': course['className'],
            'stream': course['stream'],
          });
        }

        // Update the teacher document with the courses they can teach
        await teacherRef.update({'teachingCourses': teachingCourses});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Teacher added successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Clear all fields
          _nameController.clear();
          _courseOfDegreeController.clear();
          _experienceController.clear();
          _locationController.clear();
          setState(() {
            _qualification = null;
            _teachingMode = null;
            _teachingCoursesControllers.clear();
            _addNewTeachingCourse();
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding teacher: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
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
  }

  Widget _buildTeacherInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Teacher Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: _nameController,
          label: 'Teacher Name',
          hint: 'Enter full name of the teacher',
          icon: Icons.person,
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Please enter teacher name'
                      : null,
        ),
        const SizedBox(height: 15),
        _buildDropdownField(
          label: 'Qualification',
          icon: Icons.school,
          items: _qualificationLevels,
          value: _qualification,
          onChanged: (value) {
            setState(() {
              _qualification = value;
            });
          },
          validator:
              (value) => value == null ? 'Please select qualification' : null,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: _courseOfDegreeController,
          label: 'Course of Degree',
          hint: 'e.g., Computer Science, Mathematics',
          icon: Icons.book,
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Please enter course of degree'
                      : null,
        ),
        const SizedBox(height: 15),
        _buildDropdownField(
          label: 'Teaching Mode',
          icon: Icons.computer,
          items: _teachingModes,
          value: _teachingMode,
          onChanged: (value) {
            setState(() {
              _teachingMode = value;
            });
          },
          validator:
              (value) => value == null ? 'Please select teaching mode' : null,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: _experienceController,
          label: 'Teaching Experience',
          hint: 'e.g., 5 years, 10+ years',
          icon: Icons.work,
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Please enter teaching experience'
                      : null,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: _locationController,
          label: 'Living Location',
          hint: 'e.g., City, Country',
          icon: Icons.location_on,
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Please enter living location'
                      : null,
        ),
        const SizedBox(height: 30),
        const Divider(color: Colors.deepPurple),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTeachingCourseForm(Map<String, dynamic> controllers, int index) {
    // Get class names based on selected level
    List<String> classOptions =
        controllers['courseLevel'] != null
            ? _classNamesByLevel[controllers['courseLevel']] ?? []
            : [];

    // Determine if stream selector should be shown
    bool showStreamSelector =
        controllers['courseLevel'] == 'Intermediate' ||
        controllers['courseLevel'] == 'Bachelor';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course ${index + 1}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 10),
        _buildTextField(
          controller: controllers['subjectTitle']!,
          label: 'Subject Title',
          hint: 'Enter the subject name',
          icon: Icons.subject,
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Please enter subject title'
                      : null,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: controllers['duration']!,
          label: 'Duration',
          hint: 'e.g., 3 months, 6 weeks',
          icon: Icons.timer,
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Please enter course duration'
                      : null,
        ),
        const SizedBox(height: 15),
        _buildTextField(
          controller: controllers['tutionHour']!,
          label: 'Tuition Hours',
          hint: 'e.g., 2 hours/day, 10 hours/week',
          icon: Icons.access_time,
          validator:
              (value) =>
                  value == null || value.isEmpty
                      ? 'Please enter tuition hours'
                      : null,
        ),
        const SizedBox(height: 15),
        _buildDropdownField(
          label: 'Course Level',
          icon: Icons.school,
          items: _courseLevels,
          value: controllers['courseLevel'],
          onChanged: (value) {
            setState(() {
              controllers['courseLevel'] = value;
              controllers['className'] =
                  null; // Reset class name when level changes
              controllers['stream'] = null; // Reset stream when level changes
            });
          },
          validator:
              (value) => value == null ? 'Please select course level' : null,
        ),
        const SizedBox(height: 15),
        _buildDropdownField(
          label: 'Class',
          icon: Icons.class_,
          items: classOptions,
          value: controllers['className'],
          onChanged: (value) {
            setState(() {
              controllers['className'] = value;
            });
          },
          validator: (value) => value == null ? 'Please select class' : null,
        ),
        if (showStreamSelector) ...[
          const SizedBox(height: 15),
          _buildDropdownField(
            label: 'Stream',
            icon: Icons.category,
            items: _streamOptions,
            value: controllers['stream'],
            onChanged: (value) {
              setState(() {
                controllers['stream'] = value;
              });
            },
            validator: (value) => value == null ? 'Please select stream' : null,
          ),
        ],
        const SizedBox(height: 30),
        const Divider(color: Colors.deepPurple),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.black),
        hintStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
      ),
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required List<String> items,
    required String? value,
    required void Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items:
          items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              )
              .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: validator,
      style: const TextStyle(color: Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Teacher', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple, Color(0xFF1D2671)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 10,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Teacher Registration',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Teacher's personal information section
                      _buildTeacherInfoSection(),

                      // Teaching courses section
                      const Text(
                        'Courses Teacher Can Teach',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Build forms for each course the teacher can teach
                      for (
                        int i = 0;
                        i < _teachingCoursesControllers.length;
                        i++
                      )
                        _buildTeachingCourseForm(
                          _teachingCoursesControllers[i],
                          i,
                        ),

                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _addNewTeachingCourse,
                        icon: const Icon(Icons.add, color: Colors.deepPurple),
                        label: const Text(
                          'Add Another Course',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitTeacher,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                )
                                : const Text(
                                  'Submit Teacher Profile',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
