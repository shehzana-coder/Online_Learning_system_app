import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // General Settings
  String _platformName = 'Speakora';
  String _supportEmail = 'support@speakora.com';
  String _platformDescription = 'A comprehensive learning platform';
  String _contactPhone = '+1-234-567-8900';
  String _businessAddress = '123 Education Street, Learning City';

  // Notification Settings
  bool _sessionUpdates = true;
  bool _newRegistrations = true;
  bool _systemAlerts = true;
  bool _weeklyReports = false;
  bool _maintenanceNotifications = true;

  // User Management
  bool _autoApproveTeachers = false;
  bool _allowStudentSelfRegistration = true;
  int _maxSessionsPerTeacher = 10;
  int _sessionDurationLimit = 120; // minutes
  bool _requireParentalConsent = true;

  // Security Settings
  bool _requireAdmin2FA = false;
  bool _enforcePasswordComplexity = true;
  int _passwordMinLength = 8;
  int _sessionTimeoutMinutes = 30;
  bool _enableLoginAuditLog = true;
  bool _restrictAdminIPs = false;
  List<String> _allowedIPs = [];

  // System Settings
  bool _maintenanceMode = false;
  String _maintenanceMessage =
      'System under maintenance. Please check back later.';
  bool _enableBackups = true;
  String _backupFrequency = 'daily';
  int _dataRetentionDays = 365;
  bool _enableAnalytics = true;

  // Content Moderation
  bool _enableAutoModeration = true;
  bool _requireContentApproval = false;
  List<String> _bannedWords = [];
  bool _enableReportSystem = true;

  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _bannedWordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _fetchSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ipController.dispose();
    _bannedWordController.dispose();
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    try {
      setState(() => _isLoading = true);

      final doc = await _firestore
          .collection('settings')
          .doc('platform_settings')
          .get();
      if (doc.exists) {
        final data = doc.data()!;

        setState(() {
          // General
          _platformName = data['platformName'] ?? 'Speakora';
          _supportEmail = data['supportEmail'] ?? 'support@speakora.com';
          _platformDescription = data['platformDescription'] ??
              'A comprehensive learning platform';
          _contactPhone = data['contactPhone'] ?? '+1-234-567-8900';
          _businessAddress =
              data['businessAddress'] ?? '123 Education Street, Learning City';

          // Notifications
          _sessionUpdates = data['notifications']?['sessionUpdates'] ?? true;
          _newRegistrations =
              data['notifications']?['newRegistrations'] ?? true;
          _systemAlerts = data['notifications']?['systemAlerts'] ?? true;
          _weeklyReports = data['notifications']?['weeklyReports'] ?? false;
          _maintenanceNotifications =
              data['notifications']?['maintenanceNotifications'] ?? true;

          // User Management
          _autoApproveTeachers = data['autoApproveTeachers'] ?? false;
          _allowStudentSelfRegistration =
              data['allowStudentSelfRegistration'] ?? true;
          _maxSessionsPerTeacher = data['maxSessionsPerTeacher'] ?? 10;
          _sessionDurationLimit = data['sessionDurationLimit'] ?? 120;
          _requireParentalConsent = data['requireParentalConsent'] ?? true;

          // Security
          _requireAdmin2FA = data['requireAdmin2FA'] ?? false;
          _enforcePasswordComplexity =
              data['enforcePasswordComplexity'] ?? true;
          _passwordMinLength = data['passwordMinLength'] ?? 8;
          _sessionTimeoutMinutes = data['sessionTimeoutMinutes'] ?? 30;
          _enableLoginAuditLog = data['enableLoginAuditLog'] ?? true;
          _restrictAdminIPs = data['restrictAdminIPs'] ?? false;
          _allowedIPs = List<String>.from(data['allowedIPs'] ?? []);

          // System
          _maintenanceMode = data['maintenanceMode'] ?? false;
          _maintenanceMessage = data['maintenanceMessage'] ??
              'System under maintenance. Please check back later.';
          _enableBackups = data['enableBackups'] ?? true;
          _backupFrequency = data['backupFrequency'] ?? 'daily';
          _dataRetentionDays = data['dataRetentionDays'] ?? 365;
          _enableAnalytics = data['enableAnalytics'] ?? true;

          // Content Moderation
          _enableAutoModeration = data['enableAutoModeration'] ?? true;
          _requireContentApproval = data['requireContentApproval'] ?? false;
          _bannedWords = List<String>.from(data['bannedWords'] ?? []);
          _enableReportSystem = data['enableReportSystem'] ?? true;
        });
      }
    } catch (e) {
      _showSnackBar('Error loading settings: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isSaving = true);

      final settings = {
        // General
        'platformName': _platformName,
        'supportEmail': _supportEmail,
        'platformDescription': _platformDescription,
        'contactPhone': _contactPhone,
        'businessAddress': _businessAddress,

        // Notifications
        'notifications': {
          'sessionUpdates': _sessionUpdates,
          'newRegistrations': _newRegistrations,
          'systemAlerts': _systemAlerts,
          'weeklyReports': _weeklyReports,
          'maintenanceNotifications': _maintenanceNotifications,
        },

        // User Management
        'autoApproveTeachers': _autoApproveTeachers,
        'allowStudentSelfRegistration': _allowStudentSelfRegistration,
        'maxSessionsPerTeacher': _maxSessionsPerTeacher,
        'sessionDurationLimit': _sessionDurationLimit,
        'requireParentalConsent': _requireParentalConsent,

        // Security
        'requireAdmin2FA': _requireAdmin2FA,
        'enforcePasswordComplexity': _enforcePasswordComplexity,
        'passwordMinLength': _passwordMinLength,
        'sessionTimeoutMinutes': _sessionTimeoutMinutes,
        'enableLoginAuditLog': _enableLoginAuditLog,
        'restrictAdminIPs': _restrictAdminIPs,
        'allowedIPs': _allowedIPs,

        // System
        'maintenanceMode': _maintenanceMode,
        'maintenanceMessage': _maintenanceMessage,
        'enableBackups': _enableBackups,
        'backupFrequency': _backupFrequency,
        'dataRetentionDays': _dataRetentionDays,
        'enableAnalytics': _enableAnalytics,

        // Content Moderation
        'enableAutoModeration': _enableAutoModeration,
        'requireContentApproval': _requireContentApproval,
        'bannedWords': _bannedWords,
        'enableReportSystem': _enableReportSystem,

        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('settings')
          .doc('platform_settings')
          .set(settings, SetOptions(merge: true));

      // Log the update
      await _firestore.collection('admin_logs').add({
        'action': 'settings_updated',
        'adminId': _auth.currentUser?.uid ?? 'unknown',
        'details': 'Admin updated platform settings',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _showSnackBar('Settings saved successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Error saving settings: $e', Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Admin Settings',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 0, 0, 0)),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 144, 187),
        elevation: 0,
        actions: [
          IconButton(
            icon:
                const Icon(Icons.refresh, color: Color.fromARGB(255, 0, 0, 0)),
            onPressed: _fetchSettings,
            tooltip: 'Refresh Settings',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline,
                color: Color.fromARGB(255, 0, 0, 0)),
            onPressed: () => _showHelpDialog(),
            tooltip: 'Help',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color.fromARGB(255, 0, 0, 0),
          labelColor: Color.fromARGB(255, 0, 0, 0),
          unselectedLabelColor: Colors.white70,
          labelStyle:
              GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.business), text: 'General'),
            Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.security), text: 'Security'),
            Tab(icon: Icon(Icons.settings), text: 'System'),
            Tab(icon: Icon(Icons.content_paste), text: 'Content'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 255, 144, 187)))
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGeneralTab(),
                        _buildNotificationsTab(),
                        _buildUserManagementTab(),
                        _buildSecurityTab(),
                        _buildSystemTab(),
                        _buildContentModerationTab(),
                      ],
                    ),
                  ),
                  _buildSaveButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            'Platform Information',
            Icons.info,
            [
              _buildTextField('Platform Name', _platformName,
                  (value) => _platformName = value),
              const SizedBox(height: 16),
              _buildTextField('Platform Description', _platformDescription,
                  (value) => _platformDescription = value,
                  maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField('Support Email', _supportEmail,
                  (value) => _supportEmail = value,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField('Contact Phone', _contactPhone,
                  (value) => _contactPhone = value,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField('Business Address', _businessAddress,
                  (value) => _businessAddress = value,
                  maxLines: 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCard(
            'Email Notifications',
            Icons.email,
            [
              _buildSwitchTile(
                  'Session Updates',
                  'Notify about session status changes',
                  _sessionUpdates,
                  (value) => setState(() => _sessionUpdates = value)),
              _buildSwitchTile(
                  'New Registrations',
                  'Notify about new user registrations',
                  _newRegistrations,
                  (value) => setState(() => _newRegistrations = value)),
              _buildSwitchTile(
                  'System Alerts',
                  'Critical system notifications',
                  _systemAlerts,
                  (value) => setState(() => _systemAlerts = value)),
              _buildSwitchTile(
                  'Weekly Reports',
                  'Weekly analytics reports',
                  _weeklyReports,
                  (value) => setState(() => _weeklyReports = value)),
              _buildSwitchTile(
                  'Maintenance Notifications',
                  'Scheduled maintenance alerts',
                  _maintenanceNotifications,
                  (value) => setState(() => _maintenanceNotifications = value)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserManagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCard(
            'Registration Settings',
            Icons.person_add,
            [
              _buildSwitchTile(
                  'Auto-Approve Teachers',
                  'Automatically approve new teacher registrations',
                  _autoApproveTeachers,
                  (value) => setState(() => _autoApproveTeachers = value)),
              _buildSwitchTile(
                  'Student Self-Registration',
                  'Allow students to register themselves',
                  _allowStudentSelfRegistration,
                  (value) =>
                      setState(() => _allowStudentSelfRegistration = value)),
              _buildSwitchTile(
                  'Require Parental Consent',
                  'Require parental consent for minors',
                  _requireParentalConsent,
                  (value) => setState(() => _requireParentalConsent = value)),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            'Session Limits',
            Icons.schedule,
            [
              _buildNumberField(
                  'Max Sessions per Teacher',
                  _maxSessionsPerTeacher,
                  (value) => _maxSessionsPerTeacher = value),
              const SizedBox(height: 16),
              _buildNumberField(
                  'Session Duration Limit (minutes)',
                  _sessionDurationLimit,
                  (value) => _sessionDurationLimit = value),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCard(
            'Authentication',
            Icons.lock,
            [
              _buildSwitchTile(
                  'Require Admin 2FA',
                  'Enforce two-factor authentication',
                  _requireAdmin2FA,
                  (value) => setState(() => _requireAdmin2FA = value)),
              _buildSwitchTile(
                  'Password Complexity',
                  'Enforce strong passwords',
                  _enforcePasswordComplexity,
                  (value) =>
                      setState(() => _enforcePasswordComplexity = value)),
              _buildNumberField('Minimum Password Length', _passwordMinLength,
                  (value) => _passwordMinLength = value),
              const SizedBox(height: 16),
              _buildNumberField(
                  'Session Timeout (minutes)',
                  _sessionTimeoutMinutes,
                  (value) => _sessionTimeoutMinutes = value),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            'Access Control',
            Icons.admin_panel_settings,
            [
              _buildSwitchTile(
                  'Enable Login Audit Log',
                  'Track all login attempts',
                  _enableLoginAuditLog,
                  (value) => setState(() => _enableLoginAuditLog = value)),
              _buildSwitchTile(
                  'Restrict Admin IPs',
                  'Restrict admin access to specific IPs',
                  _restrictAdminIPs,
                  (value) => setState(() => _restrictAdminIPs = value)),
              if (_restrictAdminIPs) ...[
                const SizedBox(height: 16),
                _buildIPManagement(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCard(
            'Maintenance',
            Icons.build,
            [
              _buildSwitchTile(
                  'Maintenance Mode',
                  'Put system in maintenance mode',
                  _maintenanceMode,
                  (value) => setState(() => _maintenanceMode = value)),
              if (_maintenanceMode) ...[
                const SizedBox(height: 16),
                _buildTextField('Maintenance Message', _maintenanceMessage,
                    (value) => _maintenanceMessage = value,
                    maxLines: 3),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            'Data Management',
            Icons.storage,
            [
              _buildSwitchTile(
                  'Enable Backups',
                  'Automatic system backups',
                  _enableBackups,
                  (value) => setState(() => _enableBackups = value)),
              const SizedBox(height: 16),
              _buildDropdownField(
                  'Backup Frequency',
                  _backupFrequency,
                  ['daily', 'weekly', 'monthly'],
                  (value) => _backupFrequency = value!),
              const SizedBox(height: 16),
              _buildNumberField('Data Retention (days)', _dataRetentionDays,
                  (value) => _dataRetentionDays = value),
              _buildSwitchTile(
                  'Enable Analytics',
                  'Collect usage analytics',
                  _enableAnalytics,
                  (value) => setState(() => _enableAnalytics = value)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentModerationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCard(
            'Moderation Settings',
            Icons.content_paste,
            [
              _buildSwitchTile(
                  'Auto Moderation',
                  'Automatically moderate content',
                  _enableAutoModeration,
                  (value) => setState(() => _enableAutoModeration = value)),
              _buildSwitchTile(
                  'Require Content Approval',
                  'Approve content before publishing',
                  _requireContentApproval,
                  (value) => setState(() => _requireContentApproval = value)),
              _buildSwitchTile(
                  'Enable Report System',
                  'Allow users to report content',
                  _enableReportSystem,
                  (value) => setState(() => _enableReportSystem = value)),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            'Content Filtering',
            Icons.filter_list,
            [
              _buildBannedWordsManagement(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 4,
      shadowColor: Colors.grey[300],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!, width: 1),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon,
                        color: const Color.fromARGB(255, 255, 144, 187),
                        size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String value, Function(String) onChanged,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color.fromARGB(255, 255, 144, 187), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      style: GoogleFonts.poppins(),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (keyboardType == TextInputType.emailAddress &&
            !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
      onChanged: onChanged,
    );
  }

  Widget _buildNumberField(String label, int value, Function(int) onChanged) {
    return TextFormField(
      initialValue: value.toString(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color.fromARGB(255, 255, 144, 187), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      style: GoogleFonts.poppins(),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (int.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
      onChanged: (value) {
        final intValue = int.tryParse(value);
        if (intValue != null) onChanged(intValue);
      },
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> options,
      Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color.fromARGB(255, 255, 144, 187), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      style: GoogleFonts.poppins(color: Colors.black),
      items: options
          .map((option) => DropdownMenuItem(
                value: option,
                child: Text(option.toUpperCase()),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSwitchTile(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1F2937),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF6B7280),
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color.fromARGB(255, 255, 144, 187),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildIPManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Allowed IP Addresses',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ipController,
                decoration: InputDecoration(
                  hintText: 'Enter IP address',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (_ipController.text.isNotEmpty) {
                  setState(() {
                    _allowedIPs.add(_ipController.text);
                    _ipController.clear();
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 144, 187)),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        if (_allowedIPs.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _allowedIPs
                .map((ip) => Chip(
                      label: Text(ip),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => setState(() => _allowedIPs.remove(ip)),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildBannedWordsManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Banned Words',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _bannedWordController,
                decoration: InputDecoration(
                  hintText: 'Enter banned word',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (_bannedWordController.text.isNotEmpty) {
                  setState(() {
                    _bannedWords.add(_bannedWordController.text);
                    _bannedWordController.clear();
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 144, 187)),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        if (_bannedWords.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _bannedWords
                .map((word) => Chip(
                      label: Text(word),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () =>
                          setState(() => _bannedWords.remove(word)),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 144, 187),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          child: _isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  'Save All Settings',
                  style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Settings Help',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Navigate through different tabs to configure platform settings:\n\n'
          '• General: Basic platform information\n'
          '• Notifications: Email notification preferences\n'
          '• Users: User registration and session limits\n'
          '• Security: Authentication and access control\n'
          '• System: Maintenance and data management\n'
          '• Content: Content moderation settings',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it',
                style: GoogleFonts.poppins(
                    color: const Color.fromARGB(255, 255, 144, 187))),
          ),
        ],
      ),
    );
  }
}
