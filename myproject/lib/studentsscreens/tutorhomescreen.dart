import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'messagescreen.dart';
import 'tutorinfo.dart';
import '/filters/alsospeaks.dart';
import '/filters/availability.dart';
import '/filters/country.dart';
import '/filters/price.dart';
import 'profilesetting.dart';
import 'homeschedul.dart';
import 'package:myproject/verifiedteachers/savetutor.dart';

class TutorScreen extends StatefulWidget {
  const TutorScreen({Key? key}) : super(key: key);

  @override
  _TutorScreenState createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  RangeValues _selectedPriceRange = const RangeValues(0.0, 500.0);

  List<Map<String, dynamic>> tutors = [];
  List<Map<String, dynamic>> allTutors = [];
  List<String> _selectedLanguages = [];
  Map<String, List<String>> _selectedAvailability = {};
  List<String> _selectedCountries = [];
  Map<String, String?> _profileImageCache = {};

  final List<String> filterOptions = [
    'Also Speaks',
    'Availability',
    'Country',
    'Price',
    'Native',
    'Experience',
    'Ratings',
    'Topics',
  ];

  final List<String> sortOptions = [
    'Price: Low to High',
    'Price: High to Low',
    'Rating: High to Low',
    'Experience: Most lessons',
    'Popularity: Most students',
    'Also Speaks',
  ];

  bool isSortDropdownVisible = false;
  String currentSortOption = 'Price: Low to High';

  @override
  void initState() {
    super.initState();
    _selectedAvailability = {
      'Monday': [],
      'Tuesday': [],
      'Wednesday': [],
      'Thursday': [],
      'Friday': [],
      'Saturday': [],
      'Sunday': [],
    };
    _fetchTutors();
  }

