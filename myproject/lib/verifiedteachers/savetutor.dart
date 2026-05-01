import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'teacherbiodata.dart';

class SavedTutorsScreen extends StatefulWidget {
  const SavedTutorsScreen({Key? key}) : super(key: key);

  @override
  _SavedTutorsScreenState createState() => _SavedTutorsScreenState();
}

class _SavedTutorsScreenState extends State<SavedTutorsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> savedTutors = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedTutors();
  }

  Future<void> _loadSavedTutors() async {
    try {
      String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Get saved tutor IDs from user's saved collection
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUserId).get();

      List<String> savedTutorIds = [];
      if (userDoc.exists) {
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;
        if (userData != null && userData['savedTutors'] != null) {
          savedTutorIds = List<String>.from(userData['savedTutors']);
        }
      }

      if (savedTutorIds.isEmpty) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Fetch tutor details for saved IDs
      List<Map<String, dynamic>> fetchedTutors = [];
      for (String tutorId in savedTutorIds) {
        DocumentSnapshot tutorDoc =
            await _firestore.collection('teachers').doc(tutorId).get();

        if (tutorDoc.exists) {
          Map<String, dynamic> tutorData =
              tutorDoc.data() as Map<String, dynamic>;

          // Get profile photo URL
          String? profilePhotoUrl =
              tutorData['profilePhoto'] is Map<String, dynamic>
                  ? tutorData['profilePhoto']['profilePhotoUrl']?.toString()
                  : null;

          // Get languages
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

          Map<String, dynamic> tutor = {
            'id': tutorDoc.id,
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
            'languages': languages,
            'profilePhotoUrl': profilePhotoUrl,
            'isFavorite': true, // Always true for saved tutors
          };

          fetchedTutors.add(tutor);
        }
      }

      setState(() {
        savedTutors = fetchedTutors;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading saved tutors: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeTutorFromSaved(String tutorId) async {
    try {
      String? currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _firestore.collection('users').doc(currentUserId).update({
        'savedTutors': FieldValue.arrayRemove([tutorId])
      });

      setState(() {
        savedTutors.removeWhere((tutor) => tutor['id'] == tutorId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tutor removed from saved list'),
          backgroundColor: Color.fromARGB(255, 255, 144, 187),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing tutor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: const Text(
          'Saved Tutors',
          style: TextStyle(
            fontFamily: 'poppins',
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 144, 187),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${savedTutors.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromARGB(255, 255, 144, 187),
                ),
              ),
            )
          : savedTutors.isEmpty
              ? _buildEmptyState()
              : _buildTutorsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 144, 187).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bookmark_border,
              size: 64,
              color: Color.fromARGB(255, 255, 144, 187),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Saved Tutors',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Start saving your favorite tutors\nto access them quickly',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 144, 187),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Browse Tutors',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: savedTutors.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final tutor = savedTutors[index];
        return _buildTutorCard(tutor);
      },
    );
  }

  Widget _buildTutorCard(Map<String, dynamic> tutor) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TutorProfileScreen(tutorId: tutor['id']),
          ),
        ).then((_) {
          _loadSavedTutors();
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: tutor['profilePhotoUrl'] != null
                    ? Image.network(
                        tutor['profilePhotoUrl'],
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 90,
                            height: 90,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color.fromARGB(255, 255, 144, 187),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage();
                        },
                      )
                    : _buildPlaceholderImage(),
              ),
              const SizedBox(width: 12),
              // Tutor Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  tutor['name'],
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildCountryFlag(tutor['country']),
                              if (tutor['verified']) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Color.fromARGB(255, 76, 175, 80),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.favorite,
                            color: Color.fromARGB(255, 255, 144, 187),
                            size: 24,
                          ),
                          onPressed: () {
                            _showRemoveDialog(tutor);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\$${tutor['price'].toStringAsFixed(0)} lesson',
                              style: const TextStyle(
                                color: Colors.black,
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
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Text(
                                  tutor['rating'].toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Icon(Icons.star,
                                    size: 16, color: Colors.amber),
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
                              fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${tutor['lessons']} lessons',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black87),
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
                            _buildLanguagesDisplay(tutor['languages']),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87),
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

  String _buildLanguagesDisplay(List<Map<String, dynamic>> languages) {
    if (languages.isEmpty) return 'English (Native)';
    String firstLanguage =
        '${languages[0]['language']} (${languages[0]['level']})';
    int additionalLanguages = languages.length - 1;
    return additionalLanguages > 0
        ? '$firstLanguage +$additionalLanguages'
        : firstLanguage;
  }

  void _showRemoveDialog(Map<String, dynamic> tutor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Remove Tutor',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to remove ${tutor['name']} from your saved tutors?',
            style: const TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeTutorFromSaved(tutor['id']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 144, 187),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}
