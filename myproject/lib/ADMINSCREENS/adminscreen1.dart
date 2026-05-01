// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'studentsscreen.dart';
import 'verifiedteacherscreen.dart';
import 'notverifiedteacherscreen.dart';
import 'sessionscreen.dart';
import 'analyticalscreen.dart';
import 'settingscreen.dart';
import 'coursescreen.dart';
import 'dart:async';
import 'notificationscreen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:myproject/Teachersscreen/teachersignin.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedPage = 'Dashboard';
  bool _isLoading = true;
  Map<String, int> _stats = {};
  List<Map<String, dynamic>> _recentActivities = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchDashboardData();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  Future<void> _fetchDashboardData() async {
    try {
      setState(() => _isLoading = true);

      final futures = await Future.wait([
        _firestore.collection('students').get(),
        _firestore.collection('courses').get(),
        _firestore.collection('teachers').get(),
        _firestore.collection('teachers_not_verified').get(),
        _firestore.collection('sessions').get(),
        _firestore
            .collection('sessions')
            .where('status', isEqualTo: 'active')
            .get(),
        _firestore
            .collection('students')
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime.now().subtract(const Duration(days: 7)),
                ))
            .get(),
        _firestore
            .collection('teachers_not_verified')
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime.now().subtract(const Duration(days: 7)),
                ))
            .get(),
        _firestore
            .collection('admin_logs')
            .orderBy('timestamp', descending: true)
            .limit(5)
            .get(),
      ]);

      if (mounted) {
        setState(() {
          _stats = {
            'totalStudents': futures[0].size,
            'totalCourses': futures[1].size,
            'totalTeachers': futures[2].size + futures[3].size,
            'verifiedTeachers': futures[2].size,
            'notVerifiedTeachers': futures[3].size,
            'activeSessions': futures[5].size,
            'totalSessions': futures[4].size,
            'newRegistrations': futures[6].size + futures[7].size,
            'newStudents': futures[6].size,
            'newTeachers': futures[7].size,
            'pendingApprovals': futures[3].size,
          };

          _recentActivities = futures[8].docs.map((doc) {
            final data = doc.data();
            return {
              'type': data['action'] ?? 'Unknown',
              'message': data['details'] ?? 'No details',
              'time': _formatTimestamp(data['timestamp']),
              'icon': _getActivityIcon(data['action'] ?? 'Unknown'),
              'color': _getActivityColor(data['action'] ?? 'Unknown'),
            };
          }).toList();

          _isLoading = false;
        });
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown time';
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    }
    return '${difference.inDays} days ago';
  }

  IconData _getActivityIcon(String action) {
    switch (action) {
      case 'teacher_profile_completed':
        return Icons.person_add;
      case 'new_student':
        return Icons.school;
      case 'session_completed':
        return Icons.check_circle;
      case 'verification_approved':
        return Icons.verified;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String action) {
    switch (action) {
      case 'teacher_profile_completed':
        return Colors.orange[700]!;
      case 'new_student':
        return Colors.blue[700]!;
      case 'session_completed':
        return Colors.green[700]!;
      case 'verification_approved':
        return Colors.green[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading dashboard...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              child: _buildDashboardContent(),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color.fromARGB(255, 255, 144, 187),
      automaticallyImplyLeading: false, // Remove default back button
      toolbarHeight: 70, // Increased height for better proportions
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 144, 187),
              Color.fromARGB(255, 255, 120, 170),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          // Menu button aligned to the far left
          Container(
            margin: const EdgeInsets.only(left: 2),
            // Move further left
            child: IconButton(
              icon: const Icon(
                // Adjust padding
                Icons.menu_rounded,
                color: Color.fromRGBO(0, 0, 0, 1),
                size: 24,
              ),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              tooltip: 'Menu',
              padding: const EdgeInsets.all(0), // Reduce padding around icon
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ),
          const SizedBox(width: 4), // Reduced spacing between menu and title
          // Title text
          Expanded(
            child: Text(
              'Admin Dashboard',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 23,
                fontFamily: 'Poppins',
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      actions: [
        // Search button
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(
              Icons.search_rounded,
              color: Color.fromARGB(255, 0, 0, 0),
              size: 22,
            ),
            onPressed: () {
              // Implement search functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search functionality coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Search',
          ),
        ),
        // Notification button with badge
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_rounded,
                  color: Color.fromARGB(255, 0, 0, 0),
                  size: 22,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
                tooltip: 'Notifications',
              ),
              // Notification badge
              if (_stats['pendingApprovals'] != null &&
                  _stats['pendingApprovals']! > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _stats['pendingApprovals']! > 99
                          ? '99+'
                          : '${_stats['pendingApprovals']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

// Helper method for logout confirmation

  Widget _buildDrawer() {
    final navigationItems = [
      {'title': 'Dashboard', 'icon': Icons.dashboard, 'page': 'Dashboard'},
      {
        'title': 'Verified Teachers',
        'icon': Icons.verified_user,
        'page': 'Verified Teachers'
      },
      {
        'title': 'Not Verified Teachers',
        'icon': Icons.person_off,
        'page': 'Not Verified Teachers'
      },
      {'title': 'Students', 'icon': Icons.school, 'page': 'Students'},
      {'title': 'Courses', 'icon': Icons.book, 'page': 'Courses'},
      {'title': 'Sessions', 'icon': Icons.calendar_today, 'page': 'Sessions'},
      {'title': 'Analytics', 'icon': Icons.analytics, 'page': 'Analytics'},
      {'title': 'Settings', 'icon': Icons.settings, 'page': 'Settings'},
    ];

    return Drawer(
      elevation: 0,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 255, 144, 187),
                  Color.fromARGB(255, 255, 144, 187)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.error,
                                  color: Colors.white,
                                  size: 32,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Speakora',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 0, 0),
                            fontSize: 29,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 0, 0, 0),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: navigationItems.length,
              itemBuilder: (context, index) {
                final item = navigationItems[index];
                final isSelected = _selectedPage == item['page'];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? const Color.fromARGB(255, 255, 144, 187)
                            .withOpacity(0.1)
                        : null,
                  ),
                  child: ListTile(
                    leading: Icon(
                      item['icon'] as IconData,
                      color: isSelected
                          ? const Color.fromARGB(255, 255, 144, 187)
                          : Colors.grey[600],
                      size: 20,
                    ),
                    title: Text(
                      item['title'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? const Color.fromARGB(255, 255, 144, 187)
                            : Colors.grey[800],
                        fontFamily: 'Poppins',
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    onTap: () => _navigateToPage(item['page'] as String),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.black,
                size: 20,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
              onTap: () {
                // TODO: Implement proper logout (e.g., clear auth state)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TeacherSignInScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildStatsCards(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildQuickActions(),
                      const SizedBox(height: 16),
                      _buildRecentActivity(),
                    ],
                  ),
                ),
                if (MediaQuery.of(context).size.width > 1200) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildVerificationChart(),
                        const SizedBox(height: 16),
                        _buildNewRegistrations(),
                        const SizedBox(height: 16),
                        _buildGrowthChart(),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (MediaQuery.of(context).size.width <= 1200)
              Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildVerificationChart()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildNewRegistrations()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildGrowthChart(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return _AnimatedStatsCards(stats: _stats);
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 144, 187)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.bolt,
                      color: Color.fromARGB(255, 255, 144, 187),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildQuickActionItem(
                'Review Pending Teachers',
                Icons.person_off_outlined,
                Color.fromARGB(255, 255, 144, 187),
                _stats['notVerifiedTeachers'],
                () => _navigateToPage('Not Verified Teachers'),
              ),
              const SizedBox(height: 12),
              _buildQuickActionItem(
                'Manage Students',
                Icons.school_outlined,
                Color.fromARGB(255, 255, 144, 187),
                null,
                () => _navigateToPage('Students'),
              ),
              const SizedBox(height: 12),
              _buildQuickActionItem(
                'Manage Courses',
                Icons.book_outlined,
                Color.fromARGB(255, 255, 144, 187),
                null,
                () => _navigateToPage('Courses'),
              ),
              const SizedBox(height: 12),
              _buildQuickActionItem(
                'Active Sessions',
                Icons.calendar_today_outlined,
                Color.fromARGB(255, 255, 144, 187),
                _stats['activeSessions'],
                () => _navigateToPage('Sessions'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(
    String title,
    IconData icon,
    Color color,
    int? count,
    VoidCallback onTap,
  ) {
    bool isUrgent = count != null && count > 0 && title.contains('Pending');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent ? color.withOpacity(0.3) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isUrgent ? color.withOpacity(0.05) : Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                      fontSize: 15,
                    ),
                  ),
                ),
                if (count != null && count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isUrgent ? color : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isUrgent ? Colors.white : color,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey[400],
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildRecentActivityCard({
    required List<Map<String, dynamic>> recentActivities,
    required VoidCallback onViewAll,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 144, 187)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history,
                      color: Color.fromARGB(255, 255, 144, 187),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Recent Activities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900],
                        letterSpacing: 0.5,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onViewAll,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      backgroundColor: const Color.fromARGB(255, 255, 144, 187)
                          .withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 144, 187),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (recentActivities.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.history_toggle_off,
                          size: 60,
                          color: Color.fromARGB(255, 255, 144, 187),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No recent activities',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Activities will appear here as they happen',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentActivities.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 16,
                    thickness: 1,
                    color: Colors.grey[200],
                  ),
                  itemBuilder: (context, index) => _buildActivityItem(
                    recentActivities[index],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // You can implement navigation to activity details here if needed
        },
        borderRadius: BorderRadius.circular(12),
        hoverColor: const Color.fromARGB(255, 255, 144, 187).withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      const Color.fromARGB(255, 255, 144, 187).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  activity['icon'] ?? Icons.info,
                  color: const Color.fromARGB(255, 255, 144, 187),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['message'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Color.fromARGB(255, 255, 144, 187),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activity['time'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color:
                      const Color.fromARGB(255, 255, 144, 187).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTeacherVerificationCard({
    required int totalTeachers,
    required int verifiedTeachers,
    required int notVerifiedTeachers,
  }) {
    final verificationRate =
        totalTeachers > 0 ? verifiedTeachers / totalTeachers : 0.0;

    return Card(
      elevation: 4,
      shadowColor: Colors.grey.withAlpha((0.2 * 255).toInt()),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          Color.fromARGB(255, 255, 144, 187).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.verified_user,
                      color: Color.fromARGB(255, 255, 144, 187),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Teacher Verification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900],
                        letterSpacing: 0.5,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Remove the Row and Center widget and use just Center directly
              Center(
                child: SizedBox(
                  height: 140,
                  width: 140,
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          height: 120,
                          width: 120,
                          child: CircularProgressIndicator(
                            value: verificationRate,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color.fromARGB(255, 255, 144, 187),
                            ),
                            strokeWidth: 12,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                      ),
                      Center(
                        child: FittedBox(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(verificationRate * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[900],
                                ),
                                maxLines: 1,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildVerificationStat(
                    'Verified',
                    verifiedTeachers,
                    Color.fromARGB(255, 255, 144, 187),
                  ),
                  _buildVerificationStat(
                    'Pending',
                    notVerifiedTeachers,
                    Colors.orange[800]!,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationStat(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget buildNewRegistrationsCard({
    required int newRegistrations,
    required int newStudents,
    required int newTeachers,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          Color.fromARGB(255, 255, 144, 187).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_add,
                      color: Color.fromARGB(255, 255, 144, 187),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'New Registrations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color.fromARGB(255, 255, 144, 187),
                        letterSpacing: 0.5,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      newRegistrations.toString(),
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 144, 187),
                      ),
                    ),
                    const Text(
                      'This Week',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildRegistrationStat(
                    'Students',
                    newStudents,
                    Color.fromARGB(255, 255, 144, 187),
                  ),
                  _buildRegistrationStat(
                    'Teachers',
                    newTeachers,
                    Color.fromARGB(255, 255, 144, 187),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationStat(String label, int value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            label == 'Students' ? Icons.school : Icons.person,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return buildRecentActivityCard(
      recentActivities: _recentActivities,
      onViewAll: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('View all recent activities tapped.'),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }

  Widget _buildVerificationChart() {
    return buildTeacherVerificationCard(
      totalTeachers: _stats['totalTeachers'] ?? 0,
      verifiedTeachers: _stats['verifiedTeachers'] ?? 0,
      notVerifiedTeachers: _stats['notVerifiedTeachers'] ?? 0,
    );
  }

  Widget _buildNewRegistrations() {
    return buildNewRegistrationsCard(
      newRegistrations: _stats['newRegistrations'] ?? 0,
      newStudents: _stats['newStudents'] ?? 0,
      newTeachers: _stats['newTeachers'] ?? 0,
    );
  }

  Widget _buildGrowthChart() {
    final List<FlSpot> growthData = [
      const FlSpot(0, 10),
      const FlSpot(1, 15),
      const FlSpot(2, 20),
      const FlSpot(3, 25),
      const FlSpot(4, 30),
      const FlSpot(5, 40),
      const FlSpot(6, 50),
    ];

    return Card(
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          Color.fromARGB(255, 255, 144, 187).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.trending_up,
                      color: Color.fromARGB(255, 255, 144, 187),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Platform Growth (Last 7 Weeks)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color.fromARGB(255, 0, 0, 0),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: false,
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              'W${value.toInt() + 1}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontFamily: 'Poppins',
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: 6,
                    minY: 0,
                    maxY: 60,
                    lineBarsData: [
                      LineChartBarData(
                        spots: growthData,
                        isCurved: true,
                        color: Color.fromARGB(255, 255, 144, 187),
                        barWidth: 3,
                        belowBarData: BarAreaData(
                          show: true,
                          color: Color.fromARGB(255, 255, 144, 187)
                              .withOpacity(0.1),
                        ),
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPage(String page) {
    setState(() => _selectedPage = page);
    Navigator.pop(context); // Close drawer

    if (page == 'Dashboard') return;

    Widget? destination;
    switch (page) {
      case 'Students':
        destination = const StudentsScreen();
        break;
      case 'Verified Teachers':
        destination = const TeacherScreen();
        break;
      case 'Not Verified Teachers':
        destination = const NotVerifiedTeachersScreen();
        break;
      case 'Courses':
        destination = const CoursesScreen();
        break;
      case 'Sessions':
        destination = const SessionsScreen();
        break;
      case 'Analytics':
        destination = const AnalyticsScreen();
        break;
      case 'Settings':
        destination = const SettingsScreen();
        break;
    }

    if (destination != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => destination!,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    }
  }
}

class _AnimatedStatsCards extends StatefulWidget {
  final Map<String, int> stats;

  const _AnimatedStatsCards({required this.stats});

  @override
  __AnimatedStatsCardsState createState() => __AnimatedStatsCardsState();
}

class __AnimatedStatsCardsState extends State<_AnimatedStatsCards>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  Timer? _timer;
  int _currentIndex = 0;
  late List<Map<String, dynamic>> _cards;

  @override
  void initState() {
    super.initState();
    _initializeCards();
    _setupAnimations();
    _startAutoSlide();
  }

  void _initializeCards() {
    _cards = [
      {
        'title': 'Total Students',
        'value': widget.stats['totalStudents']?.toString() ?? '0',
        'icon': Icons.school,
        'color': const Color.fromARGB(255, 110, 172, 98),
        'subtitle': '+${widget.stats['newStudents'] ?? 0} this week',
        'gradientStart': const Color(0xFFcaffbf),
        'gradientEnd': const Color(0xFFcaffbf),
      },
      {
        'title': 'Total Teachers',
        'value': widget.stats['totalTeachers']?.toString() ?? '0',
        'icon': Icons.people,
        'color': const Color.fromARGB(255, 65, 133, 139),
        'subtitle': '${widget.stats['verifiedTeachers'] ?? 0} verified',
        'gradientStart': const Color(0xFF9bf6ff),
        'gradientEnd': const Color(0xFF9bf6ff),
      },
      {
        'title': 'Total Courses',
        'value': widget.stats['totalCourses']?.toString() ?? '0',
        'icon': Icons.book,
        'color': const Color.fromARGB(255, 166, 169, 72),
        'subtitle': 'Active courses',
        'gradientStart': const Color(0xFFfdffb6),
        'gradientEnd': const Color(0xFFfdffb6),
      },
      {
        'title': 'Pending Approvals',
        'value': widget.stats['pendingApprovals']?.toString() ?? '0',
        'icon': Icons.pending,
        'color': const Color.fromARGB(255, 164, 116, 57),
        'subtitle': 'Requires attention',
        'gradientStart': const Color(0xFFffd6a5),
        'gradientEnd': const Color(0xFFffd6a5),
      },
    ];
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.0),
      end: const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _cards.length;
        });
        _controller.reset();
      }
    });
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_controller.isAnimating) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ClipRect(
              child: AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return SlideTransition(
                    position: _slideAnimation,
                    child: _buildStatCard(_cards[_currentIndex]),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            ..._cards
                .asMap()
                .entries
                .where((entry) => entry.key != _currentIndex)
                .take(2)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Opacity(
                      opacity: 0.8,
                      child: Transform.scale(
                        scale: 0.95,
                        child: _buildStatCard(entry.value),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> card) {
    return Hero(
      tag: 'stat_card_${card['title']}',
      child: Card(
        elevation: 4,
        shadowColor: Colors.grey.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 200,
          height: 130,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                card['gradientStart'] as Color,
                card['gradientEnd'] as Color,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // TODO: Implement stat card tap action
              },
              child: Padding(
                padding: const EdgeInsets.all(12), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card['title'] as String,
                                style: const TextStyle(
                                  fontSize: 18, // Reduced font size
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis, // Prevent overflow
                              ),
                              const SizedBox(height: 8), // Reduced spacing
                              Text(
                                card['value'] as String,
                                style: const TextStyle(
                                  fontSize: 20, // Reduced font size
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis, // Prevent overflow
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6), // Reduced padding
                          decoration: BoxDecoration(
                            color: (card['color'] as Color).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            card['icon'] as IconData,
                            color: card['color'] as Color,
                            size: 18, // Reduced icon size
                          ),
                        ),
                      ],
                    ),
                    Text(
                      card['subtitle'] as String,
                      style: const TextStyle(
                        fontSize: 15, // Reduced font size
                        color: Color.fromARGB(179, 0, 0, 0),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // Prevent overflow
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
