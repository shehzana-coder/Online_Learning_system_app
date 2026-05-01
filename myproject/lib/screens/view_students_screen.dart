import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewStudentsScreen extends StatefulWidget {
  const ViewStudentsScreen({Key? key}) : super(key: key);

  @override
  State<ViewStudentsScreen> createState() => _ViewStudentsScreenState();
}

class _ViewStudentsScreenState extends State<ViewStudentsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchEnrolledStudents();
  }

  Future<void> _fetchEnrolledStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch all enrollments from Firestore (no auth required)
      final enrollmentsSnapshot = await FirebaseFirestore.instance
          .collection('enrollments')
          .get();

      final List<Map<String, dynamic>> students = [];

      for (var enrollment in enrollmentsSnapshot.docs) {
        final data = enrollment.data();
        students.add({
          'id': enrollment.id,
          'name': data['studentName'] ?? 'Student',
          'email': data['studentEmail'] ?? 'N/A',
          'username': data['studentUsername'] ?? 'N/A',
          'enrolledAt': data['enrolledAt'],
          'teacherName': data['teacherName'] ?? 'N/A',
        });
      }

      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load students: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A54),
      appBar: AppBar(
        title: const Text('Enrolled Students',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F1A54),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchEnrolledStudents,
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
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchEnrolledStudents,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _students.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              color: Colors.white54, size: 80),
                          SizedBox(height: 16),
                          Text(
                            'No students enrolled yet.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Students will appear here once they enroll.',
                            style: TextStyle(color: Colors.white54),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Count banner
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.people,
                                  color: Colors.white, size: 36),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_students.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Total Enrolled Students',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Student list
                        Expanded(
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _students.length,
                            itemBuilder: (context, index) {
                              final student = _students[index];
                              final name = student['name'] as String;
                              return Card(
                                color: Colors.white,
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        const Color(0xFF0F1A54),
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : 'S',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    name,
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
                                        student['email'],
                                        style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12),
                                      ),
                                      if (student['teacherName'] != 'N/A')
                                        Text(
                                          'Teacher: ${student['teacherName']}',
                                          style: const TextStyle(
                                              color: Colors.deepPurple,
                                              fontSize: 12),
                                        ),
                                    ],
                                  ),
                                  trailing: const Icon(
                                    Icons.person,
                                    color: Color(0xFF0F1A54),
                                  ),
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
