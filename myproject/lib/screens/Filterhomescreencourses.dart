import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../PROFILE/ProfileSettingsPage.dart';
import '../homesetting/video_lectures_page.dart';
import '../homesetting/notes_screen.dart';
import '../homesetting/search.dart';
import '../COURSES/teachersprofile.dart';
import 'choosecoursesscreen.dart';

class LearningPartnerPage extends StatefulWidget {
  final String? courseLevel;
  final String? className;
  final String? stream;

  const LearningPartnerPage({
    Key? key,
    this.courseLevel,
    this.className,
    this.stream,
  }) : super(key: key);

  @override
  State<LearningPartnerPage> createState() => _LearningPartnerPageState();
}

class _LearningPartnerPageState extends State<LearningPartnerPage> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _teachers = [];
  String _errorMessage = '';
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    // No Firebase Auth — username not available without login
    if (mounted) {
      setState(() {
        _userName = 'Student';
      });
    }
  }

  Future<void> _fetchTeachers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final QuerySnapshot teachersSnapshot =
          await FirebaseFirestore.instance.collection('teachers').get();

      final List<Map<String, dynamic>> filteredTeachers = [];

      for (DocumentSnapshot doc in teachersSnapshot.docs) {
        final teacherData = doc.data() as Map<String, dynamic>;

        if (!teacherData.containsKey('teachingCourses')) continue;

        List<dynamic> courses = teacherData['teachingCourses'];

        bool teachesMatchingCourse = courses.any((course) {
          bool levelMatch = widget.courseLevel == null ||
              course['courseLevel'] == widget.courseLevel;
          bool classMatch = widget.className == null ||
              course['className'] ==
                  widget.className
                      ?.replaceAll('Class ', '')
                      .replaceAll('Year ', '');
          bool streamMatch = widget.stream == null ||
              course['stream'] == widget.stream ||
              widget.courseLevel == 'Beginner' ||
              widget.courseLevel == 'Matric';

          return levelMatch && classMatch && streamMatch;
        });

        if (teachesMatchingCourse) {
          filteredTeachers.add({
            'id': doc.id,
            'name': teacherData['name'] ?? 'Unknown Teacher',
            'qualification': teacherData['qualification'] ?? 'N/A',
            'courseOfDegree': teacherData['courseOfDegree'] ?? 'N/A',
            'experience': teacherData['experience'] ?? 'N/A',
            'teachingMode': teacherData['teachingMode'] ?? 'N/A',
            'location': teacherData['location'] ?? 'N/A',
            'courses': courses,
          });
        }
      }

      if (mounted) {
        setState(() {
          _teachers = filteredTeachers;
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

  void _onTabTapped(int index) {
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileSettingsPage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VideoLecturesPage()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SearchPage()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NotesScreen()),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A54),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _errorMessage.isNotEmpty
                ? _buildErrorView()
                : _buildContent(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0F1A54),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_fill), label: 'Videos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.description), label: 'Notes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 60),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchTeachers,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _fetchTeachers,
      color: Colors.white,
      backgroundColor: const Color(0xFF0F1A54),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${_userName.isNotEmpty ? _userName : 'Student'} 👋',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const Text(
                        'Find Your Mentor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileSettingsPage(),
                        ),
                      );
                    },
                    child: const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your guiding\nmentor',
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Every great mind was once guided,\nfind your guide today.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CoursesScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF6A11CB),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Browse Courses',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Image.asset(
                      'assets/images/8.png',
                      width: 80,
                      height: 80,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Filter info
            if (widget.courseLevel != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (widget.courseLevel != null)
                      _filterChip(widget.courseLevel!),
                    if (widget.className != null)
                      _filterChip(widget.className!),
                    if (widget.stream != null) _filterChip(widget.stream!),
                  ],
                ),
              ),

            // Teachers section
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.courseLevel != null
                        ? 'Matching Teachers'
                        : 'Available Teachers',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_teachers.length} found',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),

            _teachers.isEmpty
                ? _buildEmptyState()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                      childAspectRatio: 0.78,
                      children: _teachers
                          .map((teacher) => tutorCard(teacher))
                          .toList(),
                    ),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.white.withOpacity(0.2),
      side: const BorderSide(color: Colors.white38),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const Icon(Icons.search_off, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          const Text(
            'No teachers found for your selected criteria.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget tutorCard(Map<String, dynamic> teacher) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherProfileDetailPage(teacher: teacher),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFD1D1D2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFF0F1A54),
              child: Icon(Icons.person, size: 32, color: Colors.white),
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
            const SizedBox(height: 6),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _bulletPoint('${teacher['experience']} exp', Icons.work),
                    _bulletPoint(
                        _getSubjects(teacher['courses']), Icons.menu_book),
                    _bulletPoint('${teacher['location']}', Icons.location_on),
                    _bulletPoint(
                        '${teacher['teachingMode']}', Icons.computer),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1A54),
                borderRadius: BorderRadius.circular(8),
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

  static Widget _bulletPoint(String text, IconData icon) {
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
