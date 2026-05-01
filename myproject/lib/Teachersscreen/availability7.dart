import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'videoportion6.dart';
import 'lessonpricing8.dart'; // Adjust import path as needed

class AvailabilityScreen extends StatefulWidget {
  final String id;
  const AvailabilityScreen({super.key, required this.id});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  String? selectedTimezone;
  final Map<String, List<TimeSlot>> availability = {
    'Monday': [TimeSlot()],
    'Tuesday': [TimeSlot()],
    'Wednesday': [TimeSlot()],
    'Thursday': [TimeSlot()],
    'Friday': [TimeSlot()],
    'Saturday': [TimeSlot()],
    'Sunday': [TimeSlot()],
  };
  final Map<String, bool> daySelected = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };
  bool _isLoading = true;
  bool _isSavingBack = false; // Separate saving state for "Back" button
  bool _isSavingContinue =
      false; // Separate saving state for "Save and continue" button
  final List<Map<String, String>> countryTimezones = [
    {
      'country': 'United States (EST)',
      'timezone': 'UTC-05:00',
      'code': 'US_EST'
    },
    {
      'country': 'United States (PST)',
      'timezone': 'UTC-08:00',
      'code': 'US_PST'
    },
    {
      'country': 'United States (CST)',
      'timezone': 'UTC-06:00',
      'code': 'US_CST'
    },
    {
      'country': 'United States (MST)',
      'timezone': 'UTC-07:00',
      'code': 'US_MST'
    },
    {'country': 'United Kingdom', 'timezone': 'UTC+00:00', 'code': 'UK'},
    {'country': 'Germany', 'timezone': 'UTC+01:00', 'code': 'DE'},
    {'country': 'France', 'timezone': 'UTC+01:00', 'code': 'FR'},
    {'country': 'Spain', 'timezone': 'UTC+01:00', 'code': 'ES'},
    {'country': 'Italy', 'timezone': 'UTC+01:00', 'code': 'IT'},
    {'country': 'Russia (Moscow)', 'timezone': 'UTC+03:00', 'code': 'RU_MSK'},
    {'country': 'Turkey', 'timezone': 'UTC+03:00', 'code': 'TR'},
    {'country': 'Greece', 'timezone': 'UTC+02:00', 'code': "GR"},
    {'country': 'Egypt', 'timezone': 'UTC+02:00', 'code': 'EG'},
    {'country': 'South Africa', 'timezone': 'UTC+02:00', 'code': 'ZA'},
    {'country': 'UAE', 'timezone': 'UTC+04:00', 'code': 'AE'},
    {'country': 'Saudi Arabia', 'timezone': 'UTC+03:00', 'code': 'SA'},
    {'country': 'Pakistan', 'timezone': 'UTC+05:00', 'code': 'PK'},
    {'country': 'India', 'timezone': 'UTC+05:30', 'code': 'IN'},
    {'country': 'Bangladesh', 'timezone': 'UTC+06:00', 'code': 'BD'},
    {'country': 'Thailand', 'timezone': 'UTC+07:00', 'code': 'TH'},
    {'country': 'Indonesia', 'timezone': 'UTC+07:00', 'code': 'ID'},
    {'country': 'Singapore', 'timezone': 'UTC+08:00', 'code': 'SG'},
    {'country': 'China', 'timezone': 'UTC+08:00', 'code': 'CN'},
    {'country': 'Philippines', 'timezone': 'UTC+08:00', 'code': 'PH'},
    {'country': 'Japan', 'timezone': 'UTC+09:00', 'code': 'JP'},
    {'country': 'South Korea', 'timezone': 'UTC+09:00', 'code': 'KR'},
    {
      'country': 'Australia (Sydney)',
      'timezone': 'UTC+10:00',
      'code': 'AU_SYD'
    },
    {'country': 'Australia (Perth)', 'timezone': 'UTC+08:00', 'code': 'AU_PER'},
    {'country': 'New Zealand', 'timezone': 'UTC+12:00', 'code': 'NZ'},
    {'country': 'Brazil', 'timezone': 'UTC-03:00', 'code': 'BR'},
    {'country': 'Argentina', 'timezone': 'UTC-03:00', 'code': 'AR'},
    {'country': 'Mexico', 'timezone': 'UTC-06:00', 'code': 'MX'},
    {'country': 'Canada (EST)', 'timezone': 'UTC-05:00', 'code': 'CA_EST'},
    {'country': 'Canada (PST)', 'timezone': 'UTC-08:00', 'code': 'CA_PST'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final availabilityJson = prefs.getString('availability');
      if (availabilityJson != null) {
        final data = jsonDecode(availabilityJson);
        if (mounted) {
          setState(() {
            selectedTimezone = data['timezone'];
            for (String day in availability.keys) {
              if (data['days'].containsKey(day)) {
                daySelected[day] = data['days'][day]['enabled'] ?? false;
                availability[day] =
                    (data['days'][day]['slots'] as List<dynamic>? ?? [])
                        .map((slot) => TimeSlot(
                              from: slot['from'] as String?,
                              to: slot['to'] as String?,
                            ))
                        .toList();
                if (availability[day]!.isEmpty)
                  availability[day] = [TimeSlot()];
              }
            }
          });
        }
      }
    } catch (e) {
      print('Error loading availability: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading availability: $e',
                  style: GoogleFonts.poppins(color: Colors.white)),
              backgroundColor: const Color.fromARGB(255, 0, 0, 0)),
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

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final availabilityData = {
        'timezone': selectedTimezone,
        'days': {
          for (String day in availability.keys)
            day: {
              'enabled': daySelected[day] ?? false,
              'slots': availability[day]!
                  .where((slot) =>
                      slot.from != null &&
                      slot.from!.isNotEmpty &&
                      slot.to != null &&
                      slot.to!.isNotEmpty)
                  .map((slot) => {'from': slot.from, 'to': slot.to})
                  .toList(),
            },
        },
      };

      await prefs.setString('availability', jsonEncode(availabilityData));
    } catch (e) {
      print('Error saving availability: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving availability: $e',
                  style: GoogleFonts.poppins(color: Colors.white)),
              backgroundColor: const Color.fromARGB(255, 0, 0, 0)),
        );
      }
    }
  }

  bool _validateAvailabilityData() {
    if (selectedTimezone == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Please select a timezone',
                  style: GoogleFonts.poppins(color: Colors.white)),
              backgroundColor: const Color.fromARGB(255, 0, 0, 0)),
        );
      }
      return false;
    }

    bool hasValidDay = false;
    for (String day in daySelected.keys) {
      if (daySelected[day]!) {
        // Validate time slots for the day
        List<TimeSlot> validSlots = availability[day]!
            .where((slot) =>
                slot.from != null &&
                slot.from!.isNotEmpty &&
                slot.to != null &&
                slot.to!.isNotEmpty)
            .toList();

        // Check if there is at least one valid time slot
        if (validSlots.isNotEmpty) {
          hasValidDay = true;

          // Validate "From" is less than "To"
          for (TimeSlot slot in validSlots) {
            int fromMinutes = slot.toMinutes(slot.from!);
            int toMinutes = slot.toMinutes(slot.to!);
            if (fromMinutes >= toMinutes) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'On $day, "From" time must be earlier than "To" time in slot ${validSlots.indexOf(slot) + 1}',
                        style: GoogleFonts.poppins(color: Colors.white)),
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  ),
                );
              }
              return false;
            }
          }

          // Check for overlapping time slots
          for (int i = 0; i < validSlots.length; i++) {
            for (int j = i + 1; j < validSlots.length; j++) {
              if (validSlots[i].overlapsWith(validSlots[j])) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'On $day, time slots ${i + 1} and ${j + 1} overlap',
                          style: GoogleFonts.poppins(color: Colors.white)),
                      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  );
                }
                return false;
              }
            }
          }
        }
      }
    }

    if (!hasValidDay) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Please select at least one day with valid time slots',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: CircularProgressIndicator(
                color: Color.fromARGB(255, 255, 144, 187))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    top: 29.0, left: 16.0, right: 16.0, bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Availability",
                        style: GoogleFonts.poppins(
                            fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(
                  color: Color.fromARGB(255, 255, 144, 187),
                  thickness: 1.0,
                  height: 1.0),
              _buildInfoSection(),
              _buildTimezoneSection(),
              _buildAvailabilitySection(),
              const SizedBox(height: 32),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tell students about your availability to proceed with their sessions.",
            style: GoogleFonts.poppins(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTimezoneSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Set your timezone",
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            "Setting the correct time zone is crucial for accurately scheduling and coordinating lessons with students worldwide.",
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Text("Choose your country/timezone",
              style: GoogleFonts.poppins(fontSize: 16)),
          const SizedBox(height: 8),
          _buildTimezoneDropdown(),
        ],
      ),
    );
  }

  Widget _buildTimezoneDropdown() {
    return Container(
      width:
          MediaQuery.of(context).size.width - 32, // Screen width minus padding
      height: 50, // Fixed height for dropdown
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 255, 235, 238), // Lighter pink
            Color.fromARGB(255, 255, 205, 210), // Slightly darker pink
          ],
        ),
        border: Border.all(color: const Color.fromARGB(255, 255, 144, 187)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Select your country/timezone",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),
          ),
          value: selectedTimezone,
          icon: const Icon(Icons.keyboard_arrow_down),
          iconSize: 24,
          elevation: 16,
          style: GoogleFonts.poppins(color: Colors.black, fontSize: 14),
          dropdownColor: Colors.white,
          onChanged: (String? newValue) {
            setState(() {
              selectedTimezone = newValue;
            });
          },
          items: countryTimezones
              .map<DropdownMenuItem<String>>((Map<String, String> country) {
            return DropdownMenuItem<String>(
              value: country['code'],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '${country['country']} (${country['timezone']})',
                  style: GoogleFonts.poppins(),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Set your availability",
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
              "Availability shows your potential working hours. Students can book lessons at these times.",
              style: GoogleFonts.poppins(fontSize: 16)),
          const SizedBox(height: 16),
          _buildDayTimeSlots('Monday'),
          _buildDayTimeSlots('Tuesday'),
          _buildDayTimeSlots('Wednesday'),
          _buildDayTimeSlots('Thursday'),
          _buildDayTimeSlots('Friday'),
          _buildDayTimeSlots('Saturday'),
          _buildDayTimeSlots('Sunday'),
        ],
      ),
    );
  }

  Widget _buildDayTimeSlots(String day) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform.scale(
              scale: 0.9,
              child: Checkbox(
                visualDensity:
                    const VisualDensity(horizontal: -4, vertical: -4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                value: daySelected[day],
                activeColor: const Color.fromARGB(255, 255, 144, 187),
                checkColor: Colors.black,
                onChanged: (value) {
                  setState(() {
                    daySelected[day] = value!;
                    if (!value) {
                      availability[day]!.clear();
                      availability[day]!.add(TimeSlot());
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 6),
            Text(day,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        if (daySelected[day]!) ...[
          for (int i = 0; i < availability[day]!.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTimeSlotRow(day, i)),
                if (i >
                    0) // Show remove button only for slots after the first one
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0, right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          availability[day]!.removeAt(i);
                        });
                      },
                      child: const Icon(
                        Icons.remove_circle_outline,
                        color: Color.fromARGB(255, 0, 0, 0),
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
        ] else ...[
          _buildTimeSlotRow(day, 0, enabled: false),
        ],
        if (daySelected[day]!)
          Padding(
            padding: const EdgeInsets.only(left: 5.0, top: 8.0, bottom: 16.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  availability[day]!.add(TimeSlot());
                });
              },
              child: Row(
                children: [
                  const Icon(Icons.add, size: 18),
                  const SizedBox(width: 4),
                  Text("Add another timeslot",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTimeSlotRow(String day, int index, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(left: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child:
                      Text("From", style: GoogleFonts.poppins(fontSize: 16))),
              Expanded(
                  child: Text("To", style: GoogleFonts.poppins(fontSize: 16))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildScrollableTimePicker(
                  value: availability[day]![index].from,
                  enabled: enabled && daySelected[day]!,
                  onChanged: (time) {
                    setState(() {
                      availability[day]![index].from = time;
                    });
                  },
                  day: day,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildScrollableTimePicker(
                  value: availability[day]![index].to,
                  enabled: enabled && daySelected[day]!,
                  onChanged: (time) {
                    setState(() {
                      availability[day]![index].to = time;
                    });
                  },
                  day: day,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildScrollableTimePicker({
    String? value,
    bool enabled = true,
    required Function(String?) onChanged,
    required String day,
  }) {
    // Define gradient colors for each day
    final Map<String, LinearGradient> dayGradients = {
      'Monday': LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.blue[100]!, Colors.blue[200]!],
      ),
      'Tuesday': LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.green[100]!, Colors.green[200]!],
      ),
      'Wednesday': LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFBCCCDC),
          Color(0xFFBCCCDC),
        ],
      ),
      'Thursday': LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFD1F8EF),
          const Color(0xFFD1F8EF),
        ],
      ),
      'Friday': LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.purple[100]!, Colors.purple[200]!],
      ),
      'Saturday': LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.cyan[100]!, Colors.cyan[200]!],
      ),
      'Sunday': LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color.fromARGB(255, 218, 208, 211),
          const Color.fromARGB(255, 218, 208, 211)
        ],
      ),
    };

    return GestureDetector(
      onTap: enabled
          ? () => _showScrollableTimePicker(context, value, onChanged)
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: dayGradients[day] ??
              const LinearGradient(colors: [Colors.white, Colors.white]),
          border: Border.all(
              color: enabled
                  ? const Color.fromARGB(255, 255, 144, 187)
                  : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value != null && value.isNotEmpty ? value : "Select Time",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: enabled ? Colors.black : Colors.grey.shade600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.access_time,
              color: enabled ? Colors.black : Colors.grey.shade600,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showScrollableTimePicker(
      BuildContext context, String? currentValue, Function(String?) onChanged) {
    int selectedHour = 9;
    int selectedMinute = 0;
    String selectedPeriod = 'AM';

    if (currentValue != null && currentValue.isNotEmpty) {
      try {
        final parts = currentValue.split(':');
        if (parts.length == 2) {
          int hour24 = int.parse(parts[0]);
          int minute = int.parse(parts[1]);
          if (hour24 >= 0 && hour24 <= 23 && minute >= 0 && minute < 60) {
            if (hour24 == 0) {
              selectedHour = 12;
              selectedPeriod = 'AM';
            } else if (hour24 < 12) {
              selectedHour = hour24;
              selectedPeriod = 'AM';
            } else if (hour24 == 12) {
              selectedHour = 12;
              selectedPeriod = 'PM';
            } else {
              selectedHour = hour24 - 12;
              selectedPeriod = 'PM';
            }
            selectedMinute = minute;
          }
        }
      } catch (e) {
        // Use default values if parsing fails
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 225, 245, 254), // Light blue
                  Color.fromARGB(255, 179, 229, 252), // Slightly darker blue
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select Time',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        width: 300,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'Hour',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Expanded(
                                    child: ListWheelScrollView.useDelegate(
                                      itemExtent: 40,
                                      perspective: 0.005,
                                      diameterRatio: 1.2,
                                      physics: const FixedExtentScrollPhysics(),
                                      controller: FixedExtentScrollController(
                                          initialItem: selectedHour - 1),
                                      onSelectedItemChanged: (int index) {
                                        setDialogState(() {
                                          selectedHour = index + 1;
                                        });
                                      },
                                      childDelegate:
                                          ListWheelChildBuilderDelegate(
                                        childCount: 12,
                                        builder: (context, index) {
                                          final hour = index + 1;
                                          final isSelected =
                                              hour == selectedHour;
                                          return Container(
                                            width: 60,
                                            height: 40,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              gradient: isSelected
                                                  ? null
                                                  : const LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        Color.fromARGB(
                                                            255, 255, 235, 238),
                                                        Color.fromARGB(
                                                            255, 255, 205, 210),
                                                      ],
                                                    ),
                                              color: isSelected
                                                  ? Color.fromARGB(
                                                      255, 255, 111, 111)
                                                  : null,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              hour.toString().padLeft(2, '0'),
                                              style: GoogleFonts.poppins(
                                                fontSize: isSelected ? 20 : 16,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: Colors.black,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'Min',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Expanded(
                                    child: ListWheelScrollView.useDelegate(
                                      itemExtent: 40,
                                      perspective: 0.005,
                                      diameterRatio: 1.2,
                                      physics: const FixedExtentScrollPhysics(),
                                      controller: FixedExtentScrollController(
                                          initialItem: selectedMinute),
                                      onSelectedItemChanged: (int index) {
                                        setDialogState(() {
                                          selectedMinute = index;
                                        });
                                      },
                                      childDelegate:
                                          ListWheelChildBuilderDelegate(
                                        childCount: 60,
                                        builder: (context, index) {
                                          final isSelected =
                                              index == selectedMinute;
                                          return Container(
                                            width: 60,
                                            height: 40,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              gradient: isSelected
                                                  ? null
                                                  : const LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        Color.fromARGB(
                                                            255, 255, 235, 238),
                                                        Color.fromARGB(
                                                            255, 255, 205, 210),
                                                      ],
                                                    ),
                                              color: isSelected
                                                  ? Color.fromARGB(
                                                      255, 255, 111, 111)
                                                  : null,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              index.toString().padLeft(2, '0'),
                                              style: GoogleFonts.poppins(
                                                fontSize: isSelected ? 20 : 16,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: Colors.black,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'Period',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Expanded(
                                    child: ListWheelScrollView(
                                      itemExtent: 40,
                                      perspective: 0.005,
                                      diameterRatio: 1.2,
                                      physics: const FixedExtentScrollPhysics(),
                                      controller: FixedExtentScrollController(
                                          initialItem:
                                              selectedPeriod == 'AM' ? 0 : 1),
                                      onSelectedItemChanged: (index) {
                                        setDialogState(() {
                                          selectedPeriod = ['AM', 'PM'][index];
                                        });
                                      },
                                      children: ['AM', 'PM'].map((period) {
                                        final isSelected =
                                            period == selectedPeriod;
                                        return Container(
                                          width: 60,
                                          height: 40,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            gradient: isSelected
                                                ? null
                                                : const LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Color.fromARGB(
                                                          255, 255, 235, 238),
                                                      Color.fromARGB(
                                                          255, 255, 205, 210),
                                                    ],
                                                  ),
                                            color: isSelected
                                                ? Color.fromARGB(
                                                    255, 255, 111, 111)
                                                : null,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            period,
                                            style: GoogleFonts.poppins(
                                              fontSize: isSelected ? 20 : 16,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: Colors.black,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              int hour24 = selectedPeriod == 'AM'
                                  ? (selectedHour == 12 ? 0 : selectedHour)
                                  : (selectedHour == 12
                                      ? 12
                                      : selectedHour + 12);
                              final timeString =
                                  '${hour24.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';
                              onChanged(timeString);
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7.0),
                                side: const BorderSide(color: Colors.black),
                              ),
                              backgroundColor:
                                  Color.fromARGB(255, 255, 111, 111),
                            ),
                            child: Text(
                              'Select',
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 26.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: _isSavingBack || _isSavingContinue
                ? null
                : () async {
                    setState(() {
                      _isSavingBack = true;
                    });
                    try {
                      await _saveData();
                      if (mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  VideoUploadScreen(id: widget.id)),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isSavingBack = false;
                        });
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 144, 187),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: const BorderSide(color: Colors.black)),
            ),
            child: _isSavingBack
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.black)))
                : Text("Back",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _isSavingBack || _isSavingContinue
                ? null
                : () async {
                    if (_validateAvailabilityData()) {
                      setState(() {
                        _isSavingContinue = true;
                      });
                      try {
                        await _saveData();
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    LessonPricingScreen(id: widget.id)),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isSavingContinue = false;
                          });
                        }
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 144, 187),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: const BorderSide(color: Colors.black)),
            ),
            child: _isSavingContinue
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.black)))
                : Text("Save and continue",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    // Add cleanup if needed in future enhancements
  }
}

class TimeSlot {
  String? from;
  String? to;

  TimeSlot({this.from, this.to});

  // Convert time string (HH:mm) to minutes for comparison
  int toMinutes(String? time) {
    if (time == null || time.isEmpty) return -1; // Handle null or empty time
    try {
      final parts = time.split(':');
      if (parts.length != 2) throw FormatException('Invalid time format');
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) {
        throw RangeError('Time out of valid range');
      }
      return hours * 60 + minutes;
    } catch (e) {
      print('Error parsing time $time: $e');
      return -1; // Invalid time
    }
  }

  // Check if this time slot overlaps with another
  bool overlapsWith(TimeSlot other) {
    if (from == null ||
        from!.isEmpty ||
        to == null ||
        to!.isEmpty ||
        other.from == null ||
        other.from!.isEmpty ||
        other.to == null ||
        other.to!.isEmpty) {
      return false;
    }
    int start1 = toMinutes(from!);
    int end1 = toMinutes(to!);
    int start2 = toMinutes(other.from!);
    int end2 = toMinutes(other.to!);
    if (start1 == -1 || end1 == -1 || start2 == -1 || end2 == -1) return false;
    return start1 < end2 && start2 < end1;
  }
}
