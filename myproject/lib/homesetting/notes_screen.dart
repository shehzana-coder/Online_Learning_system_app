import 'package:flutter/material.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> notes = [
      {"title": "Algebra Basics", "subject": "Maths", "size": "1.2 MB"},
      {"title": "Photosynthesis Notes", "subject": "Biology", "size": "800 KB"},
      {"title": "Newton's Laws", "subject": "Physics", "size": "2.1 MB"},
      {"title": "Organic Chemistry", "subject": "Chemistry", "size": "1.5 MB"},
      {"title": "World War II Summary", "subject": "History", "size": "1.8 MB"},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 145, 145, 154),
        title: const Text(
          "Notes",
          style: TextStyle(color: Color.fromARGB(255, 27, 17, 82)),
        ),
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 19, 10, 69)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: notes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final note = notes[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color.fromARGB(255, 218, 219, 219),
                child: Icon(
                  Icons.description,
                  color: Color.fromARGB(255, 33, 33, 72),
                ),
              ),
              title: Text(
                note["title"] ?? "",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 27, 37, 86),
                ),
              ),
              subtitle: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "${note["subject"]}, ",
                      style: const TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: note["size"],
                      style: const TextStyle(
                        color: Color.fromARGB(255, 23, 30, 74),
                      ),
                    ),
                  ],
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Open the note PDF or detail page
              },
            ),
          );
        },
      ),
    );
  }
}
