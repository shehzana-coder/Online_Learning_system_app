import 'package:flutter/material.dart';
import 'Filterhomescreencourses.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({Key? key}) : super(key: key);

  @override
  _CoursesScreenState createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final Map<String, List<String>> levelToClasses = {
    'Beginner': ['Class 7', 'Class 8'],
    'Matric': ['Class 9', 'Class 10'],
    'Intermediate': ['Class 11', 'Class 12'],
    'Bachelor': ['Year 13', 'Year 14', 'Year 15', 'Year 16'],
  };

  final List<String> streams = [
    'ICS',
    'Medical',
    'Mathematics',
    'Arts',
    'Commerce',
  ];

  String? selectedLevel;
  String? selectedClass;
  String? selectedStream;

  final TextStyle whiteText = const TextStyle(color: Colors.white);
  final TextStyle blackText = const TextStyle(color: Colors.black);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        backgroundColor: const Color.fromARGB(255, 249, 249, 249),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Course Level:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            buildDropdown(
              value: selectedLevel,
              hint: 'Choose Course Level',
              items: levelToClasses.keys.toList(),
              onChanged: (value) {
                setState(() {
                  selectedLevel = value;
                  selectedClass = null;
                  selectedStream = null;
                });
              },
            ),
            const SizedBox(height: 16),
            if (selectedLevel != null) ...[
              const Text(
                'Select Class:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildDropdown(
                value: selectedClass,
                hint: 'Choose Class',
                items: levelToClasses[selectedLevel]!,
                onChanged: (value) {
                  setState(() {
                    selectedClass = value;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            // Stream selection logic updated for 'Beginner' and 'Matric' levels
            if (selectedLevel != 'Beginner' &&
                selectedLevel != 'Matric' &&
                selectedClass != null) ...[
              const Text(
                'Select Stream:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              buildDropdown(
                value: selectedStream,
                hint: 'Choose Stream',
                items: streams,
                onChanged: (value) {
                  setState(() {
                    selectedStream = value;
                  });
                },
              ),
              const SizedBox(height: 24),
            ],
            if (selectedLevel != null &&
                selectedClass != null &&
                (selectedLevel == 'Beginner' ||
                    selectedLevel == 'Matric' ||
                    selectedStream != null))
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => LearningPartnerPage(
                              courseLevel: selectedLevel,
                              className: selectedClass,
                              stream: selectedStream,
                            ),
                      ),
                    );
                  },
                  child: const Text('Find Mentors'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Reusable dropdown widget
  Widget buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black), // Border color black
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(), // Remove default underline
        hint: Text(hint, style: blackText), // Hint text black
        iconEnabledColor: Colors.black, // Dropdown icon color black
        dropdownColor: Colors.white, // Dropdown list background white
        style: blackText, // Selected text color black
        items:
            items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: blackText), // List items text black
              );
            }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
