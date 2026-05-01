import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VideoLecturesPage extends StatefulWidget {
  const VideoLecturesPage({super.key});

  @override
  State<VideoLecturesPage> createState() => _VideoLecturesPageState();
}

class _VideoLecturesPageState extends State<VideoLecturesPage> {
  int _selectedCategoryIndex = 0;
  int? _playingIndex;
  final Set<int> _likedVideos = {};
  final Set<int> _dislikedVideos = {};
  final Set<int> _savedVideos = {};

  final List<String> _categories = [
    'All',
    'Biology',
    'Physics',
    'Chemistry',
    'Mathematics',
  ];

  final List<Map<String, dynamic>> _allVideos = [
    {
      "title": "Respiration",
      "duration": "5:55 mins",
      "subject": "Biology",
      "color": Colors.green,
      "icon": Icons.eco,
      "views": "1.2K",
      "description": "Learn about cellular respiration and energy production in living organisms.",
    },
    {
      "title": "Heart in Biology",
      "duration": "7:10 mins",
      "subject": "Biology",
      "color": Colors.green,
      "icon": Icons.eco,
      "views": "980",
      "description": "Detailed explanation of the human heart structure and function.",
    },
    {
      "title": "Digestive System",
      "duration": "6:30 mins",
      "subject": "Biology",
      "color": Colors.green,
      "icon": Icons.eco,
      "views": "1.5K",
      "description": "Overview of the human digestive system and nutrient absorption.",
    },
    {
      "title": "Nervous System",
      "duration": "8:20 mins",
      "subject": "Biology",
      "color": Colors.green,
      "icon": Icons.eco,
      "views": "2.1K",
      "description": "Understanding the central and peripheral nervous systems.",
    },
    {
      "title": "Photosynthesis",
      "duration": "5:00 mins",
      "subject": "Biology",
      "color": Colors.green,
      "icon": Icons.eco,
      "views": "3.4K",
      "description": "How plants convert sunlight into energy through photosynthesis.",
    },
    {
      "title": "Newton's Laws",
      "duration": "9:15 mins",
      "subject": "Physics",
      "color": Colors.orange,
      "icon": Icons.science,
      "views": "4.2K",
      "description": "Comprehensive explanation of Newton's three laws of motion.",
    },
    {
      "title": "Waves & Sound",
      "duration": "7:45 mins",
      "subject": "Physics",
      "color": Colors.orange,
      "icon": Icons.science,
      "views": "1.8K",
      "description": "Properties of waves, sound, and their applications.",
    },
    {
      "title": "Organic Chemistry",
      "duration": "11:00 mins",
      "subject": "Chemistry",
      "color": Colors.purple,
      "icon": Icons.biotech,
      "views": "2.3K",
      "description": "Introduction to organic compounds and chemical reactions.",
    },
    {
      "title": "Algebra Fundamentals",
      "duration": "8:30 mins",
      "subject": "Mathematics",
      "color": Colors.blue,
      "icon": Icons.calculate,
      "views": "5.1K",
      "description": "Core concepts of algebra including equations and functions.",
    },
    {
      "title": "Trigonometry",
      "duration": "10:20 mins",
      "subject": "Mathematics",
      "color": Colors.blue,
      "icon": Icons.calculate,
      "views": "3.7K",
      "description": "Trigonometric ratios, identities, and problem solving.",
    },
  ];

  List<Map<String, dynamic>> get _filteredVideos {
    if (_selectedCategoryIndex == 0) return _allVideos;
    final category = _categories[_selectedCategoryIndex];
    return _allVideos.where((v) => v['subject'] == category).toList();
  }

  Map<String, dynamic> get _featuredVideo => _allVideos[0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A54),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Video Lectures',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Now Playing / Featured
            _buildFeaturedPlayer(),
            const SizedBox(height: 24),

