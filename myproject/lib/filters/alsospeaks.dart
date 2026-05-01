import 'package:flutter/material.dart';

class AlsoSpeakScreen extends StatefulWidget {
  final List<Map<String, dynamic>> tutors;
  final List<String> selectedLanguages;
  final Function(List<String>) onApplyFilter;

  const AlsoSpeakScreen({
    Key? key,
    required this.tutors,
    required this.selectedLanguages,
    required this.onApplyFilter,
  }) : super(key: key);

  @override
  _AlsoSpeakScreenState createState() => _AlsoSpeakScreenState();
}

class _AlsoSpeakScreenState extends State<AlsoSpeakScreen> {
  late List<String> _selectedLanguages;
  late List<String> _availableLanguages;
  List<String> _filteredLanguages = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedLanguages = List.from(widget.selectedLanguages);

    // Extract unique languages from all tutors
    Set<String> languages = {};
    for (var tutor in widget.tutors) {
      var tutorLanguages = tutor['languages'] ?? [];
      print('Tutor languages: $tutorLanguages'); // Debug
      if (tutorLanguages is List) {
        for (var language in tutorLanguages) {
          if (language is Map<String, dynamic>) {
            // Explicitly cast the 'language' field to String and check for null/empty
            String? lang = language['language']?.toString();
            if (lang != null && lang.isNotEmpty) {
              languages.add(lang);
            }
          }
        }
      }
    }
    _availableLanguages = languages.toList()..sort();
    _filteredLanguages = List.from(_availableLanguages);
    print('Available languages: $_availableLanguages'); // Debug

    // Listen to search input changes
    _searchController.addListener(_filterLanguages);
  }

  void _filterLanguages() {
    setState(() {
      String query = _searchController.text.toLowerCase();
      _filteredLanguages = _availableLanguages
          .where((language) => language.toLowerCase().contains(query))
          .toList();
    });
  }

  void _toggleLanguage(String language) {
    setState(() {
      if (_selectedLanguages.contains(language)) {
        _selectedLanguages.remove(language);
      } else {
        _selectedLanguages.add(language);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedLanguages.clear();
      _searchController.clear();
    });
  }

  void _applyFilters() {
    print('Applying filters: $_selectedLanguages'); // Debug
    widget.onApplyFilter(_selectedLanguages);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            'Also Speaks',
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
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Search languages...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.grey,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 255, 144, 187),
                    ),
                  ),
                ),
              ),
            ),
            // Clear all button
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
            // Selected count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${_selectedLanguages.length} selected',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Language list
            Expanded(
              child: _filteredLanguages.isEmpty
                  ? const Center(
                      child: Text(
                        'No languages found',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredLanguages.length,
                      itemBuilder: (context, index) {
                        final language = _filteredLanguages[index];
                        final isSelected =
                            _selectedLanguages.contains(language);
                        return ListTile(
                          title: Text(
                            language,
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleLanguage(language),
                            activeColor:
                                const Color.fromARGB(255, 255, 144, 187),
                          ),
                          onTap: () => _toggleLanguage(language),
                        );
                      },
                    ),
            ),
            // Apply button
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
