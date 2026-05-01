import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'teachers_otions_screen.dart';
import 'viewcoursesoption.dart';
import '../PROFILE/ProfileSettingsPage.dart';
import '../COURSES/teachersprofile.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllTeachers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('teachers').get();

      final List<Map<String, dynamic>> allTeachers = snapshot.docs.map((doc) {
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
    final filtered = _teachers.where((teacher) {
      final name = teacher['name'].toString().toLowerCase();
      final courses = _getSubjects(teacher['courses']).toLowerCase();
      final location = teacher['location'].toString().toLowerCase();
      return name.contains(lowerQuery) ||
          courses.contains(lowerQuery) ||
          location.contains(lowerQuery);
    }).toList();

    setState(() => _filteredTeachers = filtered);
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
                MaterialPageRoute(
                    builder: (_) => const TeacherOptionsScreen()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const OptionCoursePage()),
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchActive ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isSearchActive = !_isSearchActive;
                if (!_isSearchActive) {
                  _searchController.clear();
                  _filterTeachers('');
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.white54, size: 60),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchAllTeachers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search Bar
                    if (_isSearchActive)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterTeachers,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search by name, subject, or location',
                            hintStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: const Color(0xFF1F2A74),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.search,
                                color: Colors.white),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear,
                                  color: Colors.white),
                              onPressed: () {
                                _searchController.clear();
                                _filterTeachers('');
                              },
                            ),
                          ),
                        ),
                      ),

                    // Count
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            '${_filteredTeachers.length} teacher${_filteredTeachers.length != 1 ? 's' : ''} found',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                    // Grid of Teachers
                    Expanded(
                      child: _filteredTeachers.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off,
                                      color: Colors.white54, size: 64),
                                  SizedBox(height: 16),
                                  Text(
                                    'No teachers found.',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: GridView.count(
                                crossAxisCount: 2,
                                mainAxisSpacing: 15,
                                crossAxisSpacing: 15,
                                childAspectRatio: 0.78,
                                children: _filteredTeachers
                                    .map((t) => tutorCard(t, context))
                                    .toList(),
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
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => setState(() => _isSearchActive = true),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchAllTeachers,
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

  Widget tutorCard(Map<String, dynamic> teacher, BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherProfileDetailPage(teacher: teacher),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 209, 209, 210),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: Color(0xFF0F1A54),
              child: Icon(Icons.person, size: 30, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              teacher['name'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F1A54),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              '${teacher['qualification']} in ${teacher['courseOfDegree']}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF0F1A54)),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 5),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    bulletPoint('${teacher['experience']} exp', Icons.work),
                    bulletPoint(
                        _getSubjects(teacher['courses']), Icons.menu_book),
                    bulletPoint('${teacher['location']}', Icons.location_on),
                    bulletPoint(
                        '${teacher['teachingMode']}', Icons.computer),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1A54),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'View Profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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
        : subjects.take(2).join(', ') + (subjects.length > 2 ? '...' : '');
  }

  static Widget bulletPoint(String text, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Color(0xFF0F1A54)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, color: Color(0xFF0F1A54)),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
