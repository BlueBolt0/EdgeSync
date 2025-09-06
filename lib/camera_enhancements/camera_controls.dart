import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

/// Enhanced camera controls that can be integrated into existing camera apps
/// Provides zoom, exposure, and focus controls
class CameraControlsManager {
  final CameraController cameraController;
  
  // Control states
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 8.0;
  double _currentExposure = 0.0;
  double _minExposure = -4.0;
  double _maxExposure = 4.0;
  bool _isAutoFocus = true;
  
  // Callbacks for UI updates
  ValueNotifier<double> zoomNotifier = ValueNotifier(1.0);
  ValueNotifier<double> exposureNotifier = ValueNotifier(0.0);
  ValueNotifier<bool> autoFocusNotifier = ValueNotifier(true);

  CameraControlsManager(this.cameraController) {
    _initializeLimits();
  }

  /// Initialize zoom and exposure limits based on camera capabilities
  Future<void> _initializeLimits() async {
    try {
      _minZoom = await cameraController.getMinZoomLevel();
      _maxZoom = await cameraController.getMaxZoomLevel();
      _minExposure = await cameraController.getMinExposureOffset();
      _maxExposure = await cameraController.getMaxExposureOffset();
      
      // Update notifiers with initial values
      zoomNotifier.value = _currentZoom;
      exposureNotifier.value = _currentExposure;
    } catch (e) {
      debugPrint('Error initializing camera limits: $e');
    }
  }

  /// Set zoom level (1.0 to maxZoom)
  Future<void> setZoom(double zoom) async {
    try {
      final clampedZoom = zoom.clamp(_minZoom, _maxZoom);
      await cameraController.setZoomLevel(clampedZoom);
      _currentZoom = clampedZoom;
      zoomNotifier.value = _currentZoom;
    } catch (e) {
      debugPrint('Error setting zoom: $e');
    }
  }

  /// Zoom in by specified factor
  Future<void> zoomIn([double factor = 0.2]) async {
    await setZoom(_currentZoom + factor);
  }

  /// Zoom out by specified factor
  Future<void> zoomOut([double factor = 0.2]) async {
    await setZoom(_currentZoom - factor);
  }

  /// Set exposure compensation (-4.0 to 4.0 typically)
  Future<void> setExposure(double exposure) async {
    try {
      final clampedExposure = exposure.clamp(_minExposure, _maxExposure);
      await cameraController.setExposureOffset(clampedExposure);
      _currentExposure = clampedExposure;
      exposureNotifier.value = _currentExposure;
    } catch (e) {
      debugPrint('Error setting exposure: $e');
    }
  }

  /// Tap to focus at specified screen coordinates
  Future<void> tapToFocus(Offset screenPoint, Size screenSize) async {
    try {
      // Convert screen coordinates to camera coordinates (0.0 to 1.0)
      final double x = screenPoint.dx / screenSize.width;
      final double y = screenPoint.dy / screenSize.height;
      
      await cameraController.setFocusPoint(Offset(x, y));
      await cameraController.setExposurePoint(Offset(x, y));
      
      // Temporarily disable auto focus
      _isAutoFocus = false;
      autoFocusNotifier.value = _isAutoFocus;
      
      // Re-enable auto focus after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        _isAutoFocus = true;
        autoFocusNotifier.value = _isAutoFocus;
      });
    } catch (e) {
      debugPrint('Error setting focus point: $e');
    }
  }

  /// Toggle auto focus mode
  Future<void> toggleAutoFocus() async {
    try {
      _isAutoFocus = !_isAutoFocus;
      if (_isAutoFocus) {
        await cameraController.setFocusMode(FocusMode.auto);
      } else {
        await cameraController.setFocusMode(FocusMode.locked);
      }
      autoFocusNotifier.value = _isAutoFocus;
    } catch (e) {
      debugPrint('Error toggling auto focus: $e');
    }
  }

  /// Reset all controls to default values
  Future<void> resetControls() async {
    await setZoom(_minZoom);
    await setExposure(0.0);
    if (!_isAutoFocus) {
      await toggleAutoFocus();
    }
  }

  // Getters for current values
  double get currentZoom => _currentZoom;
  double get currentExposure => _currentExposure;
  bool get isAutoFocus => _isAutoFocus;
  double get minZoom => _minZoom;
  double get maxZoom => _maxZoom;
  double get minExposure => _minExposure;
  double get maxExposure => _maxExposure;

  void dispose() {
    zoomNotifier.dispose();
    exposureNotifier.dispose();
    autoFocusNotifier.dispose();
  }
}

/// UI Widget for camera controls overlay
class CameraControlsOverlay extends StatefulWidget {
  final CameraControlsManager controlsManager;
  final VoidCallback? onTapToFocus;
  final bool showControls;

