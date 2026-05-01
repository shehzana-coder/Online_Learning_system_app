import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String tutorName;
  final bool isAssetVideo; // Flag to indicate if video is an asset

  const VideoPlayerScreen({
    Key? key,
    required this.videoUrl,
    required this.tutorName,
    this.isAssetVideo = false, // Default to false (network video)
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      // Initialize video player with the provided URL or asset
      if (widget.isAssetVideo) {
        _videoPlayerController = VideoPlayerController.asset(widget.videoUrl);
      } else {
        _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
      }

      // Wait for initialization to complete
      await _videoPlayerController.initialize();

      // Add listener to update UI when video state changes
      _videoPlayerController.addListener(_videoPlayerListener);

      // Only update state if the widget is still mounted
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });

        // Start playing the video after initialization
        _playVideo();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error loading video: $e";
        });
        print("Video player error: $e");
      }
    }
  }

  void _playVideo() {
    if (_isVideoInitialized && mounted) {
      _videoPlayerController.play().then((_) {
        if (mounted) {
          setState(() {
            _isPlaying = true;
          });
        }
      }).catchError((error) {
        print("Error playing video: $error");
        if (mounted) {
          setState(() {
            _errorMessage = "Error playing video: $error";
          });
        }
      });
    }
  }

  void _videoPlayerListener() {
    // Update UI when video finishes
    if (_videoPlayerController.value.position >=
        _videoPlayerController.value.duration) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }

    // Ensure UI updates if play state changes
    if (_videoPlayerController.value.isPlaying != _isPlaying && mounted) {
      setState(() {
        _isPlaying = _videoPlayerController.value.isPlaying;
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.removeListener(_videoPlayerListener);
    _videoPlayerController.dispose();
    super.dispose();
  }

  // Toggle play/pause
  void _togglePlayPause() {
    if (_isVideoInitialized) {
      setState(() {
        if (_videoPlayerController.value.isPlaying) {
          _videoPlayerController.pause();
          _isPlaying = false;
        } else {
          _videoPlayerController.play();
          _isPlaying = true;
        }
      });
    }
  }

  // Format duration from seconds to mm:ss
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "${widget.tutorName}'s Introduction",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: _errorMessage != null
            ? Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              )
            : _isVideoInitialized
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Main video player
                      AspectRatio(
                        aspectRatio: _videoPlayerController.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Video
                            GestureDetector(
                              onTap: _togglePlayPause,
                              child: VideoPlayer(_videoPlayerController),
                            ),

                            // Play/Pause overlay
                            if (!_isPlaying)
                              GestureDetector(
                                onTap: _togglePlayPause,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Video controls
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        color: Colors.black,
                        child: Column(
                          children: [
                            // Progress bar
                            ValueListenableBuilder(
                              valueListenable: _videoPlayerController,
                              builder:
                                  (context, VideoPlayerValue value, child) {
                                return Column(
                                  children: [
                                    Slider(
                                      value: value.position.inMilliseconds
                                          .toDouble(),
                                      min: 0.0,
                                      max: value.duration.inMilliseconds
                                          .toDouble(),
                                      activeColor: const Color.fromARGB(
                                          255, 255, 144, 187),
                                      inactiveColor: Colors.grey[700],
                                      onChanged: (newPosition) {
                                        _videoPlayerController.seekTo(
                                          Duration(
                                              milliseconds:
                                                  newPosition.toInt()),
                                        );
                                      },
                                    ),

                                    // Time indicators
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDuration(value.position),
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                          Text(
                                            _formatDuration(value.duration),
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            // Controls buttons
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Rewind button
                                  IconButton(
                                    icon: const Icon(Icons.replay_10,
                                        color: Colors.white, size: 32),
                                    onPressed: () {
                                      final newPosition = _videoPlayerController
                                              .value.position -
                                          const Duration(seconds: 10);
                                      _videoPlayerController
                                          .seekTo(newPosition);
                                    },
                                  ),

                                  // Play/Pause button
                                  IconButton(
                                    icon: Icon(
                                      _isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                    onPressed: _togglePlayPause,
                                  ),

                                  // Forward button
                                  IconButton(
                                    icon: const Icon(Icons.forward_10,
                                        color: Colors.white, size: 32),
                                    onPressed: () {
                                      final newPosition = _videoPlayerController
                                              .value.position +
                                          const Duration(seconds: 10);
                                      _videoPlayerController
                                          .seekTo(newPosition);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
      ),
      floatingActionButton:
          _isVideoInitialized && !_videoPlayerController.value.isPlaying
              ? FloatingActionButton(
                  backgroundColor: const Color.fromARGB(255, 255, 144, 187),
                  onPressed: _playVideo,
                  child: const Icon(Icons.play_arrow),
                )
              : null,
    );
  }
}
