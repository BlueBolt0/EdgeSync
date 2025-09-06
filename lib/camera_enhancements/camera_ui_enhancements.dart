/// Enhanced UI components for camera modes and controls
/// Modular widgets that can be integrated into existing camera apps
library camera_ui_enhancements;

import 'package:flutter/material.dart';
import 'camera_modes.dart';
import 'camera_controls.dart';
import 'image_processor.dart';

/// Enhanced mode selector widget with cool modes
class EnhancedModeSelector extends StatelessWidget {
  final CameraModeManager modeManager;
  final VoidCallback? onModeChanged;
  final bool showLabels;

  const EnhancedModeSelector({
    Key? key,
    required this.modeManager,
    this.onModeChanged,
    this.showLabels = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: CameraModes.availableModes.map((config) {
            final bool isSelected = modeManager.currentMode == config.mode;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () {
                  modeManager.setMode(config.mode);
                  onModeChanged?.call();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? config.primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? config.primaryColor : Colors.white30,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        config.icon,
                        color: isSelected ? Colors.white : Colors.white70,
                        size: 20,
                      ),
                      if (showLabels) ...[
                        const SizedBox(height: 4),
                        Text(
                          config.displayName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Filter selector for the filters mode
class FilterSelector extends StatelessWidget {
  final CameraModeManager modeManager;
  final VoidCallback? onFilterChanged;
  final bool isVisible;

  const FilterSelector({
    Key? key,
    required this.modeManager,
    this.onFilterChanged,
    this.isVisible = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible || modeManager.currentMode != CameraMode.filters) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: CameraFilters.availableFilters.length,
        itemBuilder: (context, index) {
          final filter = CameraFilters.availableFilters[index];
          final bool isSelected = modeManager.currentFilter == filter.type;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                modeManager.setFilter(filter.type);
                onFilterChanged?.call();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 60,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? filter.accentColor.withOpacity(0.3) 
                      : Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? filter.accentColor : Colors.white30,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      filter.icon,
                      color: isSelected ? filter.accentColor : Colors.white70,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      filter.displayName,
                      style: TextStyle(
                        color: isSelected ? filter.accentColor : Colors.white70,
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Enhanced shutter button with mode-specific styling
class EnhancedShutterButton extends StatefulWidget {
  final VoidCallback? onTap;
  final CameraMode currentMode;
  final bool isRecording;
  final bool isProcessing;

  const EnhancedShutterButton({
    Key? key,
    this.onTap,
    required this.currentMode,
    this.isRecording = false,
    this.isProcessing = false,
  }) : super(key: key);

  @override
  State<EnhancedShutterButton> createState() => _EnhancedShutterButtonState();
}

class _EnhancedShutterButtonState extends State<EnhancedShutterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final config = CameraModes.getConfig(widget.currentMode);
    
    return GestureDetector(
      onTap: widget.isProcessing ? null : _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: widget.isProcessing 
                    ? Colors.grey 
                    : (widget.isRecording ? Colors.red : config.primaryColor),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white70, 
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: config.primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: widget.isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Icon(
                        widget.isRecording 
                            ? Icons.stop 
                            : config.icon,
                        color: Colors.white,
                        size: 30,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Processing overlay with progress indicator
class ProcessingOverlay extends StatelessWidget {
  final bool isVisible;
  final double progress;
  final String? statusText;

  const ProcessingOverlay({
    Key? key,
    required this.isVisible,
    this.progress = 0.0,
    this.statusText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_fix_high,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                statusText ?? 'Processing image...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Enhanced camera preview with effects
class EnhancedCameraPreview extends StatelessWidget {
  final Widget cameraPreview;
  final CameraModeManager modeManager;
  final bool showEffects;

  const EnhancedCameraPreview({
    Key? key,
    required this.cameraPreview,
    required this.modeManager,
    this.showEffects = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!showEffects) return cameraPreview;

    return Stack(
      children: [
        // Camera preview with effects
        PreviewEffectsManager.buildPreviewWithEffects(
          cameraPreview: cameraPreview,
          mode: modeManager.currentMode,
          filter: modeManager.currentFilter,
        ),
        
        // Mode indicator
        PreviewEffectsManager.buildModeIndicator(
          mode: modeManager.currentMode,
          filter: modeManager.currentFilter,
        ),
        
        // Focus area indicator for portrait mode
        if (modeManager.currentMode == CameraMode.portrait)
          _buildPortraitFocusIndicator(),
      ],
    );
  }

  Widget _buildPortraitFocusIndicator() {
    return Center(
      child: Container(
        width: 200,
        height: 300,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.yellow.withOpacity(0.6),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'FOCUS AREA',
            style: TextStyle(
              color: Colors.yellow,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Quick settings panel for camera controls
class QuickSettingsPanel extends StatelessWidget {
  final CameraControlsManager? controlsManager;
  final VoidCallback? onFlashToggle;
  final VoidCallback? onGridToggle;
  final VoidCallback? onTimerToggle;
  final bool showGrid;
  final bool timerEnabled;

  const QuickSettingsPanel({
    Key? key,
    this.controlsManager,
    this.onFlashToggle,
    this.onGridToggle,
    this.onTimerToggle,
    this.showGrid = false,
    this.timerEnabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickButton(
            Icons.flash_auto,
            'Flash',
            onFlashToggle,
          ),
          _buildQuickButton(
            showGrid ? Icons.grid_on : Icons.grid_off,
            'Grid',
            onGridToggle,
            isActive: showGrid,
          ),
          _buildQuickButton(
            timerEnabled ? Icons.timer : Icons.timer_off,
            'Timer',
            onTimerToggle,
            isActive: timerEnabled,
          ),
          if (controlsManager != null)
            ValueListenableBuilder<bool>(
              valueListenable: controlsManager!.autoFocusNotifier,
              builder: (context, isAutoFocus, child) {
                return _buildQuickButton(
                  isAutoFocus ? Icons.center_focus_strong : Icons.center_focus_weak,
                  'Focus',
                  () => controlsManager!.toggleAutoFocus(),
                  isActive: isAutoFocus,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(
    IconData icon,
    String label,
    VoidCallback? onTap, {
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withOpacity(0.3) : Colors.black54,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.white30,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.blue : Colors.white70,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.blue : Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