  const CameraControlsOverlay({
    Key? key,
    required this.controlsManager,
    this.onTapToFocus,
    this.showControls = true,
  }) : super(key: key);

  @override
  State<CameraControlsOverlay> createState() => _CameraControlsOverlayState();
}

class _CameraControlsOverlayState extends State<CameraControlsOverlay> {
  bool _showZoomSlider = false;
  bool _showExposureSlider = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.showControls) return const SizedBox.shrink();

    return Stack(
      children: [
        // Tap to focus detector
        Positioned.fill(
          child: GestureDetector(
            onTapUp: (details) async {
              final screenSize = MediaQuery.of(context).size;
              await widget.controlsManager.tapToFocus(
                details.globalPosition,
                screenSize,
              );
              widget.onTapToFocus?.call();
            },
            child: Container(color: Colors.transparent),
          ),
        ),

        // Zoom controls (right side)
        Positioned(
          right: 16,
          top: MediaQuery.of(context).size.height * 0.3,
          child: Column(
            children: [
              // Zoom in button
              _buildControlButton(
                Icons.zoom_in,
                () => widget.controlsManager.zoomIn(),
              ),
              const SizedBox(height: 8),
              
              // Zoom slider (shows when tapped)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _showZoomSlider ? 150 : 0,
                child: _showZoomSlider
                    ? ValueListenableBuilder<double>(
                        valueListenable: widget.controlsManager.zoomNotifier,
                        builder: (context, zoom, child) {
                          return RotatedBox(
                            quarterTurns: -1,
                            child: Slider(
                              value: zoom,
                              min: widget.controlsManager.minZoom,
                              max: widget.controlsManager.maxZoom,
                              divisions: 20,
                              activeColor: Colors.white,
                              inactiveColor: Colors.white30,
                              onChanged: (value) {
                                widget.controlsManager.setZoom(value);
                              },
                            ),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ),
              
              const SizedBox(height: 8),
              // Zoom out button
              _buildControlButton(
                Icons.zoom_out,
                () => widget.controlsManager.zoomOut(),
              ),
              
              const SizedBox(height: 16),
              
              // Zoom toggle button
              _buildControlButton(
                Icons.crop_free,
                () {
                  setState(() {
                    _showZoomSlider = !_showZoomSlider;
                    if (_showZoomSlider) _showExposureSlider = false;
                  });
                },
                isActive: _showZoomSlider,
              ),
            ],
          ),
        ),

        // Exposure controls (left side)
        Positioned(
          left: 16,
          top: MediaQuery.of(context).size.height * 0.3,
          child: Column(
            children: [
              // Exposure up button
              _buildControlButton(
                Icons.exposure_plus_1,
                () => widget.controlsManager.setExposure(
                  widget.controlsManager.currentExposure + 0.5,
                ),
              ),
              const SizedBox(height: 8),
              
              // Exposure slider
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: _showExposureSlider ? 150 : 0,
                child: _showExposureSlider
                    ? ValueListenableBuilder<double>(
                        valueListenable: widget.controlsManager.exposureNotifier,
                        builder: (context, exposure, child) {
                          return RotatedBox(
                            quarterTurns: -1,
                            child: Slider(
                              value: exposure,
                              min: widget.controlsManager.minExposure,
                              max: widget.controlsManager.maxExposure,
                              divisions: 16,
                              activeColor: Colors.orange,
                              inactiveColor: Colors.orange.withOpacity(0.3),
                              onChanged: (value) {
                                widget.controlsManager.setExposure(value);
                              },
                            ),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ),
              
              const SizedBox(height: 8),
              // Exposure down button
              _buildControlButton(
                Icons.exposure_neg_1,
                () => widget.controlsManager.setExposure(
                  widget.controlsManager.currentExposure - 0.5,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Exposure toggle button
              _buildControlButton(
                Icons.wb_sunny,
                () {
                  setState(() {
                    _showExposureSlider = !_showExposureSlider;
                    if (_showExposureSlider) _showZoomSlider = false;
                  });
                },
                isActive: _showExposureSlider,
              ),
            ],
          ),
        ),

        // Auto focus indicator (center top)
        Positioned(
          top: 50,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<bool>(
            valueListenable: widget.controlsManager.autoFocusNotifier,
            builder: (context, isAutoFocus, child) {
              return Center(
                child: GestureDetector(
                  onTap: () => widget.controlsManager.toggleAutoFocus(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAutoFocus ? Icons.center_focus_strong : Icons.center_focus_weak,
                          color: isAutoFocus ? Colors.green : Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAutoFocus ? 'AUTO' : 'MANUAL',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed, {bool isActive = false}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.3) : Colors.black54,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive ? Colors.white : Colors.white30,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
