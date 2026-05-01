import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'homescreen.dart';

class BookingSessionScreen extends StatefulWidget {
  final String tutorId;
  final DateTime date;
  final String time;
  final int duration;
  final Map<String, dynamic>? tutorDetails;

  const BookingSessionScreen({
    Key? key,
    required this.tutorId,
    required this.date,
    required this.time,
    required this.duration,
    this.tutorDetails,
  }) : super(key: key);

  @override
  State<BookingSessionScreen> createState() => _BookingSessionScreenState();
}

class _BookingSessionScreenState extends State<BookingSessionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _tutorDetails;
  bool _isLoading = true;
  String? _errorMessage;
  File? _selectedFile;
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _fetchTutorDetails();
  }

  Future<void> _fetchTutorDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      DocumentSnapshot doc =
          await _firestore.collection('teachers').doc(widget.tutorId).get();

      if (doc.exists) {
        _tutorDetails = doc.data() as Map<String, dynamic>? ?? {};
        final about = _tutorDetails?['about'] as Map<String, dynamic>? ?? {};

        // Get all tutor information in the correct format
        _tutorDetails?['about'] = {
          'firstName': about['firstName'] ?? 'Unknown',
          'lastName': about['lastName'] ?? '',
          'country': about['country'] ?? 'PK',
          'teachingCourse': about['teachingCourse'] ?? 'Not specified',
        };

        // Get teacher email directly from document
        _tutorDetails?['email'] = _tutorDetails?['email'] ?? 'No email';

        // Pricing information
        final pricing =
            _tutorDetails?['pricing'] as Map<String, dynamic>? ?? {};
        _tutorDetails?['pricing'] = {
          'standardRate': pricing['standardRate']?.toDouble() ?? 15.0,
          'introRate': pricing['introRate']?.toDouble() ?? 7.50,
        };

        print('Fetched tutor details: $_tutorDetails');
      } else {
        _errorMessage = 'No teacher document found for ID: ${widget.tutorId}';
        print('Document does not exist for tutorId: ${widget.tutorId}');
      }
    } catch (e) {
      _errorMessage = 'Failed to load tutor details: $e';
      print('Error fetching tutor details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null &&
          result.files.isNotEmpty &&
          result.files.single.path != null) {
        if (mounted) {
          setState(() {
            _selectedFile = File(result.files.single.path!);
          });
        }
      }
    } catch (e) {
      print("Error picking file: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
    }
  }

  Future<void> _confirmBooking() async {
    try {
      if (_selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please upload a payment screenshot',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Just set the confirmation state
      if (mounted) {
        setState(() {
          _isConfirmed = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Session confirmed! Click "Book Trial" to complete booking.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to confirm: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchTutorDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 144, 187),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final about = _tutorDetails?['about'] ?? {};
    final firstName = about['firstName'] ?? about['firsName'] ?? 'Unknown';
    final lastName = about['lastName'] ?? about['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final countryCode = _tutorDetails?['about']['country'] ?? 'PK';
    // Multiply standardRate by 2 for 60 min session
    if (widget.duration == 60 && _tutorDetails?['pricing'] != null) {
      _tutorDetails!['pricing']['standardRate'] =
          (_tutorDetails!['pricing']['standardRate']?.toDouble() ?? 15.0) * 2;
    }
    final course = _tutorDetails?['about']['teachingCourse'] ?? 'Not specified';
    final profilePhotoUrl =
        _tutorDetails?['profilePhoto']['profilePhotoUrl'] ?? '';
    final pricing = _tutorDetails?['pricing'] ?? {};
    final price = widget.duration == 60
        ? (pricing['standardRate']?.toDouble() ?? 15.0)
        : (pricing['standardRate']?.toDouble() ?? 7.50);
    const processingFee = 0.43;
    final total = price + processingFee;

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: Text(
                'Booking session with $fullName',
                style: GoogleFonts.poppins(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              pinned: true,
              floating: true,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1.0),
                child: Container(
                  color: Colors.grey.shade300,
                  height: 1.0,
                ),
              ),
              titleSpacing: 16.0,
              toolbarHeight: 90,
              flexibleSpace: const Padding(
                padding: EdgeInsets.only(top: 24.0),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: SizedBox(),
                ),
              ),
            ),
          ];
        },
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTutorInfo(profilePhotoUrl, fullName, countryCode, course,
                  price), // Pass specific fields
              const SizedBox(height: 20),
              _buildSessionInfo(),
              const SizedBox(height: 24),
              _buildOrderSection(price, processingFee, total),
              const SizedBox(height: 24),
              _buildCancellationPolicy(),
              const SizedBox(height: 24),
              _buildPaymentMethod(),
              const SizedBox(height: 24),
              _buildScreenshotUpload(),
              const SizedBox(height: 30),
              _buildConfirmSection(context),
              const SizedBox(height: 30),
              _buildLearnerReviewsSection(),
              const SizedBox(height: 30),
              _buildAddDetailsButton(context),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorInfo(String profilePhotoUrl, String fullName,
      String countryCode, String course, double price) {
    final about = _tutorDetails?['about'] ?? {};
    final tutorName = '${about['firstName']} ${about['lastName']}'.trim();

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: profilePhotoUrl.isNotEmpty
              ? Image.network(
                  profilePhotoUrl,
                  width: 100,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildProfileAvatar(tutorName);
                  },
                )
              : _buildProfileAvatar(tutorName),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    tutorName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _getCountryFlag(countryCode),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.verified_user,
                    size: 14,
                    color: Color.fromARGB(255, 255, 144, 187),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                course,
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        '4.5',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                '${widget.duration} min lesson',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar(String fullName) {
    String initials = fullName.isNotEmpty
        ? fullName.trim().split(' ').map((name) => name[0]).take(2).join()
        : 'U';
    return Container(
      width: 100,
      height: 90,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 144, 187),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSessionInfo() {
    final course = _tutorDetails?['about']['teachingCourse'] ?? 'Not specified';
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(widget.date);
    final endTime = DateFormat('h:mm a').format(DateFormat('h:mm a')
        .parse(widget.time)
        .add(Duration(minutes: widget.duration)));
    final about = _tutorDetails?['about'] ?? {};
    final firstName = about['firstName'] ?? about['firstName'] ?? 'Unknown';
    final lastName = about['lastName'] ?? about['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$course with $fullName',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$formattedDate at ${widget.time} - $endTime',
          style: GoogleFonts.poppins(
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSection(double price, double processingFee, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your order',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: widget.duration == 30
                      ? const Color.fromARGB(255, 255, 144, 187)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.duration == 30
                        ? const Color.fromARGB(255, 255, 144, 187)
                        : Colors.grey.shade200,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '30 min',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.duration == 30 ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: widget.duration == 60
                      ? const Color.fromARGB(255, 255, 144, 187)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.duration == 60
                        ? const Color.fromARGB(255, 255, 144, 187)
                        : Colors.grey.shade200,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '60 min',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.duration == 60 ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.duration} min session ',
              style: GoogleFonts.poppins(
                fontSize: 16,
              ),
            ),
            Text(
              '\$${price.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Processing fee',
              style: GoogleFonts.poppins(
                fontSize: 16,
              ),
            ),
            Text(
              '\$${processingFee.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(thickness: 1),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCancellationPolicy() {
    final cancellationDate = widget.date.subtract(const Duration(days: 1));
    final formattedCancellationDate =
        DateFormat('EEEE, MMMM d, yyyy').format(cancellationDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.access_time,
                color: Color.fromARGB(255, 255, 144, 187),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Free cancellation',
                style: GoogleFonts.poppins(
                  color: const Color.fromARGB(255, 255, 144, 187),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'If you want to cancel or reschedule the session, you can do it for free until 08:00 AM on $formattedCancellationDate.',
            style: GoogleFonts.poppins(
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    final accountNumber =
        _tutorDetails?['payment']?['accountNumber'] ?? '+92 344 3454123';
    final accountType =
        _tutorDetails?['payment']?['accountType'] ?? 'Nayapay, Sadapay';
    final accountName =
        _tutorDetails?['payment']?['accountName'] ?? 'Shehzana Ishaq';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment method',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Account Details:',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        _buildPaymentDetailRow('Account number', accountNumber),
        _buildPaymentDetailRow('Account', accountType),
        _buildPaymentDetailRow('Account name', accountName),
      ],
    );
  }

  Widget _buildPaymentDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotUpload() {
    return GestureDetector(
        onTap: _pickFile,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 8), // padding to the text from left
                  child: Text(
                    _selectedFile != null
                        ? _selectedFile!.path.split('/').last.length > 20
                            ? '${_selectedFile!.path.split('/').last.substring(0, 17)}...'
                            : _selectedFile!.path.split('/').last
                        : 'Add your screenshot here',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    right: 4), // padding to the icon from right boundary
                child: Icon(
                  Icons.upload_file,
                  color: Colors.grey.shade700,
                  size: 20,
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildConfirmSection(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _selectedFile != null ? _confirmBooking : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedFile != null
                  ? const Color.fromARGB(255, 255, 144, 187)
                  : Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: _selectedFile != null
                  ? const BorderSide(color: Colors.black)
                  : BorderSide.none,
            ),
            child: Text(
              'Confirm',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: _selectedFile != null ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black,
            ),
            children: [
              const TextSpan(
                  text: 'By clicking on confirm, you agree to speakora '),
              TextSpan(
                text: 'Refund & Payment Policy.',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLearnerReviewsSection() {
    final fullName = _tutorDetails?['about']['fullName'] ?? 'Unknown Tutor';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What learners say about us',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildReviewCard(
                name: 'Rohit',
                countryCode: 'IN',
                daysAgo: 3,
                rating: 5,
                reviewText:
                    'Learning with $fullName has been an amazing experience! They explain everything clearly and make difficult topics easy to understand.',
              ),
              const SizedBox(width: 12),
              _buildReviewCard(
                name: 'Faryal',
                countryCode: 'PK',
                daysAgo: 5,
                rating: 5,
                reviewText:
                    'Learning with $fullName has been an amazing experience! They explain everything clearly and make difficult topics easy to understand.',
                profileImage: 'assets/images/5.png',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard({
    required String name,
    required String countryCode,
    required int daysAgo,
    required int rating,
    required String reviewText,
    String profileImage = 'assets/images/2.png',
  }) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage(profileImage),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _getCountryFlag(countryCode),
                    ],
                  ),
                  Text(
                    '$daysAgo days ago',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              rating,
              (index) => const Icon(Icons.star, color: Colors.amber, size: 16),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reviewText,
            style: GoogleFonts.poppins(
              fontSize: 14,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            'Read more',
            style: GoogleFonts.poppins(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCountryFlag(String countryCode) {
    Color flagColor;
    switch (countryCode.toUpperCase()) {
      case 'US':
        flagColor = Colors.blue;
        break;
      case 'UK':
        flagColor = Colors.red;
        break;
      case 'IN':
        flagColor = Colors.orange;
        break;
      case 'PK':
        flagColor = const Color.fromARGB(255, 255, 144, 187);
        break;
      default:
        flagColor = const Color.fromARGB(255, 255, 144, 187); // Default color
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: flagColor,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        countryCode.toUpperCase(),
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

// Update the _submitBooking method with working navigation
  Future<void> _submitBooking() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please log in to book a session',
                style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get tutor information
      final about = _tutorDetails?['about'] ?? {};
      final tutorName = '${about['firstName']} ${about['lastName']}'.trim();
      final tutorEmail = _tutorDetails?['email'] ?? 'No email';
      final course = about['teachingCourse'] ?? 'Not specified';
      final pricing = _tutorDetails?['pricing'] ?? {};
      final price = widget.duration == 60
          ? (pricing['standardRate']?.toDouble() ?? 15.0)
          : (pricing['introRate']?.toDouble() ?? 7.50);

      // Upload file if exists
      String? fileUrl;
      if (_selectedFile != null) {
        final storageRef = FirebaseStorage.instance.ref().child(
            'payment_screenshots/${user.uid}_${DateTime.now().millisecondsSinceEpoch}');
        await storageRef.putFile(_selectedFile!);
        fileUrl = await storageRef.getDownloadURL();
      }

      // Create booking document
      await _firestore.collection('sessions').add({
        'tutorId': widget.tutorId,
        'tutorName': tutorName,
        'tutorEmail': tutorEmail,
        'studentId': user.uid,
        'studentName': user.displayName ?? 'No name',
        'studentEmail': user.email ?? 'No email',
        'languageCourse': course,
        'date': Timestamp.fromDate(widget.date),
        'time': widget.time,
        'duration': widget.duration,
        'price': price,
        'paymentScreenshotUrl': fileUrl,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session booked successfully!',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error submitting booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to book session: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Update the Book Trial button to ensure it's properly connected
  Widget _buildAddDetailsButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const TutorScreen()),
            (route) => false,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _isConfirmed
              ? const Color.fromARGB(255, 255, 144, 187)
              : Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Book Trial',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _isConfirmed ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }
}
