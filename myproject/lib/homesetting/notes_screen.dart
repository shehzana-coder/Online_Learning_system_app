import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final List<Map<String, dynamic>> _allNotes = [
    {
      "title": "Algebra Basics",
      "subject": "Mathematics",
      "size": "1.2 MB",
      "icon": Icons.calculate,
      "color": Colors.blue,
      "description": "Introduction to algebraic expressions, equations, and inequalities.",
    },
    {
      "title": "Photosynthesis Notes",
      "subject": "Biology",
      "size": "800 KB",
      "icon": Icons.eco,
      "color": Colors.green,
      "description": "Detailed notes on the process of photosynthesis in plants.",
    },
    {
      "title": "Newton's Laws",
      "subject": "Physics",
      "size": "2.1 MB",
      "icon": Icons.science,
      "color": Colors.orange,
      "description": "Comprehensive notes on Newton's three laws of motion.",
    },
    {
      "title": "Organic Chemistry",
      "subject": "Chemistry",
      "size": "1.5 MB",
      "icon": Icons.biotech,
      "color": Colors.purple,
      "description": "Notes covering organic compounds, reactions, and mechanisms.",
    },
    {
      "title": "World War II Summary",
      "subject": "History",
      "size": "1.8 MB",
      "icon": Icons.history_edu,
      "color": Colors.brown,
      "description": "A comprehensive summary of World War II events and outcomes.",
    },
    {
      "title": "Trigonometry",
      "subject": "Mathematics",
      "size": "950 KB",
      "icon": Icons.calculate,
      "color": Colors.blue,
      "description": "Trigonometric functions, identities, and applications.",
    },
    {
      "title": "Cell Biology",
      "subject": "Biology",
      "size": "1.1 MB",
      "icon": Icons.eco,
      "color": Colors.green,
      "description": "Structure and function of cells, organelles, and cell division.",
    },
    {
      "title": "Thermodynamics",
      "subject": "Physics",
      "size": "1.7 MB",
      "icon": Icons.science,
      "color": Colors.orange,
      "description": "Laws of thermodynamics, heat transfer, and entropy.",
    },
  ];

  List<Map<String, dynamic>> _filteredNotes = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedSubject = 'All';

  final List<String> _subjects = [
    'All',
    'Mathematics',
    'Biology',
    'Physics',
    'Chemistry',
    'History',
  ];

  @override
  void initState() {
    super.initState();
    _filteredNotes = _allNotes;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterNotes(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredNotes = _allNotes.where((note) {
        final titleMatch =
            note['title'].toString().toLowerCase().contains(lowerQuery);
        final subjectMatch =
            note['subject'].toString().toLowerCase().contains(lowerQuery);
        final subjectFilter =
            _selectedSubject == 'All' || note['subject'] == _selectedSubject;
        return (titleMatch || subjectMatch) && subjectFilter;
      }).toList();
    });
  }

  void _filterBySubject(String subject) {
    setState(() {
      _selectedSubject = subject;
      _filterNotes(_searchController.text);
    });
  }

  void _shareNote(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.share, color: Color(0xFF0F1A54)),
            SizedBox(width: 8),
            Text('Share Note'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share "${note['title']}" with others:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                '📖 Study Notes: ${note['title']} (${note['subject']}) — Available on TeachUp!\nhttps://teachup.app/notes',
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
                text: '📖 Study Notes: ${note['title']} (${note['subject']}) — Available on TeachUp!\nhttps://teachup.app/notes',
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

  void _openNote(Map<String, dynamic> note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: (note['color'] as Color).withOpacity(0.2),
                  child: Icon(note['icon'] as IconData,
                      color: note['color'] as Color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note['title'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        note['subject'],
                        style: TextStyle(
                          color: note['color'] as Color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              note['description'],
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.storage, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(note['size'],
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Downloading ${note['title']}...'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F1A54),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _shareNote(note);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F1A54),
                      side: const BorderSide(color: Color(0xFF0F1A54)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A54),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1A54),
        foregroundColor: Colors.white,
        title: const Text('Study Notes'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _filterNotes,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search notes...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white60),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white60),
                        onPressed: () {
                          _searchController.clear();
                          _filterNotes('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Subject filter chips
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final subject = _subjects[index];
                final isSelected = _selectedSubject == subject;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(subject),
                    selected: isSelected,
                    onSelected: (_) => _filterBySubject(subject),
                    backgroundColor: Colors.white10,
                    selectedColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF0F1A54)
                          : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    checkmarkColor: const Color(0xFF0F1A54),
                    side: BorderSide(
                      color: isSelected ? Colors.white : Colors.white24,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Notes list
          Expanded(
            child: _filteredNotes.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.note_alt_outlined,
                            color: Colors.white54, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'No notes found.',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filteredNotes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final note = _filteredNotes[index];
                      return Card(
                        elevation: 2,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor:
                                (note['color'] as Color).withOpacity(0.15),
                            child: Icon(
                              note['icon'] as IconData,
                              color: note['color'] as Color,
                            ),
                          ),
                          title: Text(
                            note['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F1A54),
                            ),
                          ),
                          subtitle: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (note['color'] as Color)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  note['subject'],
                                  style: TextStyle(
                                    color: note['color'] as Color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                note['size'],
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.download,
                                    color: Color(0xFF0F1A54), size: 20),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Downloading ${note['title']}...'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                              ),
                              const Icon(Icons.chevron_right,
                                  color: Colors.grey),
                            ],
                          ),
                          onTap: () => _openNote(note),
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