            // Category filter
            const Text(
              'Browse by Subject',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedCategoryIndex == index;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategoryIndex = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white24,
                        ),
                      ),
                      child: Text(
                        _categories[index],
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF0F1A54)
                              : Colors.white70,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Video count
            Text(
              '${_filteredVideos.length} lecture${_filteredVideos.length != 1 ? 's' : ''}',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 10),

            // Video List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredVideos.length,
              itemBuilder: (context, index) {
                return _videoTile(_filteredVideos[index], index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedPlayer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_fill,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Now Playing',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Video player placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade900,
                    Colors.indigo.shade900,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Decorative circles
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -10,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ),
                  // Play button
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Video player integration coming soon!'),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                  // Duration badge
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _featuredVideo['duration'],
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _featuredVideo['title'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                _featuredVideo['icon'] as IconData,
                color: _featuredVideo['color'] as Color,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                _featuredVideo['subject'],
                style: TextStyle(
                  color: _featuredVideo['color'] as Color,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.visibility, color: Colors.white54, size: 14),
              const SizedBox(width: 4),
              Text(
                '${_featuredVideo['views']} views',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _actionButton(
                _likedVideos.contains(-1) ? Icons.thumb_up : Icons.thumb_up_outlined,
                'Like',
                _likedVideos.contains(-1) ? Colors.blue : Colors.white70,
                () {
                  setState(() {
                    if (_likedVideos.contains(-1)) {
                      _likedVideos.remove(-1);
                    } else {
                      _likedVideos.add(-1);
                      _dislikedVideos.remove(-1);
                    }
                  });
                },
              ),
              _actionButton(
                _dislikedVideos.contains(-1) ? Icons.thumb_down : Icons.thumb_down_outlined,
                'Dislike',
                _dislikedVideos.contains(-1) ? Colors.red : Colors.white70,
                () {
                  setState(() {
                    if (_dislikedVideos.contains(-1)) {
                      _dislikedVideos.remove(-1);
                    } else {
                      _dislikedVideos.add(-1);
                      _likedVideos.remove(-1);
                    }
                  });
                },
              ),
              _actionButton(Icons.share_outlined, 'Share', Colors.white70, () {
                _shareVideo(_featuredVideo);
              }),
              _actionButton(
                _savedVideos.contains(-1) ? Icons.bookmark : Icons.bookmark_border,
                'Save',
                _savedVideos.contains(-1) ? Colors.amber : Colors.white70,
                () {
                  setState(() {
                    if (_savedVideos.contains(-1)) {
                      _savedVideos.remove(-1);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Removed from saved'), duration: Duration(seconds: 1)),
                      );
                    } else {
                      _savedVideos.add(-1);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Saved!'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
                      );
                    }
                  });
                },
              ),
              _actionButton(Icons.feedback_outlined, 'Feedback', Colors.white70, () {
                _showFeedbackDialog(_featuredVideo);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _shareVideo(Map<String, dynamic> video) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.share, color: Color(0xFF0F1A54)),
            SizedBox(width: 8),
            Text('Share Video'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share "${video['title']}" with others:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                '📚 Check out this lecture: ${video['title']} (${video['subject']}) on TeachUp!\nhttps://teachup.app/videos',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: '📚 Check out this lecture: ${video['title']} (${video['subject']}) on TeachUp!\nhttps://teachup.app/videos',
              ));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link copied to clipboard!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F1A54),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Link'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(Map<String, dynamic> video) {
    int _rating = 0;
    final feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Rate this Lecture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                video['title'],
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setDialogState(() => _rating = i + 1),
                  child: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your thoughts (optional)...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_rating == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a rating.')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Thanks for your feedback! You rated $_rating/5 stars.'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F1A54),
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _videoTile(Map<String, dynamic> video, int index) {
    final isPlaying = _playingIndex == index;
    return Card(
      color: isPlaying
          ? Colors.white.withOpacity(0.2)
          : Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: GestureDetector(
          onTap: () {
            setState(() => _playingIndex = isPlaying ? null : index);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Playing: ${video['title']}'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Container(
            width: 60,
            height: 50,
            decoration: BoxDecoration(
              color: (video['color'] as Color).withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        title: Text(
          video['title'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              video['icon'] as IconData,
              color: video['color'] as Color,
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              video['subject'],
              style: TextStyle(
                color: video['color'] as Color,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.access_time, color: Colors.white54, size: 12),
            const SizedBox(width: 2),
            Text(
              video['duration'],
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.more_vert, color: Colors.white54),
            Text(
              video['views'],
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
        onTap: () => _showVideoDetail(video),
      ),
    );
  }

  void _showVideoDetail(Map<String, dynamic> video) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: const BoxDecoration(
          color: Color(0xFF1A2A6C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(video['icon'] as IconData,
                    color: video['color'] as Color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    video['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (video['color'] as Color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    video['subject'],
                    style: TextStyle(
                      color: video['color'] as Color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.access_time,
                    color: Colors.white54, size: 14),
                const SizedBox(width: 4),
                Text(
                  video['duration'],
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.visibility,
                    color: Colors.white54, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${video['views']} views',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 24),
            Text(
              video['description'],
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Playing: ${video['title']}'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F1A54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  'Play Now',
                  style: TextStyle(
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
