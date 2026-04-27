import 'package:flutter/material.dart';

class VideoLecturesPage extends StatelessWidget {
  const VideoLecturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A54), // Deep blue background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Video Lectures",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Now Playing
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Now Playing",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      color: Colors.blue[900],
                      height: 180,
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Respiration - 5:55 mins",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      Icon(Icons.thumb_up, color: Colors.white),
                      Icon(Icons.thumb_down, color: Colors.white),
                      Icon(Icons.share, color: Colors.white),
                      Icon(Icons.feedback_outlined, color: Colors.white),
                      Icon(Icons.bookmark_border, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "More Lectures",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 10),

            // Video List
            Expanded(
              child: ListView(
                children: [
                  videoTile("Heart in Biology", "7:10 mins"),
                  videoTile("Digestive System", "6:30 mins"),
                  videoTile("Nervous System", "8:20 mins"),
                  videoTile("Photosynthesis", "5:00 mins"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget videoTile(String title, String duration) {
    return Card(
      color: Colors.white.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue[700],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.play_circle_fill, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(duration, style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.more_vert, color: Colors.white),
      ),
    );
  }
}
