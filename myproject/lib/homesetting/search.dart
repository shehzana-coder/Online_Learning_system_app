import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final List<Map<String, String>> tutors = [
    {"name": "Mr. M. Akram", "qualification": "Master in CS"},
    {"name": "Ms. Ayesha Khan", "qualification": "PhD in Math"},
    {"name": "Mr. John Doe", "qualification": "MSc Physics"},
    {"name": "Mrs. Fatima Noor", "qualification": "MPhil Chemistry"},
    {"name": "Sir Ali Raza", "qualification": "BS Computer Science"},
  ];

  List<Map<String, String>> filteredTutors = [];

  @override
  void initState() {
    super.initState();
    filteredTutors = tutors; // Initially show all tutors
  }

  void _filterTutors(String query) {
    final List<Map<String, String>> results;
    if (query.isEmpty) {
      results = tutors;
    } else {
      results =
          tutors.where((tutor) {
            final nameLower = tutor['name']!.toLowerCase();
            final queryLower = query.toLowerCase();
            return nameLower.contains(queryLower);
          }).toList();
    }
    setState(() {
      filteredTutors = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A54),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1A54),
        elevation: 0,
        title: const Text(
          'Search Tutor',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterTutors,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child:
                filteredTutors.isEmpty
                    ? const Center(
                      child: Text(
                        'No tutor found',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    )
                    : ListView.builder(
                      itemCount: filteredTutors.length,
                      itemBuilder: (context, index) {
                        final tutor = filteredTutors[index];
                        return Card(
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF0F1A54),
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(
                              tutor['name']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(tutor['qualification']!),
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
