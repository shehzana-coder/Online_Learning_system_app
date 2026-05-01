import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'videoplayer.dart';
import 'seemyschedule.dart';
import 'chatscreen.dart';
import 'teacheravailability.dart';

class TutorProfileScreen extends StatefulWidget {
  final String tutorId;

  const TutorProfileScreen({Key? key, required this.tutorId}) : super(key: key);

  @override
  _TutorProfileScreenState createState() => _TutorProfileScreenState();
}

class _TutorProfileScreenState extends State<TutorProfileScreen> {
  Map<String, dynamic>? _tutorDetails;
  bool _showFullDescription = false;
  String? _videoUrl;
  String? _profilePhotoUrl;
  String? _profileImageCache;

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
        Map<String, dynamic> tutorData = doc.data() as Map<String, dynamic>;

        // Fetch profile photo URL from Firestore
        if (_profileImageCache != null) {
          _profilePhotoUrl = _profileImageCache;
        } else {
          _profilePhotoUrl = tutorData['profilePhoto'] is Map<String, dynamic>
              ? tutorData['profilePhoto']['profilePhotoUrl']?.toString()
              : null;
          if (_profilePhotoUrl == null || _profilePhotoUrl!.isEmpty) {
            _profilePhotoUrl = null;
          }
          _profileImageCache = _profilePhotoUrl;
          print(
              'Profile photo URL for ${widget.tutorId}: $_profilePhotoUrl'); // Debug
        }

        // Fetch video URL
        _videoUrl = tutorData['video']?['videoUrl'];
        if (_videoUrl == null || _videoUrl!.isEmpty) {
          _videoUrl = null;
        }

        // Fetch languages with levels
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
        print('Languages for ${widget.tutorId}: $languages'); // Debug

        // Fetch teaching course
        String teachingCourse = tutorData['about'] is Map<String, dynamic>
            ? tutorData['about']['teachingCourse']?.toString() ??
                'Not specified'
            : 'Not specified';
        print(
            'Teaching course for ${widget.tutorId}: $teachingCourse'); // Debug

        _tutorDetails = {
          'id': widget.tutorId,
          'name':
              '${tutorData['about']?['firstName'] ?? 'Unknown'} ${tutorData['about']?['lastName'] ?? 'Tutor'}',
          'country': tutorData['about']?['country'] ?? 'Unknown',
          'rating': tutorData['rating']?.toDouble() ?? 0.0,
          'price': tutorData['pricing']?['standardRate']?.toDouble() ?? 0.0,
          'reviews': tutorData['reviews']?.length ?? 0,
          'lessons': tutorData['lessons'] ?? 0,
          'verified': tutorData['status'] == 'verified',
          'isFavorite': tutorData['isFavorite'] ?? false,
          'descriptionDetails': {
            'intro': tutorData['description']?['intro'] ??
                'No description available',
          },
          'languages': languages,
          'teachingCourse': teachingCourse,
          'subjects': tutorData['subjects'] ?? [],
          'experience': tutorData['experience'] ?? [],
          'education': tutorData['education'] ?? [],
          'availability': tutorData['availability'] ?? {},
          'superTutor': tutorData['superTutor'] ?? false,
          'lastBooked': tutorData['lastBooked'] ?? 0,
        };

