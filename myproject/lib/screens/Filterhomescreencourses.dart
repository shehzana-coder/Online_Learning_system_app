import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import '../PROFILE/ProfileSettingsPage.dart';
import '../homesetting/video_lectures_page.dart';
import '../homesetting/notes_screen.dart';
import '/homesetting/search.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
  }

  Future<void> _fetchTeachers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final teachersCollection = FirebaseFirestore.instance.collection(
        'teachers',
      );

      // Start with all teachers
      Query query = teachersCollection;

      // We'll use this to filter teachers who teach the selected subject
      final QuerySnapshot teachersSnapshot = await query.get();
      final List<DocumentSnapshot> allTeachers = teachersSnapshot.docs;

      // Filter teachers based on the selected criteria
      final List<Map<String, dynamic>> filteredTeachers = [];

      for (DocumentSnapshot doc in allTeachers) {
        final teacherData = doc.data() as Map<String, dynamic>;

        // Skip if teacher has no courses
        if (!teacherData.containsKey('teachingCourses')) continue;

        List<dynamic> courses = teacherData['teachingCourses'];

        // Check if this teacher teaches any courses matching the selected criteria
        bool teachesMatchingCourse = courses.any((course) {
          bool levelMatch =
              widget.courseLevel == null ||
              course['courseLevel'] == widget.courseLevel;
          bool classMatch =
              widget.className == null ||
              course['className'] ==
                  widget.className
                      ?.replaceAll('Class ', '')
                      .replaceAll('Year ', '');
          bool streamMatch =
              widget.stream == null ||
              course['stream'] == widget.stream ||
              widget.courseLevel == 'Beginner' ||
              widget.courseLevel == 'Matric';

          return levelMatch && classMatch && streamMatch;
        });

        if (teachesMatchingCourse) {
          // Add teacher to filtered results
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
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A54),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : _errorMessage.isNotEmpty
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 60,
                        ),
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
                )
                : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 20,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const LoginScreen(
                                          userType: 'your_value_here',
                                        ),
                                  ),
                                );
                              },
                            ),
                            const CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        "Your guiding\nmentor",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Every great mind was once guided,\nfind your guide today.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 20),

                      // Removed filter by text section

                      // Teachers grid
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child:
                            _teachers.isEmpty
                                ? Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.search_off,
                                        color: Colors.white,
                                        size: 64,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        "No teachers found for your selected criteria.",
                                        style: TextStyle(color: Colors.white),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text("Go Back"),
                                      ),
                                    ],
                                  ),
                                )
                                : GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 15,
                                  crossAxisSpacing: 15,
                                  childAspectRatio: 0.8,
                                  children: List.generate(
                                    _teachers.length,
                                    (index) => tutorCard(_teachers[index]),
                                  ),
                                ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0F1A54),
        unselectedItemColor: const Color(0xFF0F1A54),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_fill),
            label: "Media",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: "Notes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }

  Widget tutorCard(Map<String, dynamic> teacher) {
    return InkWell(
      onTap: () {
        // TODO: Navigate to teacher detail page
        // You can implement this in the future
      },
      child: Container(
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
                    // Tuition fee information could be added here if available
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSubjects(List<dynamic> courses) {
    // Extract unique subject titles from the courses list
    final Set<String> subjects = {};
    for (var course in courses) {
      if (course['subjectTitle'] != null) {
        subjects.add(course['subjectTitle'].toString());
      }
    }
    return subjects.take(3).join(', ') + (subjects.length > 3 ? '...' : '');
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
