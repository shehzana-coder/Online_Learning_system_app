import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class TeacherScreen extends StatefulWidget {
  final bool isAdmin;

  const TeacherScreen({Key? key, this.isAdmin = false}) : super(key: key);

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _searchQuery = '';
  late AnimationController _fabAnimationController;
  late AnimationController _searchAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<double> _searchAnimation;
  bool _isSearchExpanded = false;

  final ColorScheme _colorScheme = ColorScheme(
    primary: const Color.fromARGB(255, 255, 144, 187),
    primaryContainer: Color.fromARGB(255, 255, 219, 233),
    secondary: const Color.fromARGB(255, 239, 199, 214),
    secondaryContainer: const Color.fromARGB(255, 234, 181, 201),
    surface: Colors.white,
    error: const Color.fromARGB(255, 249, 75, 75),
    onPrimary: const Color.fromARGB(255, 255, 255, 255),
    onSecondary: Colors.white,
    onSurface: const Color.fromARGB(255, 255, 144, 187),
    background: const Color.fromARGB(255, 255, 246, 246),
    onError: Colors.white,
    brightness: Brightness.light,
  );

  final Color _verifiedColor = const Color.fromARGB(255, 255, 144, 187);
  final Color _deleteColor = const Color.fromARGB(255, 255, 79, 79);

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    );

    _searchAnimation = CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    );

    if (mounted) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _fabAnimationController.forward();
          _listAnimationController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _searchAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        colorScheme: _colorScheme,
        textTheme: GoogleFonts.poppinsTextTheme(),
        cardTheme: CardTheme(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: _colorScheme.primaryContainer,
          selectedColor: _colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          labelStyle: GoogleFonts.poppins(fontSize: 14),
          secondaryLabelStyle:
              GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          secondarySelectedColor: _colorScheme.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            textStyle:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: _colorScheme.primary,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white, // Changed to white
        body: _buildBody(),
        floatingActionButton: widget.isAdmin ? _buildAdminFab() : null,
      ),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(),
        SliverToBoxAdapter(child: _buildSearchAndFilter()),
        SliverFillRemaining(child: _buildTeacherList()),
      ],
    );
  }

  Widget _buildAdminFab() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) => Transform.scale(
        scale: _fabAnimation.value,
        child: FloatingActionButton.extended(
          onPressed: _showAdminOptions,
          backgroundColor: _colorScheme.secondary,
          elevation: 6,
          heroTag: 'adminFab',
          icon: const Icon(Icons.admin_panel_settings,
              color: Color.fromARGB(255, 0, 0, 0),
              semanticLabel: 'Admin Options'),
          label: Text(
            'Admin',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: _colorScheme.primary,
      iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Teachers',
          style: GoogleFonts.poppins(
            color: const Color.fromARGB(255, 0, 0, 0),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _colorScheme.primary.withOpacity(0.8),
                _colorScheme.primary,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Positioned(
                left: -40,
                bottom: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(75),
                  ),
                ),
              ),
            ],
          ),
        ),
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
      ),
      actions: [
        IconButton(
          icon: AnimatedIcon(
            icon: AnimatedIcons.search_ellipsis,
            progress: _searchAnimation,
            color: const Color.fromARGB(255, 0, 0, 0),
            size: 28,
            semanticLabel: 'Toggle Search',
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
          tooltip: 'Search',
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isSearchExpanded
                  ? FadeTransition(
                      opacity: _searchAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Search',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            onChanged: (value) => setState(
                                () => _searchQuery = value.toLowerCase()),
                            style: GoogleFonts.poppins(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Search by name or email',
                              hintStyle:
                                  GoogleFonts.poppins(color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.search,
                                  color: _colorScheme.primary,
                                  semanticLabel: 'Search'),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 16),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: _colorScheme.primary, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherList() {
    return StreamBuilder<List<QuerySnapshot>>(
      stream: _buildTeacherStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('StreamBuilder error: ${snapshot.error}'); // Debug log
          return _buildErrorState('Failed to load teachers. Please try again.');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        List<QueryDocumentSnapshot> verifiedTeachers = [];
        verifiedTeachers =
            snapshot.data?.isNotEmpty == true ? snapshot.data![0].docs : [];
        print(
            'Verified teachers count: ${verifiedTeachers.length}'); // Debug log

        final mappedTeachers = verifiedTeachers.map((doc) {
          final teachers = doc.data() as Map<String, dynamic>? ?? {};
          print('Teacher ${doc.id} raw data: $teachers'); // Debug log
          final about = teachers['about'] is Map<String, dynamic>
              ? teachers['about'] as Map<String, dynamic>
              : <String, dynamic>{};
          final education = teachers['education'] is List
              ? teachers['education'] as List<dynamic>
              : (teachers['education'] is Map<String, dynamic>
                  ? [teachers['education'] as Map<String, dynamic>]
                  : <Map<String, dynamic>>[]);
          final certifications = teachers['certifications'] is List
              ? teachers['certifications'] as List<dynamic>
              : (teachers['certifications'] is Map<String, dynamic>
                  ? [teachers['certifications'] as Map<String, dynamic>]
                  : <Map<String, dynamic>>[]);
          final description = teachers['description'] is Map<String, dynamic>
              ? teachers['description'] as Map<String, dynamic>
              : <String, dynamic>{};
          final availability = teachers['availability'] is Map<String, dynamic>
              ? teachers['availability'] as Map<String, dynamic>
              : <String, dynamic>{
                  'timezone': '',
                  'days': [],
                };
          print('Teacher ${doc.id} availability: $availability'); // Debug log
          final profilePhoto = teachers['profilePhoto'] is Map<String, dynamic>
              ? teachers['profilePhoto'] as Map<String, dynamic>
              : <String, dynamic>{};
          final video = teachers['video'] is Map<String, dynamic>
              ? teachers['video'] as Map<String, dynamic>
              : <String, dynamic>{};
          final pricing = teachers['pricing'] is Map<String, dynamic>
              ? teachers['pricing'] as Map<String, dynamic>
              : <String, dynamic>{};

          final firstName = about['firstName']?.toString() ?? 'Unknown';
          final lastName = about['lastName']?.toString() ?? '';
          final fullName = '$firstName $lastName'.trim();

          return {
            'id': doc.id,
            'about': {
              'fullName': fullName.isNotEmpty ? fullName : 'Unknown',
              'firstName': firstName,
              'lastName': lastName,
              'country': about['country']?.toString() ?? 'Not specified',
              'email': about['email']?.toString() ?? 'No email',
              'phoneNumber':
                  about['phoneNumber']?.toString() ?? 'Not specified',
              'teachingCourse': about['teachingCourse']?.toString() ?? '',
            },
            'profilePhoto': {
              'profilePhotoUrl':
                  profilePhoto['profilePhotoUrl']?.toString() ?? '',
            },
            'certifications': certifications.isNotEmpty
                ? certifications
                : [
                    {
                      'subject': 'Not specified',
                      'certification': 'Not specified',
                      'description': 'Not specified',
                      'issuedBy': 'Not specified',
                      'startYear': 'N/A',
                      'endYear': 'N/A',
                      'fileName': '',
                      'fileUrl': ''
                    }
                  ],
            'education': education.isNotEmpty
                ? education
                : [
                    {
                      'university': 'Not specified',
                      'degree': 'Not specified',
                      'degree_type': 'Not specified',
                      'specialization': 'Not specified',
                      'start_year': 'N/A',
                      'end_year': 'N/A',
                      'file_name': ''
                    }
                  ],
            'description': {
              'intro': description['intro']?.toString() ?? 'Not specified',
              'experience':
                  description['experience']?.toString() ?? 'Not specified',
              'motivation':
                  description['motivation']?.toString() ?? 'Not specified',
            },
            'video': {
              'videoUrl': video['videoUrl']?.toString() ?? '',
            },
            'availability': {
              'timezone':
                  availability['timezone']?.toString() ?? 'Not specified',
              'days': (availability['days'] is List
                  ? (availability['days'] as List<dynamic>).map((day) {
                      return {
                        'days': day['days']?.toString() ?? 'Unknown',
                        'enabled': day['enabled'] ?? false,
                        'slots': (day['slots'] is List
                            ? (day['slots'] as List<dynamic>).map((slot) {
                                return {
                                  'from': slot['from']?.toString() ?? 'N/A',
                                  'to': slot['to']?.toString() ?? 'N/A',
                                };
                              }).toList()
                            : []),
                      };
                    }).toList()
                  : []),
            },
            'pricing': {
              'standardRate':
                  pricing['standardRate']?.toString() ?? 'Not specified',
              'introRate': pricing['introRate']?.toString() ?? 'Not specified',
            },
            'status': teachers['status']?.toString() ?? 'verified',
            'collection': doc.reference.parent.id,
          };
        }).toList();

        final filteredTeachers = _filterTeachers(mappedTeachers);

        if (filteredTeachers.isEmpty) {
          print(
              'Filtered teachers empty. Search query: $_searchQuery'); // Debug log
          return _buildEmptyState();
        }

        return AnimatedBuilder(
          animation: _listAnimationController,
          builder: (context, child) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              itemCount: filteredTeachers.length,
              itemBuilder: (context, index) {
                final teachers = filteredTeachers[index];
                final teacherId = teachers['id'];
                final Animation<double> itemAnimation = CurvedAnimation(
                  parent: _listAnimationController,
                  curve: Interval(
                    0.1 + (index / filteredTeachers.length) * 0.6,
                    1.0,
                    curve: Curves.easeInOut,
                  ),
                );

                return AnimatedBuilder(
                  animation: itemAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - itemAnimation.value)),
                      child: Opacity(
                        opacity: itemAnimation.value,
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 3,
                          shadowColor: Colors.black.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _buildTeacherCard(teachers, teacherId, index),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Stream<List<QuerySnapshot>> _buildTeacherStream() {
    Query<Map<String, dynamic>> verifiedQuery =
        _firestore.collection('teachers');

    if (_searchQuery.isNotEmpty) {
      verifiedQuery = verifiedQuery.where('about.fullName',
          isGreaterThanOrEqualTo: _searchQuery);
    }

    return verifiedQuery.snapshots().map((verified) => [verified]);
  }

  Widget _buildLoadingState() {
    return Center(
      child: CustomLoadingDialog(
        message: 'Loading teachers...',
        color: _colorScheme.primary,
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: CustomErrorWidget(
        message: message,
        onRetry: () => setState(() {}),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: CustomEmptyState(
        isSearchActive: _searchQuery.isNotEmpty,
        onClearSearch: () => setState(() => _searchQuery = ''),
      ),
    );
  }

  List<Map<String, dynamic>> _filterTeachers(
      List<Map<String, dynamic>> teachers) {
    return teachers.where((teachers) {
      final name = teachers['about']['fullName'].toString().toLowerCase();
      final email = teachers['about']['email'].toString().toLowerCase();
      final subject =
          teachers['about']['teachingCourse'].toString().toLowerCase();

      if (_searchQuery.isNotEmpty) {
        if (!name.contains(_searchQuery) &&
            !email.contains(_searchQuery) &&
            !subject.contains(_searchQuery)) {
          return false;
        }
      }

      return teachers['status'] == 'verified';
    }).toList();
  }

  Widget _buildTeacherCard(
      Map<String, dynamic> teachers, String teacherId, int index) {
    final isVerified = teachers['status'] == 'verified';
    final currentUserId = _auth.currentUser?.uid;
    final isCurrentUser = currentUserId == teacherId;

    final statusColor = _verifiedColor;
    final nameInitial = teachers['about']['fullName'].toString().isNotEmpty
        ? teachers['about']['fullName'].toString().substring(0, 1).toUpperCase()
        : 'U';

    return Hero(
      tag: 'teachers-$teacherId',
      child: Material(
        color: Colors.transparent,
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isCurrentUser
                  ? _colorScheme.primary.withOpacity(0.2)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: () => _showTeacherDetails(teachers, teacherId),
            borderRadius: BorderRadius.circular(16),
            splashColor: _colorScheme.primary.withOpacity(0.1),
            highlightColor: _colorScheme.primary.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTeacherAvatar(
                      nameInitial, statusColor, isCurrentUser, teachers),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                teachers['about']['fullName'],
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.grey[900],
                                ),
                              ),
                            ),
                            _buildStatusChip(isVerified),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          teachers['about']['email'],
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        if (teachers['about']['teachingCourse']?.isNotEmpty ??
                            false) ...[
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(
                              teachers['about']['teachingCourse'],
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: _colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor:
                                _colorScheme.primaryContainer.withOpacity(0.7),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isCurrentUser)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Chip(
                                  label: Text(
                                    'You',
                                    style: GoogleFonts.poppins(
                                      color: _colorScheme.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  backgroundColor:
                                      _colorScheme.primaryContainer,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert,
                                color: Colors.grey[600],
                                semanticLabel: 'More options',
                              ),
                              onSelected: (value) {
                                if (value == 'view') {
                                  _showTeacherDetails(teachers, teacherId);
                                } else if (value == 'delete' &&
                                    widget.isAdmin) {
                                  _showDeleteConfirmation(
                                      teacherId, teachers['about']['fullName']);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: _colorScheme.primary,
                                          semanticLabel: 'View Details'),
                                      const SizedBox(width: 8),
                                      Text('View Details',
                                          style: GoogleFonts.poppins()),
                                    ],
                                  ),
                                ),
                                if (widget.isAdmin)
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete,
                                            color: _deleteColor,
                                            semanticLabel: 'Delete'),
                                        const SizedBox(width: 8),
                                        Text('Delete',
                                            style: GoogleFonts.poppins(
                                                color: _deleteColor)),
                                      ],
                                    ),
                                  ),
                              ],
                              splashRadius: 24,
                              tooltip: 'More options',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherAvatar(String nameInitial, Color statusColor,
      bool isCurrentUser, Map<String, dynamic> teachers) {
    final profilePhotoUrl =
        teachers['profilePhoto']['profilePhotoUrl']?.toString() ?? '';
    return Stack(
      children: [
        profilePhotoUrl.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  profilePhotoUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor,
                          statusColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        nameInitial,
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      statusColor,
                      statusColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    nameInitial,
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
        if (isCurrentUser)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color.fromARGB(255, 255, 255, 255), width: 2),
              ),
              child: Icon(
                Icons.person,
                size: 14,
                color: Colors.black,
                semanticLabel: 'Current user',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusChip(bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _verifiedColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _verifiedColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            color: _verifiedColor,
            size: 14,
            semanticLabel: 'Verified',
          ),
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: GoogleFonts.poppins(
              color: _verifiedColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showActionMenu(Map<String, dynamic> teachers, String teacherId) {
    // Removed redundant bottom sheet as PopupMenuButton handles actions
  }

  void _showTeacherDetails(Map<String, dynamic> teachers, String teacherId) {
    final currentUserId = _auth.currentUser?.uid;
    final isCurrentUser = currentUserId == teacherId;
    final nameInitial = teachers['about']['fullName'].toString().isNotEmpty
        ? teachers['about']['fullName'].toString().substring(0, 1).toUpperCase()
        : 'U';
    final statusColor = _verifiedColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Hero(
                            tag: 'teachers-$teacherId',
                            child: teachers['profilePhoto']['profilePhotoUrl']
                                    .isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      teachers['profilePhoto']
                                          ['profilePhotoUrl'],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              statusColor,
                                              statusColor.withOpacity(0.8),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  statusColor.withOpacity(0.4),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            nameInitial,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 36,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          statusColor,
                                          statusColor.withOpacity(0.8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: statusColor.withOpacity(0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        nameInitial,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 36,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            teachers['about']['fullName'],
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _verifiedColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _verifiedColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      color: _verifiedColor,
                                      size: 18,
                                      semanticLabel: 'Verified',
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Verified',
                                      style: GoogleFonts.poppins(
                                        color: _verifiedColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isCurrentUser) ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'You',
                                    style: GoogleFonts.poppins(
                                      color: _colorScheme.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'About',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildDetailItem(
                                'First Name',
                                teachers['about']['firstName'],
                                Icons.person_outline,
                              ),
                              const Divider(height: 32),
                              _buildDetailItem(
                                'Last Name',
                                teachers['about']['lastName'],
                                Icons.person_outline,
                              ),
                              const Divider(height: 32),
                              _buildDetailItem(
                                'Country',
                                teachers['about']['country'],
                                Icons.location_on_outlined,
                              ),
                              const Divider(height: 32),
                              _buildDetailItem(
                                'Email Address',
                                teachers['about']['email'],
                                Icons.email_outlined,
                              ),
                              const Divider(height: 32),
                              _buildDetailItem(
                                'Phone Number',
                                teachers['about']['phoneNumber'],
                                Icons.phone_outlined,
                              ),
                              const Divider(height: 32),
                              _buildDetailItem(
                                'Teaching Course',
                                teachers['about']['teachingCourse'].isEmpty
                                    ? 'Not specified'
                                    : teachers['about']['teachingCourse'],
                                Icons.school_outlined,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Description',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Introduction',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                teachers['description']['intro'],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Experience',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                teachers['description']['experience'],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Motivation',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                teachers['description']['motivation'],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Certifications',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: (teachers['certifications'] as List).isEmpty
                              ? Text(
                                  'No certifications available',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                )
                              : Column(
                                  children: (teachers['certifications']
                                          as List<dynamic>)
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final index = entry.key;
                                    final cert =
                                        entry.value as Map<String, dynamic>;
                                    return Column(
                                      children: [
                                        _buildDetailItem(
                                          'Subject',
                                          cert['subject']?.toString() ??
                                              'Not specified',
                                          Icons.book_outlined,
                                        ),
                                        const Divider(height: 32),
                                        _buildDetailItem(
                                          'Certification',
                                          cert['certification']?.toString() ??
                                              'Not specified',
                                          Icons.verified_outlined,
                                        ),
                                        const Divider(height: 32),
                                        _buildDetailItem(
                                          'Description',
                                          cert['description']?.toString() ??
                                              'Not specified',
                                          Icons.description_outlined,
                                        ),
                                        const Divider(height: 32),
                                        _buildDetailItem(
                                          'Issued By',
                                          cert['issuedBy']?.toString() ??
                                              'Not specified',
                                          Icons.person_outlined,
                                        ),
                                        const Divider(height: 32),
                                        _buildDetailItem(
                                          'Duration',
                                          '${cert['startYear'] ?? 'N/A'} - ${cert['endYear'] ?? 'N/A'}',
                                          Icons.calendar_today_outlined,
                                        ),
                                        if (cert['fileName']
                                                ?.toString()
                                                .isNotEmpty ??
                                            false) ...[
                                          const Divider(height: 32),
                                          _buildDetailItem(
                                            'File',
                                            cert['fileName']?.toString() ?? '',
                                            Icons.attach_file_outlined,
                                          ),
                                        ],
                                        if (index <
                                            (teachers['certifications'] as List)
                                                    .length -
                                                1)
                                          const Divider(height: 32),
                                      ],
                                    );
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Education',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: (teachers['education'] as List).isEmpty
                              ? Text(
                                  'No education details available',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                )
                              : Column(
                                  children:
                                      (teachers['education'] as List<dynamic>)
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                    final index = entry.key;
                                    final edu =
                                        entry.value as Map<String, dynamic>;
                                    return Column(
                                      children: [
                                        _buildDetailItem(
                                          'University',
                                          edu['university']?.toString() ??
                                              'Not specified',
                                          Icons.account_balance_outlined,
                                        ),
                                        const Divider(height: 32),
                                        _buildDetailItem(
                                          'Degree',
                                          edu['degree']?.toString() ??
                                              'Not specified',
                                          Icons.school_outlined,
                                        ),
                                        const Divider(height: 32),
                                        _buildDetailItem(
                                          'Degree Type',
                                          edu['degree_type']?.toString() ??
                                              'Not specified',
                                          Icons.book_outlined,
                                        ),
                                        const Divider(height: 32),
                                        _buildDetailItem(
                                          'Specialization',
                                          edu['specialization']?.toString() ??
                                              'Not specified',
                                          Icons.star_outlined,
                                        ),
                                        const Divider(height: 32),
                                        _buildDetailItem(
                                          'Duration',
                                          '${edu['start_year'] ?? 'N/A'} - ${edu['end_year'] ?? 'N/A'}',
                                          Icons.calendar_today_outlined,
                                        ),
                                        if (edu['file_name']
                                                ?.toString()
                                                .isNotEmpty ??
                                            false) ...[
                                          const Divider(height: 32),
                                          _buildDetailItem(
                                            'File',
                                            edu['file_name']?.toString() ?? '',
                                            Icons.attach_file_outlined,
                                          ),
                                        ],
                                        if (index <
                                            (teachers['education'] as List)
                                                    .length -
                                                1)
                                          const Divider(height: 32),
                                      ],
                                    );
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(height: 32),
                        if (teachers['video']['videoUrl'].isNotEmpty) ...[
                          Text(
                            'Introduction Video',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildDetailItem(
                                  'Video',
                                  'Watch Video',
                                  Icons.video_library_outlined,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Video URL: ${teachers['video']['videoUrl']}',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        backgroundColor: _colorScheme.primary,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        margin: const EdgeInsets.all(16),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                        Text(
                          'Availability',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailItem(
                                'Timezone',
                                teachers['availability']['timezone']
                                        ?.toString() ??
                                    'Not specified',
                                Icons.access_time_outlined,
                              ),
                              const Divider(height: 32),
                              Text(
                                'Available Days',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              (teachers['availability']['days'] as List).isEmpty
                                  ? Text(
                                      'No availability specified',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    )
                                  : Column(
                                      children: (teachers['availability']
                                              ['days'] as List)
                                          .where(
                                              (day) => day['enabled'] == true)
                                          .map<Widget>((day) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                day['days']?.toString() ??
                                                    'Unknown',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: _colorScheme.primary,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              ...(day['slots'] is List
                                                  ? (day['slots'] as List)
                                                      .map<Widget>((slot) {
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                left: 16,
                                                                bottom: 4),
                                                        child: Text(
                                                          '${slot['from'] ?? 'N/A'} - ${slot['to'] ?? 'N/A'}',
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 14,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        ),
                                                      );
                                                    }).toList()
                                                  : []),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Pricing',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildDetailItem(
                                'Standard Rate',
                                teachers['pricing']['standardRate'],
                                Icons.attach_money_outlined,
                              ),
                              const Divider(height: 32),
                              _buildDetailItem(
                                'Introductory Rate',
                                teachers['pricing']['introRate'],
                                Icons.attach_money_outlined,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (widget.isAdmin)
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showDeleteConfirmation(
                                  teacherId, teachers['about']['fullName']);
                            },
                            icon: const Icon(Icons.delete_forever,
                                size: 20,
                                color: Colors.white,
                                semanticLabel: 'Delete Teacher'),
                            label: Text(
                              'Delete Teacher',
                              style: GoogleFonts.poppins(
                                  fontSize: 16, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _deleteColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 24),
                              minimumSize: const Size(double.infinity, 54),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _colorScheme.primaryContainer.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: _colorScheme.primary,
              size: 24,
              semanticLabel: label,
            ),
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String teacherId, String teacherName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Delete Teacher',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: _deleteColor,
              size: 64,
              semanticLabel: 'Warning',
            ),
            const SizedBox(height: 16),
            Text(
              'This action cannot be undone',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to delete $teacherName?',
              style: GoogleFonts.poppins(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTeacher(teacherId, teacherName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _deleteColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  void _deleteTeacher(String teacherId, String teacherName) async {
    try {
      await _showLoadingDialog(context, 'Deleting teacher...', _deleteColor);

      DocumentSnapshot teacherDoc =
          await _firestore.collection('teachers').doc(teacherId).get();
      if (!teacherDoc.exists) {
        throw Exception('Teacher not found');
      }

      Map<String, dynamic>? teacherData =
          teacherDoc.data() as Map<String, dynamic>?;
      if (teacherData == null || teacherData['status'] != 'verified') {
        throw Exception('Teacher is not verified or data is invalid');
      }

      if (_auth.currentUser?.uid == teacherId) {
        await _auth.signOut();
      }

      await _firestore.collection('teachers').doc(teacherId).delete();

      await _firestore
          .collection('users')
          .doc(teacherId)
          .delete()
          .catchError((error) {});

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessSnackBar(
          context,
          '$teacherName deleted successfully',
          Colors.green[600]!,
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorSnackBar(
          context,
          'Failed to delete teacher: ${e.toString()}',
          _colorScheme.error,
        );
      }
    }
  }

  void _showAdminOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: _colorScheme.primary,
                    size: 28,
                    semanticLabel: 'Admin Options',
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Admin Options',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _showLoadingDialog(
      BuildContext context, String message, Color color) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomLoadingDialog(message: message, color: color),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle,
                color: Colors.white, semanticLabel: 'Success'),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white, semanticLabel: 'Error'),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class CustomLoadingDialog extends StatelessWidget {
  final String message;
  final Color color;

  const CustomLoadingDialog(
      {Key? key, required this.message, required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: color),
            const SizedBox(height: 20),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const CustomErrorWidget(
      {Key? key, required this.message, required this.onRetry})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outlined,
              color: Colors.red,
              size: 48,
              semanticLabel: 'Error',
            ),
            const SizedBox(height: 24),
            Text(
              'Error',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, semanticLabel: 'Retry'),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                minimumSize: const Size(200, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomEmptyState extends StatelessWidget {
  final bool isSearchActive;
  final VoidCallback onClearSearch;

  const CustomEmptyState(
      {Key? key, required this.isSearchActive, required this.onClearSearch})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearchActive ? Icons.search_off : Icons.person_off,
              color: Colors.grey[400],
              size: 80,
              semanticLabel:
                  isSearchActive ? 'No search results' : 'No teachers',
            ),
            const SizedBox(height: 24),
            Text(
              isSearchActive ? 'No matching teachers' : 'No teachers found',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isSearchActive
                  ? 'Try adjusting your search terms'
                  : 'No teachers available in this category',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (isSearchActive) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onClearSearch,
                icon: const Icon(Icons.clear, semanticLabel: 'Clear Search'),
                label: Text('Clear Search'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
