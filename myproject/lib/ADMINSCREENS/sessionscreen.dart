import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  _SessionsScreenState createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _sessions = [];
  String _searchQuery = '';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    try {
      setState(() {
        _isLoading = true;
      });

      Query<Map<String, dynamic>> query = _firestore.collection('sessions');
      if (_selectedStatus != 'All') {
        query = query.where('status', isEqualTo: _selectedStatus.toLowerCase());
      }

      final snapshot = await query.get();
      setState(() {
        _sessions = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'tutorName':
                data['tutorName'] ?? 'Unknown Teacher', // Added for consistency
            'teacherId': data['tutorId'] ?? 'N/A',
            'studentName': data['studentName'] ?? 'Unknown Student',
            'studentId': data['studentId'] ?? 'N/A',
            'course': data['languageCourse'] ?? 'No Course Assigned',
            'languageCourse': data['languageCourse'] ??
                'No Course Assigned', // Added for consistency
            'Booked Course': data['Booked Course'] ??
                data['languageCourse'] ??
                'No Course Booked',
            'dateTime': data['dateTime'] ?? Timestamp.now(),
            'duration': data['duration'] ?? 60, // Default 60 minutes
            'status': data['status'] ?? 'pending',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching sessions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error loading sessions: $e', style: GoogleFonts.poppins()),
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredSessions {
    if (_searchQuery.isEmpty) return _sessions;
    return _sessions.where((session) {
      final teacherName =
          (session['tutorName'] ?? 'Unknown Teacher').toString().toLowerCase();
      final studentName = (session['studentName'] ?? 'Unknown Student')
          .toString()
          .toLowerCase();
      final course =
          (session['languageCourse'] ?? 'No Course').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return teacherName.contains(query) ||
          studentName.contains(query) ||
          course.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Text('Sessions',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Color.fromARGB(255, 255, 144, 187),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSessions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 255, 144, 187)))
          : Column(
              children: [
                _buildSearchAndFilter(),
                Expanded(
                  child: _filteredSessions.isEmpty
                      ? Center(
                          child: Text(
                            'No sessions found',
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredSessions.length,
                          itemBuilder: (context, index) {
                            final session = _filteredSessions[index];
                            return _buildSessionCard(session);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search by teacher, student, or course',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
              prefixIcon: const Icon(Icons.search,
                  color: Color.fromARGB(255, 255, 144, 187)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Color.fromARGB(255, 255, 144, 187)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Color.fromARGB(255, 255, 144, 187), width: 2),
              ),
              filled: true,
              fillColor: Color.fromARGB(255, 255, 255, 255),
            ),
            style: GoogleFonts.poppins(),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            items: ['All', 'Active', 'Scheduled', 'Completed', 'Pending']
                .map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(
                        status,
                        style: GoogleFonts.poppins(color: Colors.black),
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedStatus = value ?? 'All'; // Handle null value
                _fetchSessions();
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Color.fromARGB(255, 255, 144, 187)),
              ),
              filled: true,
              fillColor: const Color.fromARGB(255, 255, 255, 255),
            ),
            style: GoogleFonts.poppins(),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final dateTime = (session['dateTime'] as Timestamp?)?.toDate();
    final formattedDate = dateTime != null
        ? DateFormat('dd/MM/yyyy').format(dateTime)
        : 'Date not set';
    final formattedTime = dateTime != null
        ? DateFormat('HH:mm').format(dateTime)
        : 'Time not set';
    final status = (session['status'] ?? 'pending').toString().capitalize();
    final bookedCourse = session['Booked Course'] ??
        session['languageCourse'] ??
        'No Course Information';
    final tutorName = session['tutorName'] ?? 'Teacher not assigned';
    final studentName = session['studentName'] ?? 'Student not assigned';
    final duration = session['duration'] ?? 60;

    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    bookedCourse,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Teacher: $tutorName',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Student: $studentName',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Date: $formattedDate',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Time: $formattedTime',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Duration: $duration minutes',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.blue;
      case 'scheduled':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
