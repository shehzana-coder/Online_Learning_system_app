import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bookingsessionscreen.dart'; // Import BookingSessionScreen

class SessionSchedulingScreen extends StatefulWidget {
  final String tutorId;
  final Map<String, dynamic>? availability;

  const SessionSchedulingScreen({
    Key? key,
    required this.tutorId,
    this.availability,
  }) : super(key: key);

  @override
  State<SessionSchedulingScreen> createState() =>
      _SessionSchedulingScreenState();
}

class _SessionSchedulingScreenState extends State<SessionSchedulingScreen> {
  int _selectedDuration = 30;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 2));
  String? _selectedTime;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _tutorAvailability;
  Map<String, dynamic>? _tutorDetails;
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, List<String>> _timeSlots = {
    'Morning': [],
    'Afternoon': [],
    'Evening': [],
  };

  final DateTime _startDate = DateTime.now();
  final DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _fetchAvailabilityAndDetails();
  }

  Future<void> _fetchAvailabilityAndDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      DocumentSnapshot verifiedDoc =
          await _firestore.collection('teachers').doc(widget.tutorId).get();

      if (verifiedDoc.exists) {
        _tutorDetails = verifiedDoc.data() as Map<String, dynamic>;
        _tutorAvailability =
            _convertAvailabilityFormat(_tutorDetails?['availability'] ??
                {
                  'timezone': 'Not specified',
                  'days': {},
                });
      } else {
        _errorMessage = 'Teacher not found';
      }

      if (_tutorAvailability != null) {
        _generateTimeSlots();
      }
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _convertAvailabilityFormat(
      Map<String, dynamic>? availability) {
    if (availability == null) {
      return {
        'timezone': 'Not specified',
        'days': [],
      };
    }
    final daysMap = availability['days'] as Map<String, dynamic>? ?? {};
    final daysList = daysMap.entries.map((entry) {
      return {
        'days': entry.key,
        'enabled': entry.value['enabled'] ?? false,
        'slots': (entry.value['slots'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [],
      };
    }).toList();

    return {
      'timezone': availability['timezone'] ?? 'Not specified',
      'days': daysList,
    };
  }

  void _generateTimeSlots() {
    _timeSlots = {'Morning': [], 'Afternoon': [], 'Evening': []};
    if (_tutorAvailability == null || _tutorAvailability!['days'] == null)
      return;

    String selectedDay = DateFormat('EEEE').format(_selectedDate);

    var dayAvailability =
        (_tutorAvailability!['days'] as List<dynamic>).firstWhere(
      (day) => day['days'] == selectedDay && day['enabled'] == true,
      orElse: () => {'days': selectedDay, 'enabled': false, 'slots': []},
    );

    if (dayAvailability == null || !dayAvailability['enabled']) return;

    for (var slot in dayAvailability['slots']) {
      try {
        DateTime startTime = _parseTime(slot['from']);
        DateTime endTime = _parseTime(slot['to']);

        while (startTime.isBefore(endTime)) {
          String formattedTime = DateFormat('h:mm a').format(startTime);
          int hour = startTime.hour;

          if (hour < 12) {
            _timeSlots['Morning']!.add(formattedTime);
          } else if (hour < 17) {
            _timeSlots['Afternoon']!.add(formattedTime);
          } else {
            _timeSlots['Evening']!.add(formattedTime);
          }

          startTime = startTime.add(Duration(minutes: _selectedDuration));
          if (_selectedDuration == 60 &&
              startTime.add(const Duration(minutes: 60)).isAfter(endTime)) {
            break;
          }
        }
      } catch (e) {
        print('Error parsing time slot: $e');
      }
    }

    for (var period in _timeSlots.keys) {
      _timeSlots[period]!.sort((a, b) {
        DateTime timeA = DateFormat('h:mm a').parse(a);
        DateTime timeB = DateFormat('h:mm a').parse(b);
        return timeA.compareTo(timeB);
      });
    }
  }

  DateTime _parseTime(String time) {
    List<String> parts = time.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  List<DateTime> _getDaysInRange() {
    List<DateTime> days = [];
    DateTime current = _startDate;
    while (current.isBefore(_endDate.add(const Duration(days: 1)))) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  bool _isDateSelected(DateTime date) {
    return date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchAvailabilityAndDetails,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 255, 144, 187),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Retry',
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              '$_selectedDuration min session',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: Text(
                              'To discuss your learning plan',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedDuration = 30;
                                      _selectedTime = null;
                                      _generateTimeSlots();
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _selectedDuration == 30
                                        ? const Color.fromARGB(
                                            255, 255, 144, 187)
                                        : Colors.grey[200],
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18),
                                  ),
                                  child: Text(
                                    '30 min',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedDuration = 60;
                                      _selectedTime = null;
                                      _generateTimeSlots();
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _selectedDuration == 60
                                        ? const Color.fromARGB(
                                            255, 255, 144, 187)
                                        : Colors.grey[200],
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18),
                                  ),
                                  child: Text(
                                    '60 min',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMMM yyyy').format(_selectedDate),
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: _startDate,
                                    lastDate: _endDate,
                                    builder: (context, child) {
                                      return Theme(
                                        data: ThemeData.light().copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: Color.fromARGB(
                                                255, 255, 144, 187),
                                            onPrimary: Colors.black,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null && mounted) {
                                    setState(() {
                                      _selectedDate = picked;
                                      _selectedTime = null;
                                      _generateTimeSlots();
                                    });
                                  }
                                },
                                child: Text(
                                  _isToday(_selectedDate)
                                      ? 'Today'
                                      : 'Select Date',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: const Color.fromARGB(
                                        255, 255, 144, 187),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                'Fri',
                                'Sat',
                                'Sun',
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat'
                              ]
                                  .map((day) => Text(
                                        day,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: _getDaysInRange().take(9).map((date) {
                                final isSelected = _isDateSelected(date);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedDate = date;
                                      _selectedTime = null;
                                      _generateTimeSlots();
                                    });
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? const Color.fromARGB(
                                              255, 255, 144, 187)
                                          : Colors.transparent,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${date.day}',
                                        style: GoogleFonts.poppins(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Select the time zone according to your country',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _timeSlots['Morning']!.isNotEmpty
                              ? _buildTimePeriodSection(
                                  'Morning', Icons.wb_sunny_outlined)
                              : const SizedBox.shrink(),
                          if (_timeSlots['Morning']!.isNotEmpty)
                            const SizedBox(height: 24),
                          _timeSlots['Afternoon']!.isNotEmpty
                              ? _buildTimePeriodSection(
                                  'Afternoon', Icons.wb_sunny)
                              : const SizedBox.shrink(),
                          if (_timeSlots['Afternoon']!.isNotEmpty)
                            const SizedBox(height: 24),
                          _timeSlots['Evening']!.isNotEmpty
                              ? _buildTimePeriodSection(
                                  'Evening', Icons.nights_stay_outlined)
                              : const SizedBox.shrink(),
                          if (_timeSlots['Evening']!.isNotEmpty)
                            const SizedBox(height: 32),
                          if (_timeSlots.values.every((slots) => slots.isEmpty))
                            Center(
                              child: Text(
                                'No available slots for this date',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.4,
                                  child: ElevatedButton(
                                    onPressed: _selectedTime != null
                                        ? () {
                                            print(
                                                'Navigating to BookingSessionScreen'); // Debug
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    BookingSessionScreen(
                                                  tutorId: widget.tutorId,
                                                  date: _selectedDate,
                                                  time: _selectedTime!,
                                                  duration: _selectedDuration,
                                                  tutorDetails: _tutorDetails,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                          255, 255, 144, 187),
                                      foregroundColor: Colors.black,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(
                                            color: Colors.black),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 6),
                                      disabledBackgroundColor: Colors.grey[300],
                                    ),
                                    child: Text(
                                      'Schedule session',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.4,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side:
                                          const BorderSide(color: Colors.black),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 6),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildTimePeriodSection(String period, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Text(
              period,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _timeSlots[period]!.map((time) {
            final isSelected = _selectedTime == time;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTime = time;
                });
              },
              child: Container(
                width: (MediaQuery.of(context).size.width - 56) / 2,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? const Color.fromARGB(255, 255, 144, 187)
                        : Colors.grey[300]!,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? const Color.fromARGB(255, 255, 144, 187)
                          .withOpacity(0.1)
                      : Colors.white,
                ),
                child: Text(
                  time,
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
