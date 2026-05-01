import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  Color _getPieColor(int index) {
    final colors = [
      Colors.blue[600]!,
      Colors.green[600]!,
      Colors.orange[600]!,
      Colors.purple[600]!,
      Colors.red[600]!,
    ];
    return colors[index % colors.length];
  }

  bool _isLoading = true;
  double _totalRevenue = 0.0;
  double _completionRate = 0.0;
  double _averageRating = 0.0;
  int _totalStudents = 0;
  int _totalTeachers = 0;

  List<Map<String, dynamic>> _studentGrowth = [];
  List<Map<String, dynamic>> _teacherGrowth = [];
  List<Map<String, dynamic>> _topCourses = [];
  List<Map<String, dynamic>> _sessionsData = [];
  List<Map<String, dynamic>> _topTeachers = [];

  String _selectedPeriod = 'Last 30 Days';
  final List<String> _periods = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 3 Months',
    'Last 6 Months',
    'All Time'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAnalytics() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Determine time range
      DateTime? startDate = _getStartDate();

      // Fetch all necessary data
      await Future.wait([
        _fetchSessionsData(startDate),
        _fetchUsersData(startDate),
        _fetchRevenueData(startDate),
        _fetchRatingsData(startDate),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching analytics: $e');
      _showErrorSnackBar('Error loading analytics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime? _getStartDate() {
    switch (_selectedPeriod) {
      case 'Last 7 Days':
        return DateTime.now().subtract(const Duration(days: 7));
      case 'Last 30 Days':
        return DateTime.now().subtract(const Duration(days: 30));
      case 'Last 3 Months':
        return DateTime.now().subtract(const Duration(days: 90));
      case 'Last 6 Months':
        return DateTime.now().subtract(const Duration(days: 180));
      case 'All Time':
        return null;
      default:
        return DateTime.now().subtract(const Duration(days: 30));
    }
  }

  Future<void> _fetchSessionsData(DateTime? startDate) async {
    Query<Map<String, dynamic>> sessionsQuery =
        _firestore.collection('sessions');
    if (startDate != null) {
      sessionsQuery = sessionsQuery.where('dateTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    final sessionsSnapshot = await sessionsQuery.get();

    double revenue = 0.0;
    int completedSessions = 0;
    int totalSessions = sessionsSnapshot.size;
    // ignore: unused_local_variable
    int activeSessions = 0;
    Map<String, int> courseCounts = {};
    Map<String, double> teacherRevenue = {};
    Map<String, List<double>> dailySessions = {};

    for (var doc in sessionsSnapshot.docs) {
      final data = doc.data();
      final status = data['status'] ?? '';
      final price = (data['price'] as num?)?.toDouble() ?? 0.0;
      final course = data['course'] ?? 'Unknown';
      final teacherId = data['teacherId'] ?? 'Unknown';
      final dateTime = (data['dateTime'] as Timestamp?)?.toDate();

      if (status == 'completed') {
        completedSessions++;
        revenue += price;
      }

      if (status == 'active' || status == 'ongoing') {
        activeSessions++;
      }

      courseCounts[course] = (courseCounts[course] ?? 0) + 1;
      teacherRevenue[teacherId] = (teacherRevenue[teacherId] ?? 0) + price;

      if (dateTime != null) {
        final dayKey = DateFormat('yyyy-MM-dd').format(dateTime);
        dailySessions[dayKey] = dailySessions[dayKey] ?? [];
        dailySessions[dayKey]!.add(price);
      }
    }

    // Prepare top courses and teachers
    final topCourses = courseCounts.entries
        .map((e) => {'course': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    final topTeachers = teacherRevenue.entries
        .map((e) => {'teacherId': e.key, 'revenue': e.value})
        .toList()
      ..sort(
          (a, b) => (b['revenue'] as double).compareTo(a['revenue'] as double));

    // Prepare sessions timeline data
    final sessionsData = dailySessions.entries
        .map((e) => {
              'date': e.key,
              'sessions': e.value.length,
              'revenue': e.value.fold<double>(0, (sum, price) => sum + price),
            })
        .toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    setState(() {
      _totalRevenue = revenue;
      _completionRate =
          totalSessions > 0 ? (completedSessions / totalSessions) * 100 : 0;
      _topCourses = topCourses.take(5).toList();
      _topTeachers = topTeachers.take(5).toList();
      _sessionsData = sessionsData.take(30).toList(); // Last 30 data points
    });
  }

  Future<void> _fetchUsersData(DateTime? startDate) async {
    // Fetch students
    Query<Map<String, dynamic>> studentsQuery =
        _firestore.collection('students');
    Query<Map<String, dynamic>> teachersQuery =
        _firestore.collection('teachers');

    if (startDate != null) {
      studentsQuery = studentsQuery.where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      teachersQuery = teachersQuery.where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    final studentsSnapshot = await studentsQuery.get();
    final teachersSnapshot = await teachersQuery.get();

    // Get total counts
    final allStudentsSnapshot = await _firestore.collection('students').get();
    final allTeachersSnapshot = await _firestore.collection('teachers').get();

    // Group growth by time period
    Map<String, int> studentGrowthMap = {};
    Map<String, int> teacherGrowthMap = {};

    final now = DateTime.now();
    int periods = _selectedPeriod == 'Last 7 Days'
        ? 7
        : _selectedPeriod == 'Last 30 Days'
            ? 30
            : _selectedPeriod == 'Last 3 Months'
                ? 90
                : _selectedPeriod == 'Last 6 Months'
                    ? 180
                    : 365;

    for (int i = 0; i < periods; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      studentGrowthMap[dateKey] = 0;
      teacherGrowthMap[dateKey] = 0;
    }

    for (var doc in studentsSnapshot.docs) {
      final createdAt = (doc['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(createdAt);
        if (studentGrowthMap.containsKey(dateKey)) {
          studentGrowthMap[dateKey] = studentGrowthMap[dateKey]! + 1;
        }
      }
    }

    for (var doc in teachersSnapshot.docs) {
      final createdAt = (doc['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(createdAt);
        if (teacherGrowthMap.containsKey(dateKey)) {
          teacherGrowthMap[dateKey] = teacherGrowthMap[dateKey]! + 1;
        }
      }
    }

    setState(() {
      _totalStudents = allStudentsSnapshot.size;
      _totalTeachers = allTeachersSnapshot.size;
      _studentGrowth = studentGrowthMap.entries
          .map((e) => {'date': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
      _teacherGrowth = teacherGrowthMap.entries
          .map((e) => {'date': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    });
  }

  Future<void> _fetchRevenueData(DateTime? startDate) async {
    // This would be similar to sessions data but focused on revenue trends
    // Implementation would depend on your specific revenue tracking needs
  }

  Future<void> _fetchRatingsData(DateTime? startDate) async {
    Query<Map<String, dynamic>> ratingsQuery = _firestore.collection('ratings');
    if (startDate != null) {
      ratingsQuery = ratingsQuery.where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    final ratingsSnapshot = await ratingsQuery.get();
    double totalRating = 0.0;
    int ratingCount = 0;

    for (var doc in ratingsSnapshot.docs) {
      final rating = (doc['rating'] as num?)?.toDouble() ?? 0.0;
      totalRating += rating;
      ratingCount++;
    }

    setState(() {
      _averageRating = ratingCount > 0 ? totalRating / ratingCount : 0.0;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingWidget() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Analytics Dashboard',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey[800],
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _fetchAnalytics,
          tooltip: 'Refresh Data',
        ),
        const SizedBox(width: 8),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: Color.fromARGB(255, 255, 144, 187),
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Color.fromARGB(255, 255, 144, 187),
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Revenue'),
          Tab(text: 'Users'),
          Tab(text: 'Courses'),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.blue[600],
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading analytics...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildPeriodFilter(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildRevenueTab(),
              _buildUsersTab(),
              _buildCoursesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.filter_list, color: Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Text(
            'Time Period:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  items: _periods
                      .map((period) => DropdownMenuItem(
                            value: period,
                            child: Text(
                              period,
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPeriod = value!;
                      _fetchAnalytics();
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsGrid(),
          const SizedBox(height: 24),
          _buildQuickInsights(),
          const SizedBox(height: 24),
          _buildRecentActivityChart(),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildMetricCard(
          title: 'Total Revenue',
          value: '\$${_totalRevenue.toStringAsFixed(0)}',
          icon: Icons.monetization_on_rounded,
          color: Colors.green,
          subtitle: 'From completed sessions',
          trend: '+12%',
        ),
        _buildMetricCard(
          title: 'Completion Rate',
          value: '${_completionRate.toStringAsFixed(1)}%',
          icon: Icons.check_circle_rounded,
          color: Colors.blue,
          subtitle: 'Session success rate',
          trend: '+3.2%',
        ),
        _buildMetricCard(
          title: 'Active Users',
          value: '${_totalStudents + _totalTeachers}',
          icon: Icons.people_rounded,
          color: Colors.orange,
          subtitle: '$_totalStudents students, $_totalTeachers teachers',
          trend: '+8%',
        ),
        _buildMetricCard(
          title: 'Average Rating',
          value: _averageRating.toStringAsFixed(1),
          icon: Icons.star_rounded,
          color: Colors.amber,
          subtitle: 'User satisfaction',
          trend: '+0.3',
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    String? trend,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (trend != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      trend,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey[500],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInsights() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 255, 144, 187),
            Color.fromARGB(255, 255, 144, 187)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'Quick Insights',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightItem('Peak activity hours: 2-4 PM', Icons.schedule),
          _buildInsightItem(
              'Most popular subject: Mathematics', Icons.calculate),
          _buildInsightItem('Average session duration: 45 min', Icons.timer),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _sessionsData.isEmpty
                ? Center(
                    child: Text(
                      'No activity data available',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[200],
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= _sessionsData.length) {
                                return const SizedBox();
                              }
                              final date =
                                  DateTime.parse(_sessionsData[index]['date']);
                              return Text(
                                DateFormat('MM/dd').format(date),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _sessionsData.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              (entry.value['sessions'] as int).toDouble(),
                            );
                          }).toList(),
                          isCurved: true,
                          color: Colors.blue[600],
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue[600]!.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildUserGrowthChart(),
          const SizedBox(height: 24),
          _buildUserStats(),
        ],
      ),
    );
  }

  Widget _buildUserGrowthChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Growth Trends',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _studentGrowth.isEmpty
                ? Center(
                    child: Text(
                      'No growth data available',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[200],
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= _studentGrowth.length) {
                                return const SizedBox();
                              }
                              final date =
                                  DateTime.parse(_studentGrowth[index]['date']);
                              return Text(
                                DateFormat('MM/dd').format(date),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _studentGrowth.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              (entry.value['count'] as int).toDouble(),
                            );
                          }).toList(),
                          isCurved: true,
                          color: Colors.blue[600],
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue[600]!.withOpacity(0.1),
                          ),
                        ),
                        LineChartBarData(
                          spots: _teacherGrowth.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              (entry.value['count'] as int).toDouble(),
                            );
                          }).toList(),
                          isCurved: true,
                          color: Colors.green[600],
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.green[600]!.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Students',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Teachers',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.school, size: 40, color: Colors.blue[600]),
                const SizedBox(height: 12),
                Text(
                  '$_totalStudents',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Total Students',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.person, size: 40, color: Colors.green[600]),
                const SizedBox(height: 12),
                Text(
                  '$_totalTeachers',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  'Total Teachers',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoursesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCoursesChart(),
          const SizedBox(height: 24),
          _buildTopCoursesList(),
        ],
      ),
    );
  }

  Widget _buildCoursesChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Popularity Distribution',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _topCourses.isEmpty
                ? Center(
                    child: Text(
                      'No course data available',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sections: _topCourses.asMap().entries.map((entry) {
                        final index = entry.key;
                        final course = entry.value;
                        return PieChartSectionData(
                          color: _getPieColor(index),
                          value: (course['count'] as int).toDouble(),
                          title: '${(course['count'] as int)}',
                          radius: 80,
                          titleStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 4,
                      centerSpaceRadius: 60,
                      startDegreeOffset: -90,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: _topCourses.asMap().entries.map((entry) {
              final index = entry.key;
              final course = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getPieColor(index),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    course['course'],
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCoursesList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Courses by Enrollment',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _topCourses.isEmpty
              ? Center(
                  child: Text(
                    'No course data available',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _topCourses.length,
                  itemBuilder: (context, index) {
                    final course = _topCourses[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getPieColor(index).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: _getPieColor(index),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course['course'],
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${course['count']} enrollments',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getPieColor(index).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${course['count']}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: _getPieColor(index),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildRevenueChart(),
          const SizedBox(height: 24),
          _buildTopTeachers(),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Trends',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _sessionsData.isEmpty
                ? Center(
                    child: Text(
                      'No revenue data available',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[200],
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '\$${value.toInt()}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= _sessionsData.length) {
                                return const SizedBox();
                              }
                              final date =
                                  DateTime.parse(_sessionsData[index]['date']);
                              return Text(
                                DateFormat('MM/dd').format(date),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _sessionsData.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              (entry.value['revenue'] as double),
                            );
                          }).toList(),
                          isCurved: true,
                          color: Colors.green[600],
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.green[600]!.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTeachers() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Earning Teachers',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _topTeachers.isEmpty
              ? Center(
                  child: Text(
                    'No teacher data available',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _topTeachers.length,
                  itemBuilder: (context, index) {
                    final teacher = _topTeachers[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blue[100],
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Teacher ${teacher['teacherId']}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Revenue Generated',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${(teacher['revenue'] as double).toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
