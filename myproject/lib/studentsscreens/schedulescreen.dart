import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'tutorhomescreen.dart';
import 'messagescreen.dart';
import 'profilesetting.dart';

class ScheduleScreen extends StatefulWidget {
  final String tutorId;

  const ScheduleScreen({Key? key, required this.tutorId}) : super(key: key);

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  Map<String, dynamic>? _tutorDetails;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _isLoading = true;
  String? _errorMessage;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchTutorDetails();
  }

  Future<void> _fetchTutorDetails() async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('teachers').doc(widget.tutorId).get();

      if (doc.exists) {
        _tutorDetails = doc.data() as Map<String, dynamic>;
        _tutorDetails!['id'] = widget.tutorId;
        _tutorDetails!['name'] =
            '${_tutorDetails!['about']?['firstName'] ?? 'Unknown'} ${_tutorDetails!['about']?['lastName'] ?? 'Tutor'}';
      } else {
        _errorMessage = 'Tutor not found';
      }
    } catch (e) {
      _errorMessage = 'Error fetching tutor details: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _scheduleSession() async {
    if (_selectedDate == null || _selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time slot')),
      );
      return;
    }

    try {
      // Create a session document
      await _firestore.collection('sessions').add({
        'tutorId': widget.tutorId,
        'tutorName': _tutorDetails!['name'],
        'studentId': 'CURRENT_USER_ID', // Replace with actual user ID from auth
        'date': _selectedDate,
        'timeSlot': _selectedTimeSlot,
        'createdAt': Timestamp.now(),
        'status': 'pending',
      });

      // Update tutor's lastBooked count
      await _firestore.collection('teachers').doc(widget.tutorId).update({
        'lastBooked': FieldValue.increment(1),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session scheduled successfully!')),
      );

      // Navigate back to TutorProfileScreen
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scheduling session: $e')),
      );
    }
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (picked != null && mounted) {
              setState(() {
                _selectedDate = picked;
                _selectedTimeSlot = null; // Reset time slot when date changes
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            _selectedDate == null
                ? 'Choose a date'
                : DateFormat('MMMM dd, yyyy').format(_selectedDate!),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotPicker() {
    if (_selectedDate == null || _tutorDetails == null) {
      return const SizedBox.shrink();
    }

    // Assuming availability is stored as a map of day to list of time slots
    // e.g., {'Monday': ['09:00', '10:00'], 'Tuesday': ['14:00', '15:00']}
    final String dayOfWeek = DateFormat('EEEE').format(_selectedDate!);
    final List<String> timeSlots =
        List<String>.from(_tutorDetails!['availability']?[dayOfWeek] ?? []);

    if (timeSlots.isEmpty) {
      return const Text(
        'No available time slots for this date',
        style: TextStyle(color: Colors.red, fontSize: 16),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Time Slot',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: timeSlots.map((slot) {
            return ChoiceChip(
              label: Text(slot),
              selected: _selectedTimeSlot == slot,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedTimeSlot = slot;
                  });
                }
              },
              selectedColor: const Color.fromARGB(255, 255, 144, 187),
              labelStyle: TextStyle(
                color:
                    _selectedTimeSlot == slot ? Colors.black : Colors.black87,
              ),
              backgroundColor: Colors.grey[200],
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          _tutorDetails != null
              ? 'Schedule with ${_tutorDetails!['name']}'
              : 'Schedule',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: const AssetImage('assets/images/3.png'),
              onBackgroundImageError: (exception, stackTrace) {
                print('Error loading profile image: $exception');
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16)))
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule a session with ${_tutorDetails!['name']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select a date and time that suits you to connect with your tutor.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildDatePicker(),
                      const SizedBox(height: 20),
                      _buildTimeSlotPicker(),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _scheduleSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 255, 144, 187),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Confirm Session',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Schedule tab is selected
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 255, 144, 187),
        unselectedItemColor: Colors.black,
        onTap: (index) {
          _navigateToScreen(context, index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mail_outline),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Setting',
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(BuildContext context, int index) {
    if (index == 2) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TutorScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MessagesScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const ProfileSettingsScreen()),
        );
        break;
    }
  }
}
