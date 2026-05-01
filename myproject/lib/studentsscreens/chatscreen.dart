import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String? recipientPhotoURL;

  const ChatScreen({
    Key? key,
    required this.recipientId,
    required this.recipientName,
    this.recipientPhotoURL,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  late String chatId;
  late String currentUserId;
  bool _isInitialized = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateUserStatus(false);
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _updateUserStatus(true);
    } else {
      _updateUserStatus(false);
    }
  }

  Future<void> _initializeChat() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    currentUserId = currentUser.uid;
    chatId = ChatHelper.getChatId(currentUserId, widget.recipientId);

    // Initialize all necessary data
    await _ensureUserDocument();
    await _ensureRecipientDocument();
    await _ensureChatDocument();
    await _ensureUserChatDocument();
    await _updateUserStatus(true);

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _ensureUserDocument() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final userDoc =
        await _firestore.collection('users').doc(currentUserId).get();

    if (!userDoc.exists) {
      await _firestore.collection('users').doc(currentUserId).set({
        'name': currentUser.displayName ?? 'Unknown User',
        'email': currentUser.email ?? '',
        'photoURL': currentUser.photoURL ?? '',
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'fcmToken': '',
      });
    }
  }

  Future<void> _ensureRecipientDocument() async {
    final recipientDoc =
        await _firestore.collection('users').doc(widget.recipientId).get();

    if (!recipientDoc.exists) {
      await _firestore.collection('users').doc(widget.recipientId).set({
        'name': widget.recipientName,
        'email': '',
        'photoURL': widget.recipientPhotoURL ?? '',
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'fcmToken': '',
      });
    }
  }

  Future<void> _ensureChatDocument() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final chatDoc = await _firestore.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [currentUserId, widget.recipientId],
        'participantDetails': {
          currentUserId: {
            'name': currentUser.displayName ?? 'Unknown User',
            'photoURL': currentUser.photoURL ?? '',
          },
          widget.recipientId: {
            'name': widget.recipientName,
            'photoURL': widget.recipientPhotoURL ?? '',
          }
        },
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': '',
        'createdAt': FieldValue.serverTimestamp(),
        'unreadCount': {
          currentUserId: 0,
          widget.recipientId: 0,
        }
      });
    } else {
      await _firestore.collection('chats').doc(chatId).update({
        'participantDetails.${currentUserId}': {
          'name': currentUser.displayName ?? 'Unknown User',
          'photoURL': currentUser.photoURL ?? '',
        }
      });
    }
  }

  Future<void> _ensureUserChatDocument() async {
    final userChatDoc =
        await _firestore.collection('userChats').doc(currentUserId).get();

    if (!userChatDoc.exists) {
      await _firestore.collection('userChats').doc(currentUserId).set({
        'chats': {
          chatId: {
            'lastAccessed': FieldValue.serverTimestamp(),
            'isMuted': false,
            'isPinned': false,
          }
        }
      });
    } else {
      await _firestore.collection('userChats').doc(currentUserId).update({
        'chats.$chatId.lastAccessed': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _updateUserStatus(bool isOnline) async {
    if (currentUserId.isNotEmpty) {
      await _firestore.collection('users').doc(currentUserId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_msgController.text.trim().isEmpty || !_isInitialized) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final msg = _msgController.text.trim();
    _msgController.clear();

    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'text': msg,
        'senderId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
        'readBy': [currentUserId],
        'editedAt': null,
        'replyTo': null,
      });

      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': msg,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': currentUserId,
        'unreadCount.${widget.recipientId}': FieldValue.increment(1),
      });

      await _firestore.collection('userChats').doc(currentUserId).update({
        'chats.$chatId.lastAccessed': FieldValue.serverTimestamp(),
      });

      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  Future<void> _pickAndSendFile() async {
    if (!_isInitialized) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isUploading = true;
        });

        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileSize = result.files.single.size;
        final fileExtension = result.files.single.extension ?? '';

        // Upload file to Firebase Storage
        final storageRef = _storage
            .ref()
            .child('chat_files')
            .child(chatId)
            .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        String messageType = 'file';
        if (['jpg', 'jpeg', 'png', 'gif', 'webp']
            .contains(fileExtension.toLowerCase())) {
          messageType = 'image';
        } else if (['mp4', 'mov', 'avi', 'mkv']
            .contains(fileExtension.toLowerCase())) {
          messageType = 'video';
        } else if (['mp3', 'wav', 'aac', 'm4a']
            .contains(fileExtension.toLowerCase())) {
          messageType = 'audio';
        }

        // Send file message
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add({
          'text': fileName,
          'senderId': currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
          'type': messageType,
          'fileUrl': downloadUrl,
          'fileName': fileName,
          'fileSize': fileSize,
          'fileExtension': fileExtension,
          'readBy': [currentUserId],
          'editedAt': null,
          'replyTo': null,
        });

        await _firestore.collection('chats').doc(chatId).update({
          'lastMessage': '📎 $fileName',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSender': currentUserId,
          'unreadCount.${widget.recipientId}': FieldValue.increment(1),
        });

        _scrollToBottom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send file: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (!_isInitialized) return;

    try {
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .where('readBy', whereNotIn: [
        [currentUserId]
      ]).get();

      WriteBatch batch = _firestore.batch();

      for (var doc in unreadMessages.docs) {
        List<String> readBy = List<String>.from(doc.data()['readBy'] ?? []);
        if (!readBy.contains(currentUserId)) {
          readBy.add(currentUserId);
          batch.update(doc.reference, {'readBy': readBy});
        }
      }

      batch.update(_firestore.collection('chats').doc(chatId), {
        'unreadCount.$currentUserId': 0,
      });

      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            widget.recipientName,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Color.fromARGB(255, 255, 144, 187),
          foregroundColor: const Color.fromARGB(255, 0, 0, 0),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.recipientName,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(widget.recipientId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final isOnline = userData['isOnline'] ?? false;
                  final lastSeen = userData['lastSeen'] as Timestamp?;

                  return Text(
                    isOnline ? 'Online' : _formatLastSeen(lastSeen),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color.fromARGB(179, 0, 0, 0),
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        backgroundColor: Color.fromARGB(255, 255, 144, 187),
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Something went wrong',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _markMessagesAsRead();
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msgData =
                        messages[index].data() as Map<String, dynamic>;
                    final isMe = msgData['senderId'] == currentUserId;
                    final timestamp = msgData['timestamp'] as Timestamp?;
                    final readBy = List<String>.from(msgData['readBy'] ?? []);

                    return MessageBubble(
                      message: msgData['text'] ?? '',
                      isMe: isMe,
                      timestamp: timestamp,
                      isRead: readBy.contains(widget.recipientId),
                      showReadStatus: isMe,
                      messageType: msgData['type'] ?? 'text',
                      fileUrl: msgData['fileUrl'],
                      fileName: msgData['fileName'],
                      fileSize: msgData['fileSize'],
                      fileExtension: msgData['fileExtension'],
                    );
                  },
                );
              },
            ),
          ),

          // Upload indicator
          if (_isUploading)
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: const [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Uploading file...',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

          // Message input area
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 6,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: Row(
              children: [
                // File picker button
                IconButton(
                  onPressed: _isUploading ? null : _pickAndSendFile,
                  icon: const Icon(
                    Icons.attach_file,
                    color: Colors.grey,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  backgroundColor: Color.fromARGB(255, 255, 144, 187),
                  child: const Icon(
                    Icons.send,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(Timestamp? timestamp) {
    if (timestamp == null) return 'Last seen recently';

    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Last seen just now';
    } else if (difference.inHours < 1) {
      return 'Last seen ${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return 'Last seen ${difference.inHours}h ago';
    } else {
      return 'Last seen ${difference.inDays}d ago';
    }
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final Timestamp? timestamp;
  final bool isRead;
  final bool showReadStatus;
  final String messageType;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileExtension;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.timestamp,
    this.isRead = false,
    this.showReadStatus = false,
    this.messageType = 'text',
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileExtension,
  }) : super(key: key);

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Widget _buildFileMessage() {
    IconData fileIcon;
    Color iconColor;

    switch (messageType) {
      case 'image':
        fileIcon = Icons.image;
        iconColor = Colors.green;
        break;
      case 'video':
        fileIcon = Icons.videocam;
        iconColor = Colors.red;
        break;
      case 'audio':
        fileIcon = Icons.audiotrack;
        iconColor = Colors.orange;
        break;
      default:
        fileIcon = Icons.insert_drive_file;
        iconColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(fileIcon, color: iconColor, size: 24),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fileName ?? 'File',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (fileSize != null)
                  Text(
                    _formatFileSize(fileSize),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.pink[200] : Colors.grey[300],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (messageType == 'text')
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                ),
              )
            else
              _buildFileMessage(),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (timestamp != null)
                  Text(
                    _formatTime(timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                if (showReadStatus) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 16,
                    color: isRead ? Colors.blue : Colors.grey[600],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class to create or get chat ID between two users
class ChatHelper {
  static String getChatId(String userId1, String userId2) {
    final users = [userId1, userId2]..sort();
    return '${users[0]}_${users[1]}';
  }

  @deprecated
  static Future<void> createChatIfNotExists(
      String chatId, String userId1, String userId2) async {
    // This functionality is now built into the ChatScreen
  }
}

// Usage example widget
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'Please log in first',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 255, 144, 187),
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser.uid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Something went wrong',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data?.docs ?? [];

          if (chats.isEmpty) {
            return const Center(
              child: Text(
                'No chats yet. Start a conversation!',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatData = chats[index].data() as Map<String, dynamic>;
              final participants =
                  List<String>.from(chatData['participants'] ?? []);
              final otherUserId =
                  participants.firstWhere((id) => id != currentUser.uid);
              final participantDetails =
                  chatData['participantDetails'] as Map<String, dynamic>? ?? {};
              final otherUserDetails =
                  participantDetails[otherUserId] as Map<String, dynamic>? ??
                      {};

              final unreadCount = (chatData['unreadCount']
                      as Map<String, dynamic>?)?[currentUser.uid] ??
                  0;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      otherUserDetails['photoURL']?.isNotEmpty == true
                          ? NetworkImage(otherUserDetails['photoURL'])
                          : null,
                  child: otherUserDetails['photoURL']?.isEmpty != false
                      ? Text(
                          otherUserDetails['name']
                                  ?.substring(0, 1)
                                  .toUpperCase() ??
                              '?',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  otherUserDetails['name'] ?? 'Unknown User',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  chatData['lastMessage'] ?? 'No messages yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                trailing: unreadCount > 0
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        recipientId: otherUserId,
                        recipientName:
                            otherUserDetails['name'] ?? 'Unknown User',
                        recipientPhotoURL: otherUserDetails['photoURL'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
