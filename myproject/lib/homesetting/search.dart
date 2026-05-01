import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../COURSES/teachersprofile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allTeachers = [];
  List<Map<String, dynamic>> _filteredTeachers = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeachers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('teachers').get();

      final teachers = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
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
          _allTeachers = teachers;
          _filteredTeachers = teachers;
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
    final results = _allTeachers.where((teacher) {
      final name = teacher['name'].toString().toLowerCase();
      final subject = _getSubjects(teacher['courses']).toLowerCase();
      final location = teacher['location'].toString().toLowerCase();
      return name.contains(lowerQuery) ||
          subject.contains(lowerQuery) ||
          location.contains(lowerQuery);
    }).toList();

    setState(() => _filteredTeachers = results);
  }

  String _getSubjects(List<dynamic> courses) {
    final Set<String> subjects = {};
    for (var course in courses) {
      if (course['subjectTitle'] != null) {
        subjects.add(course['subjectTitle'].toString());
      }
    }
    return subjects.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A54),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1A54),
        elevation: 0,
        title: const Text(
          'Search Teachers',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterTeachers,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name, subject, or location...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white60),
                        onPressed: () {
                          _searchController.clear();
                          _filterTeachers('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.white54, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchTeachers,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredTeachers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off,
                                    color: Colors.white54, size: 64),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'No teachers available.'
                                      : 'No results for "${_searchController.text}"',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredTeachers.length,
                            itemBuilder: (context, index) {
                              final teacher = _filteredTeachers[index];
                              final subjects =
                                  _getSubjects(teacher['courses']);
                              return Card(
                                color: Colors.white,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFF0F1A54),
                                    child: Icon(Icons.person,
                                        color: Colors.white),
                                  ),
                                  title: Text(
                                    teacher['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F1A54),
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${teacher['qualification']} in ${teacher['courseOfDegree']}',
                                        style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12),
                                      ),
                                      if (subjects.isNotEmpty)
                                        Text(
                                          subjects,
                                          style: const TextStyle(
                                              color: Colors.deepPurple,
                                              fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 12, color: Colors.grey),
                                          const SizedBox(width: 2),
                                          Text(
                                            teacher['location'],
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 11),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.computer,
                                              size: 12, color: Colors.grey),
                                          const SizedBox(width: 2),
                                          Text(
                                            teacher['teachingMode'],
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Color(0xFF0F1A54),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TeacherProfileDetailPage(
                                                teacher: teacher),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
