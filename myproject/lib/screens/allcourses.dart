// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'teachers_otions_screen.dart';
import 'viewcoursesoption.dart'; // Replace with your actual student screen import
import '../PROFILE/ProfileSettingsPage.dart'; // Import the ProfileSettingPage

class FullCoursePage extends StatefulWidget {
  final bool isTeacher;

  const FullCoursePage({Key? key, this.isTeacher = false}) : super(key: key);

  @override
  State<FullCoursePage> createState() => _FullCoursePageState();
}

class _FullCoursePageState extends State<FullCoursePage> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _filteredTeachers = [];
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAllTeachers();
  }

  Future<void> _fetchAllTeachers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('teachers').get();

      final List<Map<String, dynamic>> allTeachers =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Unknown Teacher',
              'qualification': data['qualification'] ?? 'N/A',
              'courseOfDegree': data['courseOfDegree'] ?? 'N/A',
              'experience': data['experience'] ?? 'N/A',
              'teachingMode': data['teachingMode'] ?? 'N/A',
              'location': data['location'] ?? 'N/A',
              'courses': data['teachingCourses'] ?? [],
            };
          }).toList();

      if (mounted) {
        setState(() {
          _teachers = allTeachers;
          _filteredTeachers = allTeachers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load teachers: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _filterTeachers(String query) {
    final lowerQuery = query.toLowerCase();
    final filtered =
        _teachers.where((teacher) {
          final name = teacher['name'].toString().toLowerCase();
          final courses = _getSubjects(teacher['courses']).toLowerCase();
          return name.contains(lowerQuery) || courses.contains(lowerQuery);
        }).toList();

    setState(() {
      _filteredTeachers = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A54),
      appBar: AppBar(
        title: const Text('All Courses'),
        backgroundColor: const Color(0xFF0F1A54),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.isTeacher) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const TeacherOptionsScreen()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const OptionCoursePage()),
              );
            }
          },
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : _errorMessage.isNotEmpty
              ? Center(
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.white),
                ),
              )
              : Column(
                children: [
                  // Search Bar
                  if (_isSearchActive)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _filterTeachers,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search by name or subject',
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: const Color(0xFF1F2A74),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white),
                            onPressed: () {
                              _searchController.clear();
                              _filterTeachers('');
                              setState(() {
                                _isSearchActive = false;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  // Grid of Teachers
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 15,
                        childAspectRatio: 0.8,
                        children: List.generate(
                          _filteredTeachers.length,
                          (index) => tutorCard(_filteredTeachers[index]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF0F1A54),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearchActive = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileSettingsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget tutorCard(Map<String, dynamic> teacher) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 209, 209, 210),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFF0F1A54),
            child: Icon(Icons.person, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            teacher['name'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F1A54),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            "${teacher['qualification']} in ${teacher['courseOfDegree']}",
            style: const TextStyle(fontSize: 12, color: Color(0xFF0F1A54)),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 5),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  bulletPoint("${teacher['experience']} exp", Icons.work),
                  bulletPoint(
                    _getSubjects(teacher['courses']),
                    Icons.menu_book,
                  ),
                  bulletPoint("${teacher['location']}", Icons.home),
                  bulletPoint("${teacher['teachingMode']}", Icons.wifi),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSubjects(List<dynamic> courses) {
    final Set<String> subjects = {};
    for (var course in courses) {
      if (course['subjectTitle'] != null) {
        subjects.add(course['subjectTitle'].toString());
      }
    }
    return subjects.isEmpty
        ? 'N/A'
        : subjects.take(3).join(', ') + (subjects.length > 3 ? '...' : '');
  }

  static Widget bulletPoint(String text, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Color(0xFF0F1A54)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF0F1A54)),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