        if (mounted) {
          setState(() {});
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Tutor not found')));
        }
      }
    } catch (e) {
      print("Error fetching tutor details: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching tutor details: $e')),
        );
      }
    }
  }

  Widget _buildVideoSection() {
    return GestureDetector(
      onTap: () {
        if (_videoUrl != null && _videoUrl!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(
                videoUrl: _videoUrl!,
                tutorName: _tutorDetails?['name'] ?? 'Tutor',
                isAssetVideo: false,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No video available for this tutor')),
          );
        }
      },
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: _videoUrl != null && _videoUrl!.isNotEmpty
                  ? Image.network(
                      _getVideoThumbnail(_videoUrl!),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[300],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Video Preview',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[300],
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videocam, size: 50, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Video Preview',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.play_arrow,
                size: 40.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getVideoThumbnail(String url) {
    String? youtubeId = _extractYouTubeId(url);
    if (youtubeId.isNotEmpty) {
      return 'https://img.youtube.com/vi/$youtubeId/0.jpg';
    }
    return url;
  }

  String _extractYouTubeId(String url) {
    RegExp regExp = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#\&\?]*).*',
    );
    Match? match = regExp.firstMatch(url);
    return (match != null && match.group(7)!.length == 11)
        ? match.group(7)!
        : '';
  }

  @override
  Widget build(BuildContext context) {
    if (_tutorDetails == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _tutorDetails!['isFavorite']
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: _tutorDetails!['isFavorite'] ? Colors.red : Colors.black,
            ),
            onPressed: () async {
              setState(() {
                _tutorDetails!['isFavorite'] = !_tutorDetails!['isFavorite'];
              });
              await _firestore
                  .collection('teachers')
                  .doc(_tutorDetails!['id'])
                  .update({'isFavorite': _tutorDetails!['isFavorite']});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildVideoSection(),
                  ),

                  // Profile Info Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: _profilePhotoUrl != null
                              ? Image.network(
                                  _profilePhotoUrl!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _tutorDetails!['name'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    _tutorDetails!['country'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildCountryFlag(_tutorDetails!['country']),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stats Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn(
                          icon: Icons.verified,
                          label: 'Verified',
                          iconColor: _tutorDetails!['verified']
                              ? Colors.green
                              : Colors.grey,
                        ),
                        _buildStatColumn(
                          icon: Icons.star,
                          text:
                              '${_tutorDetails!['rating'].toStringAsFixed(1)}',
                          label: 'Rating',
                          iconColor: Colors.amber,
                        ),
                        _buildStatColumn(
                          text:
                              '\$${_tutorDetails!['price'].toStringAsFixed(0)}',
                          label: 'Per lesson',
                        ),
                        _buildStatColumn(
                          text: '${_tutorDetails!['reviews']}',
                          label: 'Reviews',
                        ),
                        _buildStatColumn(
                          text: '${_tutorDetails!['lessons']}',
                          label: 'Lessons',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // About me section
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'About me',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tutorDetails!['descriptionDetails']['intro'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontFamily: 'poppins',
                            height: 1.5,
                          ),
                          maxLines: _showFullDescription ? null : 3,
                          overflow: _showFullDescription
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showFullDescription = !_showFullDescription;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 17, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                _showFullDescription
                                    ? 'Show less'
                                    : 'Show more',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'poppins',
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Languages Section
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Languages',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_tutorDetails!['languages'].isNotEmpty) ...[
                          Row(
                            children: [
                              Text(
                                _tutorDetails!['languages'][0]['language'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      const Color.fromARGB(255, 255, 144, 187),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Native',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_tutorDetails!['languages'].length > 1) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Others',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._tutorDetails!['languages']
                                .sublist(1)
                                .map((lang) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Color.fromARGB(
                                                255, 255, 144, 187),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            lang['language'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '(${lang['level']})',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontFamily: 'Poppins',
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ],
                        ] else ...[
                          const Text(
                            'No languages specified',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Poppins',
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Teaching Course Section
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Teaching Course',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _tutorDetails!['teachingCourse'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // See my Schedule button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Seemyschedule(
                                tutorId: _tutorDetails!['id'],
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'See my Schedule',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Reviews Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.black, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${_tutorDetails!['rating'].toStringAsFixed(1)} - ${_tutorDetails!['reviews']} reviews',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Reviews List
                  Container(
                    height: 180,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('teachers')
                          .doc(_tutorDetails!['id'])
                          .collection('reviews')
                          .limit(3)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        var reviews = snapshot.data!.docs;

                        if (reviews.isEmpty) {
                          return const Center(
                            child: Text(
                              'No reviews yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: reviews.length,
                          itemBuilder: (context, index) {
                            var review =
                                reviews[index].data() as Map<String, dynamic>;
                            return _buildReviewCard(
                              name: review['name'] ?? 'Unknown',
                              flag: review['country'] ?? 'UK',
                              daysAgo: review['daysAgo'] ?? 'N/A',
                              avatarUrl:
                                  review['avatarUrl'] ?? 'assets/images/2.png',
                              comment:
                                  review['comment'] ?? 'No comment provided',
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Show all reviews button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: OutlinedButton(
                      onPressed: () {
                        // Navigate to full reviews screen
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(double.infinity, 60),
                      ),
                      child: const Text(
                        'Show all reviews',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // My resume section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: const Text(
                        'My resume',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Navigate to resume screen
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chat_bubble_outline,
                        color: Colors.black),
                    onPressed: () {
                      // Navigate to chat screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            recipientId: _tutorDetails!['id'],
                            recipientName: _tutorDetails!['name'],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SessionSchedulingScreen(
                              tutorId: _tutorDetails!['id'],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 255, 144, 187),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Buy trial session',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    IconData? icon,
    String? text,
    required String label,
    Color iconColor = Colors.black,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(
            icon,
            color: iconColor,
            size: 20,
          )
        else if (text != null)
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

Widget _buildCountryFlag(String country) {
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

  String getFlagEmoji(String countryName) {
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

  String flag = getFlagEmoji(country);
  return Text(flag, style: const TextStyle(fontSize: 16));
}

Widget _buildReviewCard({
  required String name,
  required String flag,
  required String daysAgo,
  required String avatarUrl,
  required String comment,
}) {
  return Container(
    width: 240,
    margin: const EdgeInsets.only(right: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.grey[200]!),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: avatarUrl.startsWith('http')
                  ? NetworkImage(avatarUrl)
                  : AssetImage(avatarUrl) as ImageProvider,
              onBackgroundImageError: (exception, stackTrace) {
                print('Error loading avatar image: $exception');
              },
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildCountryFlag(flag),
                  ],
                ),
                Text(
                  daysAgo,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          comment,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}
