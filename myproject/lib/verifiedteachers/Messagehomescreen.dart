import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'chatscreen.dart'; // Your new ChatScreen
import 'homescreen.dart';
import 'teachersprofile.dart';
import 'homeschedule.dart';

class MessagesScreen extends StatefulWidget {
  final String? tutorId;

  const MessagesScreen({Key? key, this.tutorId}) : super(key: key);

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _profilePhotoUrl; // Add this for profile picture

  // Cache for profile images to avoid repeated Firebase Storage calls
  final Map<String, String?> _profileImageCache = {};

  // Real-time listeners
  StreamSubscription<QuerySnapshot>? _conversationsListener;
  final Map<String, StreamSubscription<QuerySnapshot>> _messageListeners = {};

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setupRealTimeListeners();
    _fetchProfilePhoto(); // Add this to fetch profile photo
  }

  // Add this method to fetch profile photo
  Future<void> _fetchProfilePhoto() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final querySnapshot = await _firestore
            .collection('teachers')
            .where('authUid', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          setState(() {
            _profilePhotoUrl =
                data['profilePhoto']?['profilePhotoUrl']?.toString();
          });
        }
      } catch (e) {
        print('Error fetching profile photo: $e');
        // No snackbar to avoid cluttering UI; fallback to avatar
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _conversationsListener?.cancel();
    // Cancel all message listeners
    for (var listener in _messageListeners.values) {
      listener.cancel();
    }
    _messageListeners.clear();
    super.dispose();
  }

  void _setupRealTimeListeners() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _errorMessage = 'Please sign in to view messages';
        _isLoading = false;
      });
      return;
    }

    try {
      // Listen to conversations collection for real-time updates
      _conversationsListener = _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          _handleConversationsUpdate(snapshot);
        },
        onError: (error) {
          print('Error listening to conversations: $error');
          setState(() {
            _errorMessage = 'Error loading conversations: $error';
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      print('Error setting up listeners: $e');
      setState(() {
        _errorMessage = 'Error setting up real-time updates: $e';
        _isLoading = false;
      });
    }
  }

  void _handleConversationsUpdate(QuerySnapshot snapshot) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    List<Map<String, dynamic>> conversations = [];

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<String> participants = List<String>.from(data['participants'] ?? []);
      String otherParticipantId =
          participants.firstWhere((id) => id != userId, orElse: () => '');

      if (otherParticipantId.isEmpty) continue;

      // Get participant details from the chat document first
      Map<String, dynamic> participantDetails =
          data['participantDetails'] ?? {};
      Map<String, dynamic> otherUserDetails =
          participantDetails[otherParticipantId] ?? {};

      String tutorName = otherUserDetails['name'] ?? 'Unknown User';
      String profileImageUrl = otherUserDetails['photoURL'] ?? '';

      // Enhanced profile image fetching with multiple sources
      if (profileImageUrl.isEmpty) {
        profileImageUrl =
            await _getProfileImageFromMultipleSources(otherParticipantId);
      }

      // If details are missing, try to fetch from teachers collection
      if (tutorName == 'Unknown User') {
        try {
          DocumentSnapshot tutorDoc = await _firestore
              .collection('teachers')
              .doc(otherParticipantId)
              .get();

          if (tutorDoc.exists) {
            Map<String, dynamic> tutorData =
                tutorDoc.data() as Map<String, dynamic>;
            tutorName =
                '${tutorData['about']?['firstName'] ?? 'Unknown'} ${tutorData['about']?['lastName'] ?? 'User'}';
          }
        } catch (e) {
          print('Error fetching tutor details: $e');
        }
      }

      // Get unread count - this is the key for notifications
      int unreadCount =
          (data['unreadCount'] as Map<String, dynamic>?)?[userId] ?? 0;

      conversations.add({
        'chatId': doc.id,
        'tutorId': otherParticipantId,
        'tutorName': tutorName,
        'lastMessage': data['lastMessage'] ?? 'No messages yet',
        'lastMessageTime': data['lastMessageTime'] != null
            ? (data['lastMessageTime'] as Timestamp).toDate()
            : null,
        'unreadCount': unreadCount,
        'profileImage': profileImageUrl,
      });

      // Set up individual message listener for this chat to update unread counts
      _setupMessageListener(doc.id, otherParticipantId, userId);
    }

    // Handle new conversation from tutorId if provided
    if (widget.tutorId != null) {
      bool conversationExists =
          conversations.any((conv) => conv['tutorId'] == widget.tutorId);

      if (!conversationExists) {
        try {
          DocumentSnapshot tutorDoc =
              await _firestore.collection('teachers').doc(widget.tutorId).get();

          if (tutorDoc.exists) {
            Map<String, dynamic> tutorData =
                tutorDoc.data() as Map<String, dynamic>;
            String tutorName =
                '${tutorData['about']?['firstName'] ?? 'Unknown'} ${tutorData['about']?['lastName'] ?? 'User'}';
            String profileImageUrl =
                await _getProfileImageFromMultipleSources(widget.tutorId ?? '');

            conversations.insert(0, {
              'chatId': null,
              'tutorId': widget.tutorId,
              'tutorName': tutorName,
              'lastMessage': 'Start a new conversation',
              'lastMessageTime': null,
              'unreadCount': 0,
              'profileImage': profileImageUrl,
            });
          }
        } catch (e) {
          print('Error fetching tutor for new conversation: $e');
        }
      }
    }

    setState(() {
      _conversations = conversations;
      _isLoading = false;
      _errorMessage = null;
    });
  }

  void _setupMessageListener(
      String chatId, String otherParticipantId, String userId) {
    // Cancel existing listener if it exists
    _messageListeners[chatId]?.cancel();

    // Listen to new messages in this specific chat
    _messageListeners[chatId] = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId',
            isEqualTo:
                otherParticipantId) // Only listen to messages from the other participant
        .orderBy('timestamp', descending: true)
        .limit(1) // Only get the latest message
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.docs.isNotEmpty) {
          var latestMessage = snapshot.docs.first;
          var messageData = latestMessage.data();

          // Check if this message is unread by current user
          List<String> readBy = List<String>.from(messageData['readBy'] ?? []);
          if (!readBy.contains(userId)) {
            // Update unread count in the chat document
            _updateUnreadCount(chatId, userId, increment: true);
          }
        }
      },
      onError: (error) {
        print('Error listening to messages for chat $chatId: $error');
      },
    );
  }

  Future<void> _updateUnreadCount(String chatId, String userId,
      {bool increment = true}) async {
    try {
      DocumentReference chatRef = _firestore.collection('chats').doc(chatId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot chatDoc = await transaction.get(chatRef);

        if (chatDoc.exists) {
          Map<String, dynamic> data = chatDoc.data() as Map<String, dynamic>;
          Map<String, dynamic> unreadCount =
              Map<String, dynamic>.from(data['unreadCount'] ?? {});

          int currentCount = unreadCount[userId] ?? 0;
          if (increment) {
            unreadCount[userId] = currentCount + 1;
          } else {
            unreadCount[userId] = 0; // Reset when messages are read
          }

          transaction.update(chatRef, {'unreadCount': unreadCount});
        }
      });
    } catch (e) {
      print('Error updating unread count: $e');
    }
  }

  // Method to mark messages as read when user opens a chat
  Future<void> _markMessagesAsRead(String chatId, String userId) async {
    try {
      // Reset unread count for this user
      await _updateUnreadCount(chatId, userId, increment: false);

      // Mark all unread messages as read
      QuerySnapshot unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('readBy', whereNotIn: [
        [userId] // Messages where readBy array doesn't contain userId
      ]).get();

      WriteBatch batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        List<String> readBy = List<String>.from(
            (doc.data() as Map<String, dynamic>)['readBy'] ?? []);
        if (!readBy.contains(userId)) {
          readBy.add(userId);
          batch.update(doc.reference, {'readBy': readBy});
        }
      }

      if (unreadMessages.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> _fetchConversations() async {
    // This method is now handled by real-time listeners
    // Keeping it for backward compatibility but it's not actively used
  }

  // Enhanced method to get profile images from multiple sources with caching
  Future<String> _getProfileImageFromMultipleSources(String userId) async {
    // Check cache first
    if (_profileImageCache.containsKey(userId)) {
      return _profileImageCache[userId] ?? '';
    }

    String profileImageUrl = '';

    try {
      // Method 1: Check user's document for photoURL
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        profileImageUrl =
            userData['photoURL'] ?? userData['profileImageUrl'] ?? '';
      }

      // Method 2: If not found, check teachers collection
      if (profileImageUrl.isEmpty) {
        DocumentSnapshot teacherDoc =
            await _firestore.collection('teachers').doc(userId).get();

        if (teacherDoc.exists) {
          Map<String, dynamic> teacherData =
              teacherDoc.data() as Map<String, dynamic>;
          profileImageUrl = teacherData['photoURL'] ??
              teacherData['profileImageUrl'] ??
              teacherData['about']?['photoURL'] ??
              '';
        }
      }

      // Method 3: If still not found, check Firebase Storage
      if (profileImageUrl.isEmpty) {
        profileImageUrl = await _getProfileImageFromStorage(userId) ?? '';
      }

      // Method 4: If still not found, check if user has Firebase Auth photoURL
      if (profileImageUrl.isEmpty && userId == _auth.currentUser?.uid) {
        profileImageUrl = _auth.currentUser?.photoURL ?? '';
      }
    } catch (e) {
      print('Error fetching profile image for $userId: $e');
    }

    // Cache the result (even if empty) to avoid repeated calls
    _profileImageCache[userId] =
        profileImageUrl.isEmpty ? null : profileImageUrl;

    return profileImageUrl;
  }

  // Enhanced Firebase Storage method with better error handling
  Future<String?> _getProfileImageFromStorage(String userId) async {
    try {
      // Try different possible paths and extensions
      final possiblePaths = [
        'profile_pictures/$userId.jpg',
        'profile_pictures/$userId.jpeg',
        'profile_pictures/$userId.png',
        'profile_pictures/$userId.webp',
        'profileImages/$userId.jpg',
        'profileImages/$userId.jpeg',
        'profileImages/$userId.png',
        'images/profile/$userId.jpg',
        'images/profile/$userId.jpeg',
        'images/profile/$userId.png',
        'users/$userId/profile.jpg',
        'users/$userId/profile.jpeg',
        'users/$userId/profile.png',
      ];

      for (String path in possiblePaths) {
        try {
          String downloadUrl =
              await FirebaseStorage.instance.ref(path).getDownloadURL();
          return downloadUrl;
        } catch (e) {
          continue;
        }
      }

      return null;
    } catch (e) {
      print('Error getting profile image from storage for $userId: $e');
      return null;
    }
  }

  Future<void> _migrateLegacyConversation(
      String conversationId, String tutorId, String tutorName) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Check if chat already exists in new structure
      String chatId = ChatHelper.getChatId(userId, tutorId);
      DocumentSnapshot chatDoc =
          await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        // Migrate conversation to new chat structure
        DocumentSnapshot oldConversation = await _firestore
            .collection('conversations')
            .doc(conversationId)
            .get();

        if (oldConversation.exists) {
          Map<String, dynamic> oldData =
              oldConversation.data() as Map<String, dynamic>;

          // Create new chat document
          await _firestore.collection('chats').doc(chatId).set({
            'participants': [userId, tutorId],
            'participantDetails': {
              userId: {
                'name': _auth.currentUser?.displayName ?? 'User',
                'photoURL': await _getProfileImageFromMultipleSources(userId),
              },
              tutorId: {
                'name': tutorName,
                'photoURL': await _getProfileImageFromMultipleSources(tutorId),
              }
            },
            'lastMessage': oldData['lastMessage'] ?? '',
            'lastMessageTime':
                oldData['lastMessageTime'] ?? FieldValue.serverTimestamp(),
            'lastMessageSender': oldData['lastMessageSender'] ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'unreadCount': {
              userId: oldData['unreadCount']?[userId] ?? 0,
              tutorId: oldData['unreadCount']?[tutorId] ?? 0,
            }
          });

          // Migrate messages if they exist
          QuerySnapshot oldMessages = await _firestore
              .collection('conversations')
              .doc(conversationId)
              .collection('messages')
              .orderBy('timestamp')
              .get();

          WriteBatch batch = _firestore.batch();
          for (var messageDoc in oldMessages.docs) {
            Map<String, dynamic> messageData =
                messageDoc.data() as Map<String, dynamic>;
            DocumentReference newMessageRef = _firestore
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .doc();

            batch.set(newMessageRef, {
              'text': messageData['text'] ?? '',
              'senderId': messageData['senderId'] ?? '',
              'timestamp':
                  messageData['timestamp'] ?? FieldValue.serverTimestamp(),
              'type': messageData['type'] ?? 'text',
              'readBy': [messageData['senderId'] ?? ''],
              'editedAt': null,
              'replyTo': null,
            });
          }

          await batch.commit();
        }
      }
    } catch (e) {
      print('Error migrating conversation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TutorScreen()),
            );
          },
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              backgroundImage:
                  _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                      ? NetworkImage(_profilePhotoUrl!)
                      : null,
              child: _profilePhotoUrl == null || _profilePhotoUrl!.isEmpty
                  ? Icon(
                      Icons.person,
                      color: Colors.grey[600],
                      size: 24,
                    )
                  : null,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color.fromARGB(255, 255, 144, 187),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Archived'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // All messages tab
                    _conversations.isEmpty
                        ? const Center(child: Text('No conversations yet'))
                        : ListView.builder(
                            itemCount: _conversations.length,
                            itemBuilder: (context, index) {
                              final conv = _conversations[index];
                              return _buildMessageTile(
                                name: conv['tutorName'],
                                message: conv['lastMessage'],
                                time: conv['lastMessageTime'] != null
                                    ? _formatTime(conv['lastMessageTime'])
                                    : '',
                                unreadCount: conv['unreadCount'],
                                profileImageUrl: conv['profileImage'],
                                userId: conv['tutorId'],
                                onTap: () async {
                                  // Mark messages as read when opening chat
                                  if (conv['chatId'] != null) {
                                    await _markMessagesAsRead(
                                        conv['chatId'], _auth.currentUser!.uid);
                                  }

                                  // Handle legacy conversation migration
                                  if (conv['chatId'] == null &&
                                      widget.tutorId != null) {
                                    // This is a new conversation, no migration needed
                                  } else if (conv['chatId'] != null &&
                                      conv['chatId'].contains('_')) {
                                    // This is already in new format, proceed normally
                                  } else if (conv['chatId'] != null) {
                                    // This might be a legacy conversation ID, attempt migration
                                    await _migrateLegacyConversation(
                                        conv['chatId'],
                                        conv['tutorId'],
                                        conv['tutorName']);
                                  }

                                  // Navigate to new ChatScreen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        recipientId: conv['tutorId'],
                                        recipientName: conv['tutorName'],
                                        recipientPhotoURL:
                                            conv['profileImage']?.isNotEmpty ==
                                                    true
                                                ? conv['profileImage']
                                                : null,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                    // Archived messages tab
                    const Center(
                      child: Text('No archived messages'),
                    ),
                  ],
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Messages tab is selected
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 255, 144, 187),
        unselectedItemColor: Colors.black,
        onTap: (index) {
          _navigateToScreen(context, index);
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.mail_outline),
            label: 'Messages',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Setting',
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(BuildContext context, int index) {
    if (index == 1) return; // No navigation if already on Messages

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TutorScreen()),
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
          MaterialPageRoute(builder: (context) => const TeacherProfileScreen()),
        );
        break;
    }
  }

  Widget _buildMessageTile({
    required String name,
    required String message,
    required String time,
    required int unreadCount,
    required String? profileImageUrl,
    required String userId,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: _buildProfileImage(profileImageUrl, name, userId),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
          fontSize: 16,
          color: unreadCount > 0 ? Colors.black : Colors.black87,
        ),
      ),
      subtitle: Text(
        message,
        style: TextStyle(
          color: unreadCount > 0 ? Colors.black54 : Colors.grey,
          fontSize: 14,
          fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: TextStyle(
              color: unreadCount > 0
                  ? const Color.fromARGB(255, 255, 144, 187)
                  : Colors.grey[400],
              fontSize: 12,
              fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color.fromARGB(255, 255, 144, 187),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildProfileImage(
      String? profileImageUrl, String name, String userId) {
    // If we have a valid URL, use NetworkImage
    if (profileImageUrl != null &&
        profileImageUrl.isNotEmpty &&
        profileImageUrl.startsWith('http')) {
      return CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(profileImageUrl),
        onBackgroundImageError: (exception, stackTrace) {
          print('Error loading network image for $userId: $exception');
        },
        child: null,
      );
    }

    // If it's an asset path, use AssetImage
    if (profileImageUrl != null &&
        profileImageUrl.isNotEmpty &&
        profileImageUrl.startsWith('assets/')) {
      return CircleAvatar(
        radius: 25,
        backgroundImage: AssetImage(profileImageUrl),
        onBackgroundImageError: (exception, stackTrace) {
          print('Error loading asset image: $exception');
        },
      );
    }

    // Fallback: Show first letter of name with colored background
    return CircleAvatar(
      radius: 25,
      backgroundColor: _generateColorFromName(name),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  // Generate a consistent color based on the name
  Color _generateColorFromName(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
    ];

    int hash = name.hashCode;
    return colors[hash.abs() % colors.length];
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);
    if (messageDate == today) {
      return DateFormat('h:mm a').format(time);
    } else {
      return DateFormat('MMM d').format(time);
    }
  }
}

class ChatHelper {
  static String getChatId(String userId1, String userId2) {
    final users = [userId1, userId2]..sort();
    return '${users[0]}_${users[1]}';
  }
}
