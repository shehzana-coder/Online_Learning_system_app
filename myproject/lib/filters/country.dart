import 'package:flutter/material.dart';

class CountryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> tutors;
  final List<String> selectedCountries;
  final Function(List<String>) onApplyFilter;

  const CountryScreen({
    Key? key,
    required this.tutors,
    required this.selectedCountries,
    required this.onApplyFilter,
  }) : super(key: key);

  @override
  _CountryScreenState createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  late List<String> _selectedCountries;
  late List<String> _availableCountries;
  List<String> _filteredCountries = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCountries = List.from(widget.selectedCountries);

    // Extract unique countries from all tutors
    Set<String> countries = {};
    for (var tutor in widget.tutors) {
      String country = tutor['country'] ?? '';
      if (country.isNotEmpty) {
        countries.add(country);
      }
    }
    _availableCountries = countries.toList()..sort();
    _filteredCountries = List.from(_availableCountries);
    print('Available countries: $_availableCountries'); // Debug

    // Listen to search input changes
    _searchController.addListener(_filterCountries);
  }

  void _filterCountries() {
    setState(() {
      String query = _searchController.text.toLowerCase();
      _filteredCountries = _availableCountries
          .where((country) => country.toLowerCase().contains(query))
          .toList();
    });
  }

  void _toggleCountry(String country) {
    setState(() {
      if (_selectedCountries.contains(country)) {
        _selectedCountries.remove(country);
      } else {
        _selectedCountries.add(country);
      }
      print('Selected countries: $_selectedCountries'); // Debug
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCountries.clear();
      _searchController.clear();
      _filteredCountries = List.from(_availableCountries);
      print('Cleared countries'); // Debug
    });
  }

  void _applyFilters() {
    print('Applying countries: $_selectedCountries'); // Debug
    widget.onApplyFilter(List.from(_selectedCountries));
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getFlagEmoji(String countryName) {
    final Map<String, String> countryCodeMap = {
      'afghanistan': 'AF',
      'algeria': 'DZ',
      'argentina': 'AR',
      'australia': 'AU',
      'austria': 'AT',
      'bangladesh': 'BD',
      'belgium': 'BE',
      'brazil': 'BR',
      'canada': 'CA',
      'china': 'CN',
      'denmark': 'DK',
      'egypt': 'EG',
      'finland': 'FI',
      'france': 'FR',
      'germany': 'DE',
      'greece': 'GR',
      'india': 'IN',
      'indonesia': 'ID',
      'iran': 'IR',
      'iraq': 'IQ',
      'ireland': 'IE',
      'italy': 'IT',
      'japan': 'JP',
      'kenya': 'KE',
      'malaysia': 'MY',
      'mexico': 'MX',
      'nepal': 'NP',
      'netherlands': 'NL',
      'new zealand': 'NZ',
      'nigeria': 'NG',
      'norway': 'NO',
      'pakistan': 'PK',
      'philippines': 'PH',
      'poland': 'PL',
      'portugal': 'PT',
      'qatar': 'QA',
      'russia': 'RU',
      'saudi arabia': 'SA',
      'singapore': 'SG',
      'south africa': 'ZA',
      'south korea': 'KR',
      'spain': 'ES',
      'sri lanka': 'LK',
      'sweden': 'SE',
      'switzerland': 'CH',
      'thailand': 'TH',
      'turkey': 'TR',
      'uae': 'AE',
      'uk': 'GB',
      'ukraine': 'UA',
      'usa': 'US',
      'vietnam': 'VN'
    };

    String countryCode = countryCodeMap[countryName.toLowerCase()] ?? '';
    if (countryCode.isEmpty) {
      return '🏳️';
    }
    return countryCode
        .toUpperCase()
        .split('')
        .map((char) => String.fromCharCode(0x1F1E6 + char.codeUnitAt(0) - 0x41))
        .join();
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
            'Country',
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
                  hintText: 'Search countries...',
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
                '${_selectedCountries.length} selected',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Country list
            Expanded(
              child: _filteredCountries.isEmpty
                  ? const Center(
                      child: Text(
                        'No countries found',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = _filteredCountries[index];
                        final isSelected = _selectedCountries.contains(country);
                        return ListTile(
                          leading: Text(
                            _getFlagEmoji(country),
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            country,
                            style: const TextStyle(fontFamily: 'Poppins'),
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleCountry(country),
                            activeColor:
                                const Color.fromARGB(255, 255, 144, 187),
                          ),
                          onTap: () => _toggleCountry(country),
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
