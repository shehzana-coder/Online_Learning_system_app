import 'package:flutter/material.dart';

class AvailabilityScreen extends StatefulWidget {
  final List<Map<String, dynamic>> tutors;
  final Map<String, List<String>> selectedAvailability;
  final Function(Map<String, List<String>>) onApplyFilter;

  const AvailabilityScreen({
    Key? key,
    required this.tutors,
    required this.selectedAvailability,
    required this.onApplyFilter,
  }) : super(key: key);

  @override
  _AvailabilityScreenState createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  late Map<String, List<String>> _selectedAvailability;
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _selectedAvailability = Map.from(widget.selectedAvailability);
    // Initialize empty lists for days if not present
    for (var day in _days) {
      _selectedAvailability.putIfAbsent(day, () => []);
    }
    print('Initial availability: $_selectedAvailability'); // Debug
  }

  void _toggleDay(String day) {
    setState(() {
      List<String> currentSelection = _selectedAvailability[day]!;
      if (currentSelection.isEmpty) {
        currentSelection.add('selected');
      } else {
        currentSelection.clear();
      }
      print('Toggled $day: ${currentSelection.isNotEmpty}'); // Debug
    });
  }

  void _clearFilters() {
    setState(() {
      for (var day in _days) {
        _selectedAvailability[day] = [];
      }
      print('Cleared availability: $_selectedAvailability'); // Debug
    });
  }

  void _applyFilters() {
    print('Applying availability: $_selectedAvailability'); // Debug
    widget.onApplyFilter(Map.from(_selectedAvailability));
    Navigator.pop(context);
  }

  int _countSelectedDays() {
    return _selectedAvailability.values
        .where((slots) => slots.isNotEmpty)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Availability',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _clearFilters,
                  child: const Text(
                    'Clear all',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color.fromARGB(255, 255, 144, 187),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${_countSelectedDays()} selected',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _days.length,
                itemBuilder: (context, index) {
                  final day = _days[index];
                  final isSelected = _selectedAvailability[day]!.isNotEmpty;
                  return ListTile(
                    title: Text(
                      day,
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleDay(day),
                      activeColor: const Color.fromARGB(255, 255, 144, 187),
                    ),
                    onTap: () => _toggleDay(day),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 144, 187),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
