import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as path;
import '../services/harmonizer_service.dart';
import '../widgets/harmonizer_dialog.dart';
import '../noise_injection/android_noise_injector.dart';

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
  late List<String> _currentMediaPaths;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentMediaPaths = List.from(widget.mediaPaths);
  }

  void _addMediaPath(String path) {
    setState(() {
      _currentMediaPaths.insert(0, path);
      _pageController.jumpToPage(0);
    });
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
        itemCount: _currentMediaPaths.length,
        itemBuilder: (context, index) {
          return MediaViewer(
            filePath: _currentMediaPaths[index],
            onNewMedia: _addMediaPath,
          );
        },
      ),
    );
  }
}

class MediaViewer extends StatefulWidget {
  final String filePath;
  final Function(String newPath) onNewMedia;

  const MediaViewer({
    super.key,
    required this.filePath,
    required this.onNewMedia,
  });

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoPlayerController;
  bool _isVideo = false;
  final HarmonizerService _harmonizerService = HarmonizerService();
  bool _isProcessing = false;
  bool _showButtons = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

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

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _isVideofile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return extension == '.mp4' || extension == '.mov' || extension == '.avi';
  }

  Future<void> _handleHarmonizer() async {
    if (_isVideo) return; // Only for images

    setState(() => _isProcessing = true);
    try {
      await _showHarmonizerDialog(widget.filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Harmonizer error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handlePrivacy() async {
    if (_isVideo) return; // Only for images

    setState(() => _isProcessing = true);
    try {
      final imageBytes = await File(widget.filePath).readAsBytes();
      final result = await AndroidOptimizedNoiseInjector.injectNoise(
        imageBytes: imageBytes,
        filename: 'privacy_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (result != null && result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Privacy image saved!')));
        }
      } else {
        throw Exception(result?['error'] ?? 'Unknown error');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Privacy error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showHarmonizerDialog(String imagePath) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => HarmonizerDialog(
        key: ValueKey('harmonizer_${DateTime.now().millisecondsSinceEpoch}'),
        imagePath: imagePath,
        harmonizerService: _harmonizerService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(child: _isVideo ? _buildVideoPlayer() : _buildImageViewer()),
        if (_isProcessing) const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildImageViewer() {
    final isPrivacyImage = path.basename(widget.filePath).startsWith('privacy_');

    return GestureDetector(
      onTap: () {
        setState(() {
          _showButtons = !_showButtons;
          if (_showButtons) {
            _animationController.forward();
          } else {
            _animationController.reverse();
          }
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.file(File(widget.filePath), fit: BoxFit.contain),
          if (isPrivacyImage)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.privacy_tip,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          // Animated buttons
          Positioned(
            bottom: 30,
            child: FadeTransition(
              opacity: _animation,
              child: ScaleTransition(
                scale: _animation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(
                      icon: Icons.auto_awesome,
                      label: 'Harmonizer',
                      onTap: _handleHarmonizer,
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 20),
                    _buildActionButton(
                      icon: Icons.privacy_tip,
                      label: 'Privacy',
                      onTap: _handlePrivacy,
                      color: Colors.deepPurple,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: _isProcessing ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Color.fromRGBO(
            (color.r * 255).round(),
            (color.g * 255).round(),
            (color.b * 255).round(),
            0.9,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
