import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as path;

class GalleryScreen extends StatefulWidget {
  final List<String> mediaPaths;
  final int initialIndex;

  const GalleryScreen({
    super.key,
    required this.mediaPaths,
    required this.initialIndex,
  });

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.mediaPaths.length,
        itemBuilder: (context, index) {
          return MediaViewer(filePath: widget.mediaPaths[index]);
        },
      ),
    );
  }
}

class MediaViewer extends StatefulWidget {
  final String filePath;

  const MediaViewer({super.key, required this.filePath});

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  VideoPlayerController? _videoPlayerController;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _isVideo = _isVideofile(widget.filePath);
    if (_isVideo) {
      _videoPlayerController = VideoPlayerController.file(File(widget.filePath))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
          }
        });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  bool _isVideofile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return extension == '.mp4' || extension == '.mov' || extension == '.avi';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _isVideo
          ? _buildVideoPlayer()
          : Image.file(File(widget.filePath), fit: BoxFit.contain),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: VideoPlayer(_videoPlayerController!),
          ),
          const SizedBox(height: 20),
          IconButton(
            onPressed: () {
              setState(() {
                _videoPlayerController!.value.isPlaying
                    ? _videoPlayerController!.pause()
                    : _videoPlayerController!.play();
              });
            },
            icon: Icon(
              _videoPlayerController!.value.isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              color: Colors.white,
              size: 60,
            ),
          ),
        ],
      );
    }
    return const CircularProgressIndicator();
  }
}
