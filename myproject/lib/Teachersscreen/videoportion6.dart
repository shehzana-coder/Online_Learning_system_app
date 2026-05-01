import 'dart:async';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:convert';
import 'descriptionscreen5.dart';
import 'availability7.dart'; // Adjust import path as needed

class VideoUploadScreen extends StatefulWidget {
  final String id;
  const VideoUploadScreen({super.key, required this.id});

  @override
  State<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  PlatformFile? videoFile;
  String? videoPath;
  bool isUploading = false;
  bool isLoading = false;
  String? userEmail;
  String? existingVideoUrl;
  String? existingVideoName;
  bool hasVideoChanged = false;
  bool hasExistingVideo = false;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userEmail = prefs.getString('email') ?? 'user_${widget.id}@example.com';
    await _loadLocalCache();
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final videoJson = prefs.getString('video');
      if (videoJson != null) {
        final data = jsonDecode(videoJson);
        if (mounted) {
          setState(() {
            existingVideoUrl = data['video_url'];
            existingVideoName = data['video_name'];
            hasExistingVideo =
                existingVideoUrl != null && existingVideoName != null;
          });
        }
      }
    } catch (e) {
      print('Error loading video data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading video data: $e',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
    }
  }

  Future<void> _saveToLocalCache(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      data['last_sync'] = DateTime.now().toIso8601String();
      await prefs.setString('video', jsonEncode(data));
    } catch (e) {
      print('Error saving video data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving video data: $e',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
    }
  }

  bool _hasValidVideo() {
    return (videoFile != null && videoPath != null) ||
        (hasExistingVideo && !hasVideoChanged);
  }

  Future<void> _selectVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov'],
        allowMultiple: false,
      );

      if (result != null) {
        final file = File(result.files.first.path!);
        final fileSizeInBytes = await file.length();
        final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        if (fileSizeInMB > 100) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Video size exceeds 100MB limit',
                    style:
                        GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                backgroundColor: const Color.fromARGB(255, 0, 0, 0),
              ),
            );
          }
          return;
        }

        if (mounted) {
          setState(() {
            videoFile = result.files.first;
            videoPath = result.files.first.path;
            hasVideoChanged = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting video: $e',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _uploadVideo() async {
    if (videoFile == null || videoPath == null) return null;

    setState(() {
      isUploading = true;
    });

    try {
      final file = File(videoPath!);
      if (!await file.exists()) {
        throw Exception('Selected video file does not exist');
      }

      final storageRef = FirebaseStorage.instance.ref().child(
          'teacher_videos/${widget.id}/${DateTime.now().millisecondsSinceEpoch}_${videoFile!.name}');
      await storageRef.putFile(file).timeout(const Duration(seconds: 60));

      final videoUrl = await storageRef.getDownloadURL();

      return {
        'video_url': videoUrl,
        'video_name': videoFile!.name,
        'upload_timestamp': DateTime.now().toIso8601String(),
        'file_size': videoFile!.size,
      };
    } on TimeoutException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload timed out: $e',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
      return null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  Future<void> _handleBackNavigation() async {
    if (hasVideoChanged && videoFile != null && videoPath != null) {
      try {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Row(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 20),
                    Text("Saving video...",
                        style: GoogleFonts.poppins(
                            color: Colors.black, fontSize: 12)),
                  ],
                ),
              );
            },
          );
        }

        final uploadResult = await _uploadVideo();

        if (uploadResult != null) {
          await _saveToLocalCache({
            'video_url': uploadResult['video_url'],
            'video_name': uploadResult['video_name'],
          });

          if (mounted) {
            setState(() {
              existingVideoUrl = uploadResult['video_url'] as String;
              existingVideoName = uploadResult['video_name'] as String;
              hasExistingVideo = true;
              hasVideoChanged = false;
            });
          }
        }

        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) Navigator.of(context).pop();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving video: $e',
                  style:
                      GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
              backgroundColor: const Color.fromARGB(255, 0, 0, 0),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleSaveAndContinue() async {
    if (isUploading) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please wait for the video upload to complete',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
      return;
    }

    if (!_hasValidVideo()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a video to upload',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      Map<String, dynamic> videoData = {
        'teacher_id': widget.id,
        'completed': true,
        'section_completed_at': DateTime.now().toIso8601String(),
      };

      if (hasVideoChanged && videoFile != null && videoPath != null) {
        final uploadResult = await _uploadVideo();
        if (uploadResult != null) {
          videoData.addAll({
            'video_url': uploadResult['video_url'],
            'video_name': uploadResult['video_name'],
          });

          await _saveToLocalCache({
            'video_url': uploadResult['video_url'],
            'video_name': uploadResult['video_name'],
          });

          if (mounted) {
            setState(() {
              existingVideoUrl = uploadResult['video_url'] as String;
              existingVideoName = uploadResult['video_name'] as String;
              hasExistingVideo = true;
              hasVideoChanged = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              isUploading = false;
            });
          }
          return;
        }
      } else if (hasExistingVideo) {
        videoData.addAll({
          'video_url': existingVideoUrl,
          'video_name': existingVideoName,
        });
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AvailabilityScreen(id: widget.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving data: $e',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _handleBackNavigation();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white, // Changed background color to white
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            elevation: 0.5,
            flexibleSpace: Padding(
              padding: const EdgeInsets.only(top: 30, left: 16, right: 16),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Video section",
                      style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    const SizedBox(height: 4),
                    Container(
                        height: 1,
                        width: 550,
                        color: const Color.fromARGB(255, 255, 144, 187)),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      "Record your video and upload it below. This video will be shown to your students to know about you.",
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: isUploading ? null : _selectVideo,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: isUploading
                                  ? Colors.grey.shade300
                                  : Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                          color: isUploading
                              ? Colors.grey.shade50
                              : Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isUploading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.pink)),
                              ),
                            if (isUploading) const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isUploading
                                    ? "Uploading video, please wait..."
                                    : videoFile != null
                                        ? "   Video selected: ${videoFile!.name}"
                                        : hasExistingVideo
                                            ? "Video uploaded: $existingVideoName"
                                            : "     Upload here.....",
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: isUploading
                                        ? Colors.grey
                                        : Colors.black54),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              videoFile != null || hasExistingVideo
                                  ? Icons.check_circle
                                  : Icons.upload_outlined,
                              size: 24,
                              color: videoFile != null || hasExistingVideo
                                  ? Colors.green
                                  : (isUploading
                                      ? Colors.grey
                                      : Colors.black54),
                            ),
                            const SizedBox(width: 16),
                          ],
                        ),
                      ),
                    ),
                    if (hasExistingVideo && !hasVideoChanged)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "You've already uploaded a video. Select a new one to replace it or continue.",
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600]),
                        ),
                      ),
                    if (hasVideoChanged)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "New video selected. It will replace your existing video when you save.",
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: const Color.fromARGB(255, 135, 129, 129)),
                        ),
                      ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 80,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 255, 144, 187),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Colors.black),
                              ),
                            ),
                            onPressed: isUploading
                                ? null
                                : () async {
                                    await _handleBackNavigation();
                                    if (mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProfileDescriptionScreen(
                                                  id: widget.id),
                                        ),
                                      );
                                    }
                                  },
                            child: Text(
                              "Back",
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isUploading ? Colors.grey : Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 180,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (isUploading ||
                                      (!_hasValidVideo()))
                                  ? Colors.grey.shade300
                                  : const Color.fromARGB(255, 255, 144, 187),
                              foregroundColor:
                                  (isUploading || (!_hasValidVideo()))
                                      ? Colors.grey.shade600
                                      : Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                    color: (isUploading || (!_hasValidVideo()))
                                        ? Colors.grey.shade400
                                        : Colors.black),
                              ),
                            ),
                            onPressed: (isUploading || (!_hasValidVideo()))
                                ? null
                                : () => _handleSaveAndContinue(),
                            child: isUploading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.black),
                                  )
                                : Text(
                                    "Save and continue",
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    if (!_hasValidVideo() && !isUploading)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Select a video to continue",
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up temporary file if it wasn't uploaded
    if (videoPath != null && hasVideoChanged) {
      try {
        File(videoPath!).deleteSync();
      } catch (e) {
        print('Error deleting temporary video file: $e');
      }
    }
    super.dispose();
  }
}
