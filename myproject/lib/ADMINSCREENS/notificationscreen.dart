import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  String _searchQuery = '';
  String _selectedType = 'All';
  late AnimationController _refreshController;

  final List<String> _types = [
    'All',
    'Teacher Signups',
    'Session Bookings',
    'Teacher Registrations',
    'Teacher Verifications',
    'Teacher Deletions'
  ];

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fetchNotifications();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    try {
      _refreshController.forward();
      setState(() {
        _isLoading = true;
      });

      // Fetch existing notifications
      Query<Map<String, dynamic>> notificationsQuery =
          _firestore.collection('notifications');
      if (_selectedType != 'All' &&
          _selectedType != 'Teacher Registrations' &&
          _selectedType != 'Teacher Verifications' &&
          _selectedType != 'Teacher Deletions') {
        notificationsQuery = notificationsQuery.where('type',
            isEqualTo: {
                  'Teacher Signups': 'teacher_signup',
                  'Session Bookings': 'session_booking',
                  'Teacher Verifications': 'teacher_verification',
                  'Teacher Deletions': 'teacher_deletion',
                }[_selectedType] ??
                '');
      }

      final notificationsSnapshot = await notificationsQuery.get();

      // Fetch teacher registrations from admin_logs
      Query<Map<String, dynamic>> adminLogsQuery = _firestore
          .collection('admin_logs')
          .where('action', isEqualTo: 'teacher_registration');
      if (_selectedType != 'All' &&
          _selectedType != 'Teacher Signups' &&
          _selectedType != 'Session Bookings' &&
          _selectedType != 'Teacher Verifications' &&
          _selectedType != 'Teacher Deletions') {
        adminLogsQuery =
            adminLogsQuery.where('action', isEqualTo: 'teacher_registration');
      }

      final adminLogsSnapshot = await adminLogsQuery.get();

      // Combine both data sources
      List<Map<String, dynamic>> combinedNotifications = [];

      // Add existing notifications
      combinedNotifications.addAll(notificationsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': data['type'] ?? 'unknown',
          'userId': data['userId'] ?? '',
          'userName': data['userName'] ?? 'Unknown',
          'details': data['details'] ?? '',
          'timestamp': data['timestamp'] ?? Timestamp.now(),
          'isRead': data['isRead'] ?? false,
          'sessionId': data['sessionId'] ?? null,
          'source': 'notifications',
        };
      }));

      // Add teacher registrations from admin_logs
      combinedNotifications.addAll(adminLogsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': 'teacher_registration',
          'userId': data['teacherId'] ?? '',
          'userName': data['teacherName'] ?? 'Unknown',
          'details': data['details'] ?? '',
          'timestamp': data['timestamp'] ?? Timestamp.now(),
          'isRead': false,
          'sessionId': null,
          'teacherEmail': data['teacherEmail'] ?? '',
          'status': data['status'] ?? 'not_verified',
          'phoneNumber': data['phoneNumber'],
          'source': 'admin_logs',
        };
      }));

      setState(() {
        _notifications = combinedNotifications;
        _notifications.sort((a, b) => (b['timestamp'] as Timestamp)
            .compareTo(a['timestamp'] as Timestamp));
        _isLoading = false;
      });

      _refreshController.reset();
    } catch (e) {
      print('Error fetching notifications: $e');
      _showSnackBar('Error loading notifications: $e', Colors.red);
      setState(() {
        _isLoading = false;
      });
      _refreshController.reset();
    }
  }

  Future<void> _deleteNotification(String notificationId, String userName,
      String type, String source) async {
    try {
      // Show confirmation dialog
      final shouldDelete = await _showDeleteConfirmation(userName, type);
      if (!shouldDelete) return;

      // Delete from appropriate collection
      if (source == 'notifications') {
        await _firestore
            .collection('notifications')
            .doc(notificationId)
            .delete();
      } else if (source == 'admin_logs') {
        await _firestore.collection('admin_logs').doc(notificationId).delete();
      }

      // Log the deletion action
      await _firestore.collection('admin_logs').add({
        'action': 'notification_deleted',
        'adminId': _auth.currentUser?.uid ?? 'unknown',
        'details': 'Admin deleted notification for $userName ($type)',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Remove from local list
      setState(() {
        _notifications.removeWhere((n) => n['id'] == notificationId);
      });

      _showSnackBar('Notification deleted successfully', Colors.green);
    } catch (e) {
      print('Error deleting notification: $e');
      _showSnackBar('Error deleting notification: $e', Colors.red);
    }
  }

  Future<bool> _showDeleteConfirmation(String userName, String type) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange[600], size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Delete Notification',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Are you sure you want to delete the $type notification for $userName? This action cannot be undone.',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Delete',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _toggleReadStatus(String notificationId, bool currentStatus,
      String userName, String type, String source) async {
    try {
      if (source == 'admin_logs') {
        return;
      }

      final newStatus = !currentStatus;
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': newStatus});

      await _firestore.collection('admin_logs').add({
        'action': 'notification_read_status_changed',
        'adminId': _auth.currentUser?.uid ?? 'unknown',
        'details':
            'Admin marked notification for $userName ($type) as ${newStatus ? 'read' : 'unread'}',
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        final index =
            _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['isRead'] = newStatus;
        }
      });

      _showSnackBar(
        'Notification marked as ${newStatus ? 'read' : 'unread'}',
        Colors.green,
      );
    } catch (e) {
      print('Error updating read status: $e');
      _showSnackBar('Error updating notification: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> generateTeacherSignupNotification({
    required String teacherId,
    required String teacherName,
    required String details,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'type': 'teacher_signup',
        'userId': teacherId,
        'userName': teacherName,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'sessionId': null,
      });

      print('Teacher signup notification generated for $teacherName');
      await _fetchNotifications();
    } catch (e) {
      print('Error generating teacher signup notification: $e');
      _showSnackBar('Error generating notification: $e', Colors.red);
    }
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    List<Map<String, dynamic>> filtered = _notifications;

    // Filter by type
    if (_selectedType != 'All') {
      final typeMap = {
        'Teacher Signups': 'teacher_signup',
        'Session Bookings': 'session_booking',
        'Teacher Registrations': 'teacher_registration',
        'Teacher Verifications': 'teacher_verification',
        'Teacher Deletions': 'teacher_deletion',
      };
      filtered = filtered.where((notification) {
        return notification['type'] == typeMap[_selectedType];
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((notification) {
        final userName = notification['userName'].toString().toLowerCase();
        final details = notification['details'].toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return userName.contains(query) || details.contains(query);
      }).toList();
    }

    return filtered;
  }

  int get _unreadCount {
    return _notifications.where((n) => !(n['isRead'] as bool)).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        title: Row(
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.grey[800],
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          RotationTransition(
            turns: _refreshController,
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _fetchNotifications,
              tooltip: 'Refresh notifications',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading notifications...',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildSearchAndFilter(),
                _buildStatsRow(),
                Expanded(
                  child: _filteredNotifications.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _fetchNotifications,
                          color: Colors.blue[600],
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _filteredNotifications.length,
                            itemBuilder: (context, index) {
                              final notification =
                                  _filteredNotifications[index];
                              return _buildNotificationCard(
                                  notification, index);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search notifications...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              style: GoogleFonts.poppins(color: Colors.grey[800]),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                prefixIcon:
                    Icon(Icons.filter_list_rounded, color: Colors.grey[500]),
              ),
              style: GoogleFonts.poppins(color: Colors.grey[800]),
              items: _types
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type, style: GoogleFonts.poppins()),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final totalCount = _notifications.length;
    final readCount = _notifications.where((n) => n['isRead'] as bool).length;
    final unreadCount = totalCount - readCount;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _buildStatChip('Total', totalCount, Colors.blue),
          const SizedBox(width: 12),
          _buildStatChip('Unread', unreadCount, Colors.orange),
          const SizedBox(width: 12),
          _buildStatChip('Read', readCount, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedType != 'All'
                ? 'Try adjusting your filters'
                : 'All caught up! Check back later.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index) {
    final timestamp = (notification['timestamp'] as Timestamp?)?.toDate();
    final formattedTime = timestamp != null
        ? DateFormat('MMM dd, yyyy • HH:mm').format(timestamp)
        : 'Unknown';
    final isRead = notification['isRead'] as bool;
    final type = {
          'teacher_signup': 'Teacher Signup',
          'session_booking': 'Session Booking',
          'teacher_registration': 'Teacher Registration',
          'teacher_verification': 'Teacher Verification',
          'teacher_deletion': 'Teacher Deletion',
        }[notification['type']] ??
        'Unknown';
    final source = notification['source'] ?? 'notifications';

    final typeColors = {
      'teacher_signup': Colors.blue,
      'session_booking': Colors.green,
      'teacher_registration': Colors.purple,
      'teacher_verification': Colors.orange,
      'teacher_deletion': Colors.red,
    };

    final typeIcons = {
      'teacher_signup': Icons.person_add_rounded,
      'session_booking': Icons.event_rounded,
      'teacher_registration': Icons.how_to_reg_rounded,
      'teacher_verification': Icons.verified_user_rounded,
      'teacher_deletion': Icons.person_remove_rounded,
    };

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Dismissible(
        key: Key(notification['id']),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.red[400],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
              const SizedBox(height: 4),
              Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          return await _showDeleteConfirmation(
            notification['userName'],
            type,
          );
        },
        onDismissed: (direction) {
          _deleteNotification(
            notification['id'],
            notification['userName'],
            type,
            source,
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isRead ? Colors.transparent : Colors.blue.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (typeColors[notification['type']] ?? Colors.grey)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    typeIcons[notification['type']] ??
                        Icons.notification_important_rounded,
                    color: typeColors[notification['type']] ?? Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              type,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          if (!isRead && source == 'notifications')
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.blue[600],
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['userName'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification['details'],
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (notification['type'] == 'teacher_registration') ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email: ${notification['teacherEmail']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Status: ${notification['status']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        formattedTime,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    if (source == 'notifications')
                      Container(
                        decoration: BoxDecoration(
                          color: (isRead ? Colors.green : Colors.orange)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(
                            isRead
                                ? Icons.mark_email_read_rounded
                                : Icons.mark_email_unread_rounded,
                            color:
                                isRead ? Colors.green[600] : Colors.orange[600],
                            size: 20,
                          ),
                          onPressed: () => _toggleReadStatus(
                            notification['id'],
                            isRead,
                            notification['userName'],
                            type,
                            source,
                          ),
                          tooltip: isRead ? 'Mark as unread' : 'Mark as read',
                        ),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_rounded,
                          color: Colors.red[600],
                          size: 20,
                        ),
                        onPressed: () => _deleteNotification(
                          notification['id'],
                          notification['userName'],
                          type,
                          source,
                        ),
                        tooltip: 'Delete notification',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