  Future<void> _toggleFavoriteStatus(String tutorId, bool isFavorite) async {
    try {
      String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      if (isFavorite) {
        await _firestore.collection('users').doc(currentUserId).update({
          'savedTutors': FieldValue.arrayUnion([tutorId])
        });
      } else {
        await _firestore.collection('users').doc(currentUserId).update({
          'savedTutors': FieldValue.arrayRemove([tutorId])
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating favorite: $e')),
      );
    }
  }

  Future<void> _fetchTutors() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('teachers').get();

      List<Map<String, dynamic>> fetchedTutors = [];
      String? currentUserId = _auth.currentUser?.uid;

      for (var doc in querySnapshot.docs) {
        if (doc.id == currentUserId) continue; // Skip current user

        Map<String, dynamic> tutorData = doc.data() as Map<String, dynamic>;

        // Fetch profile photo URL from Firestore
        String? profilePhotoUrl;
        if (_profileImageCache.containsKey(doc.id)) {
          profilePhotoUrl = _profileImageCache[doc.id];
        } else {
          profilePhotoUrl = tutorData['profilePhoto'] is Map<String, dynamic>
              ? tutorData['profilePhoto']['profilePhotoUrl']?.toString()
              : null;
          if (profilePhotoUrl == null || profilePhotoUrl.isEmpty) {
            profilePhotoUrl = null;
          }
          _profileImageCache[doc.id] = profilePhotoUrl;
          print('Profile photo URL for ${doc.id}: $profilePhotoUrl'); // Debug
        }

        // Fetch languages from tutorData['about']['languages']
        List<Map<String, dynamic>> languages = [];
        if (tutorData['about']?['languages'] is List) {
          languages = (tutorData['about']['languages'] as List)
              .map((item) => item is Map<String, dynamic>
                  ? {
                      'language': item['language']?.toString() ?? '',
                      'level': item['level']?.toString() ?? ''
                    }
                  : {'language': item.toString(), 'level': ''})
              .toList();
        }
        if (languages.isEmpty) {
          languages = [
            {'language': 'English', 'level': 'Native'}
          ];
        }

        // Normalize availability
        var availability =
            tutorData['availability'] ?? {'timezone': '', 'days': []};
        print('Raw availability for ${doc.id}: $availability'); // Debug
        List<String> days = [];
        if (availability['days'] is List) {
          days = List<String>.from(availability['days']);
        } else if (availability['days'] is Map) {
          days = (availability['days'] as Map).keys.cast<String>().toList();
        }

        Map<String, dynamic> tutor = {
          'id': doc.id,
          'name':
              '${tutorData['about']?['firstName'] ?? ''} ${tutorData['about']?['lastName'] ?? ''}',
          'country': tutorData['about']?['country'] ?? '',
          'verified': tutorData['status'] == 'verified',
          'price': tutorData['pricing'] != null
              ? (tutorData['pricing']['standardRate']?.toDouble() ?? 0.0)
              : 0.0,
          'lessonDuration': '1 hour lesson',
          'rating': tutorData['rating']?.toDouble() ?? 4.5,
          'reviews': tutorData['reviews']?.length ?? 0,
          'description': tutorData['description'] != null
              ? (tutorData['description']['intro'] ??
                  'Unlock your English mastery...')
              : 'Unlock your English mastery...',
          'students': tutorData['students'] ?? 0,
          'lessons': tutorData['lessons'] ?? 0,
          'languages': languages, // Updated to store as list of maps
          'isFavorite': tutorData['isFavorite'] ?? false,
          'profilePhotoUrl': profilePhotoUrl,
          'aboutInfo': tutorData['about'] ?? {},
          'certifications': tutorData['certifications'] ?? [],
          'education': tutorData['education'] ?? [],
          'descriptionDetails': tutorData['description'] ??
              {'intro': '', 'experience': '', 'motivation': ''},
          'videoUrl': tutorData['description']?['videoUrl'] ?? '',
          'availability': {
            'timezone': availability['timezone'] ?? '',
            'days': days
          },
          'pricing':
              tutorData['pricing'] ?? {'standardRate': 0.0, 'introRate': 0.0}
        };

        fetchedTutors.add(tutor);
      }

      if (mounted) {
        setState(() {
          allTutors = fetchedTutors;
          tutors = List.from(allTutors);
          _sortTutors(currentSortOption);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching tutors: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      tutors = List.from(allTutors);

      // Apply language filter
      if (_selectedLanguages.isNotEmpty) {
        print('Filtering by languages: $_selectedLanguages'); // Debug
        tutors = tutors.where((tutor) {
          var tutorLanguages = tutor['languages'] ?? [];
          List<String> languages = tutorLanguages
              .map((lang) => lang['language']?.toString() ?? '')
              .where((lang) => lang.isNotEmpty) // Filter out empty strings
              .toList();
          return _selectedLanguages
              .every((selectedLang) => languages.contains(selectedLang));
        }).toList();
      }

      // Apply price filter
      if (_selectedPriceRange.start > 0.0 || _selectedPriceRange.end < 500.0) {
        print(
            'Filtering by price range: ${_selectedPriceRange.start} - ${_selectedPriceRange.end}'); // Debug
        tutors = tutors.where((tutor) {
          double price = (tutor['price'] as num?)?.toDouble() ?? 0.0;
          return price >= _selectedPriceRange.start &&
              price <= _selectedPriceRange.end;
        }).toList();
      }

      // Apply availability filter
      if (_selectedAvailability.values.any((slots) => slots.isNotEmpty)) {
        print('Filtering by availability: $_selectedAvailability'); // Debug
        tutors = tutors.where((tutor) {
          var availability = tutor['availability'] ?? {'days': []};
          List<String> tutorDays = [];
          if (availability['days'] is List) {
            tutorDays = List<String>.from(availability['days']);
          } else if (availability['days'] is Map) {
            tutorDays =
                (availability['days'] as Map).keys.cast<String>().toList();
          }
          return _selectedAvailability.entries.any((entry) {
            String day = entry.key;
            List<String> selected = entry.value;
            return selected.isNotEmpty && tutorDays.contains(day);
          });
        }).toList();
      }

      // Apply country filter
      if (_selectedCountries.isNotEmpty) {
        print('Filtering by countries: $_selectedCountries'); // Debug
        tutors = tutors.where((tutor) {
          String tutorCountry = tutor['country'] ?? '';
          return _selectedCountries.contains(tutorCountry);
        }).toList();
      }

      print('Filtered tutors count: ${tutors.length}'); // Debug
      _sortTutors(currentSortOption);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text(
              'speakora',
              style: TextStyle(
                color: Color.fromARGB(255, 0, 0, 0),
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 60,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  children: filterOptions.map((option) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: OutlinedButton(
                        onPressed: () {
                          if (option == 'Also Speaks') {
                            if (allTutors.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('No tutors available to filter')),
                              );
                              return;
                            }
                            print(
                                'Navigating to AlsoSpeakScreen with ${allTutors.length} tutors'); // Debug
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AlsoSpeakScreen(
                                  tutors: allTutors,
                                  selectedLanguages:
                                      List.from(_selectedLanguages),
                                  onApplyFilter: (List<String> selected) {
                                    print(
                                        'Applying languages: $selected'); // Debug
                                    setState(() {
                                      _selectedLanguages = List.from(selected);
                                      _applyFilters();
                                    });
                                  },
                                ),
                              ),
                            );
                          } else if (option == 'Availability') {
                            if (allTutors.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('No tutors available to filter')),
                              );
                              return;
                            }
                            print(
                                'Navigating to AvailabilityScreen with ${allTutors.length} tutors'); // Debug
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AvailabilityScreen(
                                  tutors: allTutors,
                                  selectedAvailability:
                                      Map.from(_selectedAvailability),
                                  onApplyFilter:
                                      (Map<String, List<String>> selected) {
                                    print(
                                        'Applying availability: $selected'); // Debug
                                    setState(() {
                                      _selectedAvailability =
                                          Map.from(selected);
                                      _applyFilters();
                                    });
                                  },
                                ),
                              ),
                            );
                          } else if (option == 'Country') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CountryScreen(
                                  tutors: allTutors,
                                  selectedCountries: _selectedCountries,
                                  onApplyFilter: (List<String> selected) {
                                    setState(() {
                                      _selectedCountries = selected;
                                      _applyFilters();
                                    });
                                  },
                                ),
                              ),
                            );
                          } else if (option == 'Price') {
                            if (allTutors.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('No tutors available to filter')),
                              );
                              return;
                            }
                            print(
                                'Navigating to PriceFilterScreen with ${allTutors.length} tutors'); // Debug
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PriceFilterScreen(
                                  tutors: allTutors,
                                  selectedPriceRange: _selectedPriceRange,
                                  onApplyFilter: (RangeValues selected) {
                                    print(
                                        'Applying price range: ${selected.start} - ${selected.end}'); // Debug
                                    setState(() {
                                      _selectedPriceRange = selected;
                                      _applyFilters();
                                    });
                                  },
                                ),
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          side: const BorderSide(color: Colors.grey),
                          backgroundColor: Colors.white,
                        ),
                        child: Text(
                          option,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.bookmark_outline, color: Colors.grey),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SavedTutorsScreen(),
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Spacer(),
                const Text(
                  'Sort by',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.filter_list, color: Colors.black),
                  color: Colors.white, // Added white background color
                  onSelected: (String value) {
                    if (value == 'Also Speaks') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AlsoSpeakScreen(
                            tutors: allTutors,
                            selectedLanguages: _selectedLanguages,
                            onApplyFilter: (List<String> selected) {
                              setState(() {
                                _selectedLanguages = selected;
                                _applyFilters();
                              });
                            },
                          ),
                        ),
                      );
                    } else {
                      setState(() {
                        currentSortOption = value;
                        _sortTutors(value);
                      });
                    }
                  },
                  offset: const Offset(0, 40),
                  itemBuilder: (BuildContext context) {
                    return sortOptions.map((String option) {
                      return PopupMenuItem<String>(
                        value: option,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              option,
                              style: TextStyle(
                                color: currentSortOption == option &&
                                        option != 'Also Speaks'
                                    ? Color.fromARGB(255, 255, 144, 187)
                                    : Colors.black87,
                                fontWeight: currentSortOption == option &&
                                        option != 'Also Speaks'
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (currentSortOption == option &&
                                option != 'Also Speaks')
                              Icon(
                                Icons.check,
                                color: Color.fromARGB(255, 255, 144, 187),
                              )
                          ],
                        ),
                      );
                    }).toList();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: tutors.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: tutors.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tutor = tutors[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TutorProfileScreen(
                                tutorId: tutor['id'],
                              ),
                            ),
                          ).then((value) {
                            setState(() {});
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: tutor['profilePhotoUrl'] != null
                                      ? Image.network(
                                          tutor['profilePhotoUrl'],
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (BuildContext context,
                                              Widget child,
                                              ImageChunkEvent?
                                                  loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Container(
                                              width: 90,
                                              height: 90,
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return _buildPlaceholderImage();
                                          },
                                        )
                                      : _buildPlaceholderImage(),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                tutor['name'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              _buildCountryFlag(
                                                  tutor['country']),
                                              if (tutor['verified'])
                                                const SizedBox(width: 4),
                                              if (tutor['verified'])
                                                const Icon(Icons.verified,
                                                    size: 16,
                                                    color: Color.fromARGB(
                                                        255, 76, 175, 80)),
                                            ],
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              tutor['isFavorite']
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: tutor['isFavorite']
                                                  ? Color.fromARGB(
                                                      255, 255, 144, 187)
                                                  : Colors.grey,
                                            ),
                                            onPressed: () async {
                                              await _toggleFavoriteStatus(
                                                  tutor['id'],
                                                  !tutor['isFavorite']);
                                              setState(() {
                                                tutors[index]['isFavorite'] =
                                                    !tutors[index]
                                                        ['isFavorite'];
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '\$${tutor['price']} lesson',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                tutor['lessonDuration'],
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    '${tutor['rating'].toStringAsFixed(1)}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const Icon(Icons.star,
                                                      size: 16,
                                                      color: Colors.amber),
                                                  Text(
                                                    ' ${tutor['reviews']} reviews',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        tutor['description'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline,
                                              size: 16, color: Colors.black),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${tutor['students']} students',
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            '${tutor['lessons']} lessons',
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.language,
                                              size: 16, color: Colors.black),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              _buildLanguagesDisplay(
                                                  tutor['languages']),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 255, 144, 187),
        unselectedItemColor: Colors.black,
        currentIndex: 0,
        onTap: (index) {
          _navigateToScreen(context, index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.send),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Setting',
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(BuildContext context, int index) {
    if (index == 0) return; // No navigation if already on Search

    switch (index) {
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MessagesScreen(tutorId: ''),
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ScheduleScreen()),
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

  Widget _buildPlaceholderImage() {
    return Container(
      width: 90,
      height: 90,
      color: Colors.grey[200],
      child: Icon(Icons.person, size: 50, color: Colors.grey[400]),
    );
  }

  Widget _buildCountryFlag(String country) {
    final Map<String, String> countryCodeMap = {
      'afghanistan': 'AF',
      'algeria': 'DZ',
      'argentina': 'AR',
      'australia': 'AU',
      'austria': 'AT',
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

    String getFlagEmoji(String countryName) {
      String countryCode = countryCodeMap[countryName.toLowerCase()] ?? '';
      if (countryCode.isEmpty) {
        return '🏳️';
      }
      return countryCode
          .toUpperCase()
          .split('')
          .map((char) =>
              String.fromCharCode(0x1F1E6 + char.codeUnitAt(0) - 0x41))
          .join();
    }

    String flag = getFlagEmoji(country);
    return Text(flag, style: const TextStyle(fontSize: 16));
  }

  void _sortTutors(String sortOption) {
    setState(() {
      switch (sortOption) {
        case 'Price: Low to High':
          tutors
              .sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
          break;
        case 'Price: High to Low':
          tutors
              .sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
          break;
        case 'Rating: High to Low':
          tutors.sort(
              (a, b) => (b['rating'] as num).compareTo(a['rating'] as num));
          break;
        case 'Experience: Most lessons':
          tutors.sort(
              (a, b) => (b['lessons'] as num).compareTo(a['lessons'] as num));
          break;
        case 'Popularity: Most students':
          tutors.sort(
              (a, b) => (b['students'] as num).compareTo(a['students'] as num));
          break;
      }
    });
  }

  String _buildLanguagesDisplay(List<Map<String, dynamic>> languages) {
    if (languages.isEmpty) return 'English (Native)';
    String firstLanguage =
        '${languages[0]['language']} (${languages[0]['level']})';
    int additionalLanguages = languages.length - 1;
    return additionalLanguages > 0
        ? '$firstLanguage +$additionalLanguages'
        : firstLanguage;
  }
}
