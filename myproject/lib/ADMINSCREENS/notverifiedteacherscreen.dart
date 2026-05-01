import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'notificationscreen.dart'; // Import your NotificationsScreen

class NotVerifiedTeachersScreen extends StatefulWidget {
  const NotVerifiedTeachersScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NotVerifiedTeachersScreenState createState() =>
      _NotVerifiedTeachersScreenState();
}

class _NotVerifiedTeachersScreenState extends State<NotVerifiedTeachersScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _searchQuery = '';
  late AnimationController _searchAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _searchAnimation;
  late Animation<Offset> _listSlideAnimation;
  bool _isSearchExpanded = false;

  // Material Design color scheme
  final _primaryColor = const Color.fromARGB(255, 255, 144, 187); // Deep Blue
  final _secondaryColor = const Color(0xFF00C853); // Green
  final _errorColor = const Color(0xFFD32F2F); // Red
  final _warningColor = const Color(0xFFF57C00); // Orange
  final _surfaceColor = const Color(0xFFFAFAFA); // Light Grey
  final _backgroundColor = const Color(0xFFF5F7FA); // Off White

  @override
  void initState() {
    super.initState();
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _searchAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _searchAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _listSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _listAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _searchAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  Future<void> _verifyTeacher(
      String uid, String fullName, Map<String, dynamic> teacherData) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.verified_user, color: _secondaryColor),
              const SizedBox(width: 12),
              Text(
                'Verify Teacher',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to verify $fullName? This will:\n\n• Move them to verified teachers',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check_circle, size: 18),
              label: Text(
                'Verify',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _secondaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Show loading dialog
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          content: Row(
            children: [
              CircularProgressIndicator(color: _primaryColor),
              const SizedBox(width: 20),
              Text('Processing verification...', style: GoogleFonts.poppins()),
            ],
          ),
        ),
      );

      final teacherEmail = teacherData['about']['email'];

      if (teacherEmail == null || teacherEmail.isEmpty) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
        throw Exception('Teacher email is missing or invalid');
      }

      // Check if user exists in Firebase Auth
      String? authUid;
      bool isNewUser = false;
      bool needsPasswordReset = false;

      try {
        final signInMethods =
            // ignore: deprecated_member_use
            await _auth.fetchSignInMethodsForEmail(teacherEmail);

        if (signInMethods.isEmpty) {
          // User doesn't exist - we won't create an account here
          isNewUser = true;
        } else {
          // User exists - we won't modify their account
          needsPasswordReset = false;
        }
      } catch (e) {
        print('Auth error: $e');
      }

      // Update teacher data in Firestore
      final updatedTeacherData = {
        ...teacherData,
        'status': 'verified',
        'verifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'authUid': authUid ?? uid,
        'isNewUser': isNewUser,
        'needsPasswordUpdate': needsPasswordReset,
        'verifiedBy': _auth.currentUser?.email ?? 'admin',
        // Ensure profilePhoto and languages are preserved
        'profilePhoto': teacherData['profilePhoto'] ?? {'profilePhotoUrl': ''},
        'about': {
          ...teacherData['about'],
          'languages': teacherData['about']['languages'] ?? [],
        },
      };

      try {
        await _firestore.runTransaction((transaction) async {
          final verifiedTeacherRef = _firestore.collection('teachers').doc(uid);
          final verifiedTeacherSnapshot =
              await transaction.get(verifiedTeacherRef);

          if (verifiedTeacherSnapshot.exists) {
            transaction.update(verifiedTeacherRef, updatedTeacherData);
          } else {
            transaction.set(verifiedTeacherRef, updatedTeacherData);
          }

          // Remove from not verified collection
          final notVerifiedRef =
              _firestore.collection('teachers_not_verified').doc(uid);
          transaction.delete(notVerifiedRef);
        });
      } catch (e) {
        Navigator.pop(context);
        throw Exception('Failed to save teacher data to database: $e');
      }

      // Send verification email
      try {
        await _sendVerificationEmail(
          teacherEmail,
          fullName,
          isNewUser,
          needsPasswordReset,
        );
      } catch (e) {
        print('Email sending failed: $e');
      }

      // Log admin action
      try {
        await _firestore.collection('admin_logs').add({
          'action': 'teacher_verified',
          'teacherId': uid,
          'teacherEmail': teacherEmail,
          'teacherName': fullName,
          'authUid': authUid,
          'adminEmail': _auth.currentUser?.email,
          'timestamp': FieldValue.serverTimestamp(),
          'isNewUser': isNewUser,
          'needsPasswordUpdate': needsPasswordReset,
          'verificationMethod': 'admin_panel',
        });
      } catch (e) {
        print('Failed to log admin action: $e');
      }

      // Close loading dialog
      Navigator.pop(context);

      // Show success dialog with overflow fix
      await showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: _secondaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Teacher Verified Successfully!',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.3,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          '$fullName has been verified and can now login.',
                          style: GoogleFonts.poppins(),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          '✅ Teacher data updated in database',
                          style: GoogleFonts.poppins(color: Colors.green[700]),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          '✅ Verification email sent to $teacherEmail',
                          style: GoogleFonts.poppins(color: Colors.green[700]),
                        ),
                        if (needsPasswordReset) ...[
                          const SizedBox(height: 4),
                          SelectableText(
                            '⚠️ Password reset required on first login',
                            style:
                                GoogleFonts.poppins(color: Colors.orange[700]),
                          ),
                        ],
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _secondaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('OK', style: GoogleFonts.poppins()),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Refresh the screen
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error verifying teacher: ${_getUserFriendlyError(e.toString())}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  Future<void> _sendVerificationEmail(
    String email,
    String fullName,
    bool isNewUser,
    bool needsPasswordReset,
  ) async {
    try {
      try {
        final smtpServer =
            gmail('shehzana67890@gmail.com', 'kmvp nkdj ktdm mrjk');

        final message = Message()
          ..from = Address('shehzana67890@gmail.com', 'Speakora Admin Team')
          ..recipients.add(email)
          ..subject = 'Your Teacher Account Has Been Verified'
          ..html = '''
            <h3>Dear $fullName,</h3>
            <p>Your teacher account has been verified successfully.</p>
            <h4>Login Credentials:</h4>
            <p><strong>Email:</strong> $email</p>
            <p><strong>NOTE:</strong> Now you can login to your account.</p>
            ''';

        final sendReport = await send(message, smtpServer);
        print('✅ Email sent: ${sendReport.toString()}');
      } catch (e) {
        print('SMTP Server Error: $e');
        throw Exception('Failed to configure email server: $e');
      }
    } catch (e) {
      print('❌ Email sending failed: $e');
      rethrow;
    }
  }

  Future<void> _checkNetworkConnectivity() async {
    try {
      await _firestore.collection('connectivity_test').limit(1).get();
    } catch (e) {
      throw Exception(
          'Network connectivity issue. Please check your internet connection.');
    }
  }

  Future<void> _createAuthAccountWithRetry(
      String email, String password, String uid) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        // ignore: deprecated_member_use
        final signInMethods = await _auth.fetchSignInMethodsForEmail(email);

        if (signInMethods.isEmpty) {
          final userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          await _firestore.collection('teachers').doc(uid).update({
            'authUid': userCredential.user?.uid,
            'needsAuthSetup': false,
          });

          await _auth.signOut();
          return;
        } else {
          await _firestore.collection('teachers').doc(uid).update({
            'needsAuthSetup': false,
          });
          return;
        }
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          throw Exception(
              'Failed to create auth account after $maxRetries attempts: $e');
        }
        await Future.delayed(Duration(seconds: 2 * retryCount));
      }
    }
  }

  String _getUserFriendlyError(String error) {
    if (error.contains('network-request-failed') || error.contains('timeout')) {
      return 'Network connection issue. Please check your internet connection and try again.';
    } else if (error.contains('permission-denied')) {
      return 'Permission denied. Please ensure you have admin privileges.';
    } else if (error.contains('email-already-in-use')) {
      return 'An account with this email already exists. The teacher will be verified with existing credentials.';
    } else if (error.contains('invalid-email')) {
      return 'The teacher\'s email address is invalid. Please update their email and try again.';
    } else if (error.contains('weak-password')) {
      return 'The generated password is too weak. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again or contact support.';
    }
  }

  Future<void> _ensureAdminSession() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Admin session lost. Please login again.');
      }

      final adminDoc =
          await _firestore.collection('admins').doc(currentUser.uid).get();
      if (!adminDoc.exists) {
        throw Exception('Admin privileges not found. Access denied.');
      }
    } catch (e) {
      throw Exception('Admin authentication failed: $e');
    }
  }

  Future<void> _deleteTeacher(String uid, String fullName) async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.delete_forever, color: _errorColor),
              const SizedBox(width: 12),
              Text(
                'Delete Teacher',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete $fullName? This action cannot be undone.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete, size: 18),
              label: Text(
                'Delete',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );

      if (confirm != true) return;

      await _firestore.collection('teachers_not_verified').doc(uid).delete();

      await _firestore.collection('admin_logs').add({
        'action': 'teacher_deleted',
        'teacherId': uid,
        'teacherName': fullName,
        'timestamp': FieldValue.serverTimestamp(),
        'details': 'Unverified teacher deleted by admin',
      });

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationsScreen(),
        ),
      );
      await _generateNotification(
        uid,
        fullName,
        'Teacher $fullName has been deleted.',
        'teacher_deletion',
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const NotificationsScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error deleting teacher: $e',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
            backgroundColor: _errorColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _generateNotification(
      String userId, String userName, String details, String type) async {
    try {
      await _firestore.collection('notifications').add({
        'type': type,
        'userId': userId,
        'userName': userName,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'sessionId': null,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error generating notification: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: _errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryColor,
          primary: _primaryColor,
          secondary: _secondaryColor,
          error: _errorColor,
          surface: _surfaceColor,
          background: _backgroundColor,
        ),
      ),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverFillRemaining(child: _buildTeacherList()),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 110,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: _primaryColor,
      iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Not Verified Teachers',
          style: GoogleFonts.poppins(
            color: const Color.fromARGB(255, 0, 0, 0),
            fontWeight: FontWeight.bold,
            fontSize: 21,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _primaryColor,
                Color.lerp(_primaryColor, Colors.black, 0.2)!,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromARGB(255, 255, 255, 255)
                        .withOpacity(0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _searchAnimation,
            color: const Color.fromARGB(255, 0, 0, 0),
          ),
          onPressed: () {
            setState(() {
              _isSearchExpanded = !_isSearchExpanded;
              if (_isSearchExpanded) {
                _searchAnimationController.forward();
              } else {
                _searchAnimationController.reverse();
                _searchQuery = '';
              }
            });
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isSearchExpanded ? 80 : 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _isSearchExpanded ? 1.0 : 0.0,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            onChanged: (value) =>
                setState(() => _searchQuery = value.toLowerCase()),
            style: GoogleFonts.poppins(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
              prefixIcon: Icon(Icons.search, color: _primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: _surfaceColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('teachers_not_verified').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final teachers = snapshot.data?.docs ?? [];
        final mappedTeachers = teachers.map((doc) {
          final data = doc.data() as Map<String, dynamic>;

          final about = data['about'] as Map<String, dynamic>? ?? {};
          final profilePhoto =
              data['profilePhoto'] as Map<String, dynamic>? ?? {};
          final languages = (about['languages'] as List<dynamic>?)
                  ?.map((lang) => '${lang['language']} (${lang['level']})')
                  .toList() ??
              [];

          final firstName = about['firstName']?.toString() ?? 'Unknown';
          final lastName = about['lastName']?.toString() ?? '';
          final fullName = '$firstName $lastName'.trim();

          final certifications = (data['certifications'] as List<dynamic>?)
                  ?.map((cert) => cert as Map<String, dynamic>)
                  .toList() ??
              [];
          final education = (data['education'] as List<dynamic>?)
                  ?.map((edu) => edu as Map<String, dynamic>)
                  .toList() ??
              [];
          final description =
              data['description'] as Map<String, dynamic>? ?? {};
          final video = data['video'] as Map<String, dynamic>? ?? {};
          final availability =
              data['availability'] as Map<String, dynamic>? ?? {};
          final days = (availability['days'] as Map<String, dynamic>?)
                  ?.map((day, dayData) {
                final slots = (dayData['slots'] as List<dynamic>?)
                        ?.map((slot) => slot as Map<String, dynamic>)
                        .toList() ??
                    [];
                return MapEntry(day, {
                  'enabled': dayData['enabled'] as bool? ?? false,
                  'slots': slots,
                });
              }) ??
              {};
          final pricing = data['pricing'] as Map<String, dynamic>? ?? {};

          return {
            'uid': doc.id,
            'fullName': fullName.isNotEmpty ? fullName : 'Unknown',
            'email': about['email']?.toString() ?? 'No email',
            'teachingCourse': about['teachingCourse']?.toString() ?? '',
            'languages': languages,
            'createdAt': data['createdAt'] ?? Timestamp.now(),
            'profileComplete': about.isNotEmpty &&
                profilePhoto['profilePhotoUrl'] != null &&
                profilePhoto['profilePhotoUrl'].isNotEmpty &&
                certifications.isNotEmpty &&
                education.isNotEmpty &&
                description.isNotEmpty &&
                video.isNotEmpty &&
                availability.isNotEmpty &&
                pricing.isNotEmpty,
            'data': {
              'about': {
                'firstName': firstName,
                'lastName': lastName,
                'country': about['country']?.toString() ?? '',
                'email': about['email']?.toString() ?? '',
                'phoneNumber': about['phoneNumber']?.toString() ?? '',
                'teachingCourse': about['teachingCourse']?.toString() ?? '',
                'languages': about['languages'] ?? [],
              },
              'profilePhoto': {
                'profilePhotoUrl':
                    profilePhoto['profilePhotoUrl']?.toString() ?? '',
              },
              'certifications': certifications,
              'education': education,
              'description': {
                'intro': description['intro']?.toString() ?? '',
                'experience': description['experience']?.toString() ?? '',
                'motivation': description['motivation']?.toString() ?? '',
              },
              'video': {
                'videoUrl': video['videoUrl']?.toString() ?? '',
              },
              'availability': {
                'timezone': availability['timezone']?.toString() ?? '',
                'days': days,
              },
              'pricing': {
                'standardRate': pricing['standardRate']?.toDouble() ?? 0.0,
                'introRate': pricing['introRate']?.toDouble(),
              },
              'status': data['status']?.toString() ?? 'not_verified',
              'createdAt': data['createdAt'],
              'updatedAt': data['updatedAt'],
            },
          };
        }).toList();

        final filteredTeachers = mappedTeachers.where((teacher) {
          final name = teacher['fullName'].toLowerCase();
          final email = teacher['email'].toLowerCase();
          return name.contains(_searchQuery) || email.contains(_searchQuery);
        }).toList();

        if (filteredTeachers.isEmpty) {
          return _buildEmptyState();
        }

        return SlideTransition(
          position: _listSlideAnimation,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filteredTeachers.length,
            itemBuilder: (context, index) {
              final teacher = filteredTeachers[index];
              return _buildTeacherCard(teacher);
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading teachers...',
            style: GoogleFonts.poppins(
              color: Colors.grey[700],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: _errorColor, size: 64),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.poppins(
              color: Colors.grey[700],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: Text(
              'Try Again',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
          Icon(
            Icons.person_off_outlined,
            color: Colors.grey[400],
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            'No unverified teachers found',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search'
                : 'All teachers are verified',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(Map<String, dynamic> teacher) {
    final createdAt = (teacher['createdAt'] as Timestamp?)?.toDate();
    final formattedDate = createdAt != null
        ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
        : 'Unknown';
    final profilePhotoUrl =
        teacher['data']['profilePhoto']['profilePhotoUrl'] ?? '';

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showTeacherDetails(teacher),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Hero(
                    tag: 'avatar-${teacher['uid']}',
                    child: CircleAvatar(
                      radius: 32,
                      backgroundImage: profilePhotoUrl.isNotEmpty
                          ? NetworkImage(profilePhotoUrl)
                          : null,
                      backgroundColor: _primaryColor,
                      child: profilePhotoUrl.isEmpty
                          ? Text(
                              teacher['fullName']
                                      ?.substring(0, 1)
                                      .toUpperCase() ??
                                  'U',
                              style: GoogleFonts.poppins(
                                color: const Color.fromARGB(255, 0, 0, 0),
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teacher['fullName'],
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            color: Colors.grey[900],
                          ),
                        ),
                        Text(
                          teacher['email'],
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: Colors.white,
                    onSelected: (value) => _handleMenuAction(value, teacher),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility,
                                color: _primaryColor, size: 20),
                            const SizedBox(width: 12),
                            Text('View Details', style: GoogleFonts.poppins()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'verify',
                        child: Row(
                          children: [
                            Icon(Icons.verified_user,
                                color: _secondaryColor, size: 20),
                            const SizedBox(width: 12),
                            Text('Verify',
                                style: GoogleFonts.poppins(
                                    color: _secondaryColor)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_forever,
                                color: _errorColor, size: 20),
                            const SizedBox(width: 12),
                            Text('Delete',
                                style: GoogleFonts.poppins(color: _errorColor)),
                          ],
                        ),
                      ),
                    ],
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(
                      teacher['profileComplete'] ? 'Complete' : 'Incomplete',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: teacher['profileComplete']
                            ? _secondaryColor
                            : _warningColor,
                      ),
                    ),
                    backgroundColor: teacher['profileComplete']
                        ? _secondaryColor.withOpacity(0.1)
                        : _warningColor.withOpacity(0.1),
                    avatar: Icon(
                      teacher['profileComplete']
                          ? Icons.check_circle
                          : Icons.warning,
                      size: 16,
                      color: teacher['profileComplete']
                          ? _secondaryColor
                          : _warningColor,
                    ),
                  ),
                  if (teacher['teachingCourse'].isNotEmpty)
                    Chip(
                      label: Text(
                        teacher['teachingCourse'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _primaryColor,
                        ),
                      ),
                      backgroundColor: _primaryColor.withOpacity(0.1),
                      avatar: Icon(
                        Icons.school,
                        size: 16,
                        color: _primaryColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Registered: $formattedDate',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => _verifyTeacher(
                        teacher['uid'], teacher['fullName'], teacher['data']),
                    icon: const Icon(Icons.verified_user, size: 16),
                    label: Text(
                      'Verify Now',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: _secondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(String action, Map<String, dynamic> teacher) {
    switch (action) {
      case 'view':
        _showTeacherDetails(teacher);
        break;
      case 'verify':
        _verifyTeacher(teacher['uid'], teacher['fullName'], teacher['data']);
        break;
      case 'delete':
        _deleteTeacher(teacher['uid'], teacher['fullName']);
        break;
    }
  }

  void _showTeacherDetails(Map<String, dynamic> teacher) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildTeacherDetailsContent(teacher),
                      ),
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

  Widget _buildTeacherDetailsContent(Map<String, dynamic> teacher) {
    final data = teacher['data'];
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final certifications = data['certifications'] as List<dynamic>;
    final education = data['education'] as List<dynamic>;
    final availability = data['availability']['days'] as Map<String, dynamic>;
    final profilePhotoUrl = data['profilePhoto']['profilePhotoUrl'] ?? '';
    final languages = data['about']['languages'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Hero(
                tag: 'avatar-${teacher['uid']}',
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: profilePhotoUrl.isNotEmpty
                      ? NetworkImage(profilePhotoUrl)
                      : null,
                  backgroundColor: _primaryColor,
                  child: profilePhotoUrl.isEmpty
                      ? Text(
                          teacher['fullName'].substring(0, 1).toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: const Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                teacher['fullName'],
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text(
                  teacher['profileComplete']
                      ? 'Profile Complete'
                      : 'Profile Incomplete',
                  style: GoogleFonts.poppins(
                    color: teacher['profileComplete']
                        ? _secondaryColor
                        : _warningColor,
                  ),
                ),
                backgroundColor: teacher['profileComplete']
                    ? _secondaryColor.withOpacity(0.1)
                    : _warningColor.withOpacity(0.1),
                avatar: Icon(
                  teacher['profileComplete']
                      ? Icons.check_circle
                      : Icons.warning,
                  color: teacher['profileComplete']
                      ? _secondaryColor
                      : _warningColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionTitle('About'),
        _buildDetailItem('Email', data['about']['email'], Icons.email),
        _buildDetailItem('Phone',
            data['about']['phoneNumber'] ?? 'Not provided', Icons.phone),
        _buildDetailItem('Country', data['about']['country'] ?? 'Not specified',
            Icons.location_on),
        _buildDetailItem('Teaching Course',
            data['about']['teachingCourse'] ?? 'Not specified', Icons.subject),
        _buildDetailItem(
            'Languages',
            languages.isNotEmpty
                ? languages
                    .map((lang) => '${lang['language']} (${lang['level']})')
                    .join(', ')
                : 'Not specified',
            Icons.language),
        const SizedBox(height: 16),
        _buildSectionTitle('Description'),
        _buildDetailItem('Introduction',
            data['description']['intro'] ?? 'Not provided', Icons.info),
        _buildDetailItem('Experience',
            data['description']['experience'] ?? 'Not provided', Icons.work),
        _buildDetailItem('Motivation',
            data['description']['motivation'] ?? 'Not provided', Icons.star),
        const SizedBox(height: 16),
        _buildSectionTitle('Certifications'),
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            child: Column(
              children: [
                ...certifications.map((cert) => Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: const Color.fromARGB(255, 243, 243, 243),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Text(
                                      cert['certification'] ??
                                          'Unknown Certification',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailRow(
                                      'Subject', cert['subject'] ?? 'N/A'),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailRow('Description',
                                      cert['description'] ?? 'N/A'),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailRow(
                                      'Issued By', cert['issuedBy'] ?? 'N/A'),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailRow('Years',
                                      '${cert['startYear'] ?? 'N/A'} - ${cert['endYear'] ?? 'N/A'}'),
                                ),
                              ],
                            ),
                            if (cert['fileName'] != null &&
                                cert['fileName'].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: TextButton.icon(
                                  onPressed: () {
                                    // Implement file view logic
                                  },
                                  icon: Icon(Icons.file_present,
                                      color: _primaryColor, size: 20),
                                  label: Text('View Document',
                                      style: GoogleFonts.poppins(
                                          color: _primaryColor)),
                                ),
                              ),
                            if (cert['fileUrl'] != null &&
                                cert['fileUrl'].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: TextButton.icon(
                                  onPressed: () {
                                    // Implement file view logic
                                  },
                                  icon: Icon(Icons.link,
                                      color: _primaryColor, size: 20),
                                  label: Text('View File URL',
                                      style: GoogleFonts.poppins(
                                          color: _primaryColor)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Education'),
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            child: Column(
              children: [
                ...education.map((edu) => Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: const Color.fromARGB(255, 243, 243, 243),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Text(
                                      '${edu['degree'] ?? 'Unknown'} (${edu['degree_type'] ?? ''})',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if ((edu['specialization'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Text(
                                        'in ${edu['specialization']}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailRow(
                                      'University', edu['university'] ?? 'N/A'),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailRow('Degree Type',
                                      edu['degree_type'] ?? 'N/A'),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailRow('Specialization',
                                      edu['specialization'] ?? 'N/A'),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDetailRow('Duration',
                                      '${edu['start_year'] ?? 'N/A'} - ${edu['end_year'] ?? 'N/A'}'),
                                ),
                              ],
                            ),
                            if (edu['file_name'] != null &&
                                edu['file_name'].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: TextButton.icon(
                                  onPressed: () {
                                    // Implement file view logic
                                  },
                                  icon: Icon(Icons.file_present,
                                      color: _primaryColor, size: 20),
                                  label: Text('View Document',
                                      style: GoogleFonts.poppins(
                                          color: _primaryColor)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Video'),
        _buildDetailItem('Video URL',
            data['video']['videoUrl'] ?? 'Not provided', Icons.video_library),
        const SizedBox(height: 16),
        _buildSectionTitle('Availability'),
        _buildDetailItem(
            'Timezone',
            data['availability']['timezone'] ?? 'Not specified',
            Icons.access_time),
        SizedBox(
          height: 150,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: availability.entries
                  .where((entry) => entry.value['enabled'])
                  .map((entry) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: Card(
                            elevation: 1,
                            color: const Color.fromARGB(255, 234, 234, 234),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: (entry.value['slots']
                                                as List<dynamic>)
                                            .map((slot) => Text(
                                                  '${slot['from']} - ${slot['to']}',
                                                  style: GoogleFonts.poppins(
                                                    color: const Color.fromARGB(
                                                        255, 0, 0, 0),
                                                    fontSize: 12,
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Pricing'),
        _buildDetailItem(
            'Standard Rate',
            '\$${data['pricing']['standardRate'].toStringAsFixed(2)}/hr',
            Icons.monetization_on),
        if (data['pricing']['introRate'] != null)
          _buildDetailItem(
              'Intro Rate',
              '\$${data['pricing']['introRate'].toStringAsFixed(2)}/hr',
              Icons.monetization_on),
        if (createdAt != null) ...[
          const SizedBox(height: 16),
          _buildSectionTitle('Registration'),
          _buildDetailItem(
              'Created At',
              '${createdAt.day}/${createdAt.month}/${createdAt.year}',
              Icons.calendar_today),
        ],
        const SizedBox(height: 24),
        _buildSectionTitle('Actions'),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            _verifyTeacher(
                teacher['uid'], teacher['fullName'], teacher['data']);
          },
          icon: const Icon(Icons.verified_user, size: 20),
          label: Text('Verify Teacher',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _secondaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 0),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            _deleteTeacher(teacher['uid'], teacher['fullName']);
          },
          icon: const Icon(Icons.delete_forever, size: 20),
          label: Text('Delete Teacher',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _errorColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 0),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.grey[900],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[900],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  color: Colors.grey[900],
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
