/// Camera Mode Types and Management
/// Defines different camera modes and their configurations
library camera_modes;

import 'package:flutter/material.dart';

/// Enum for different camera capture modes
enum CameraMode {
  normal,
  portrait,
  hdr,
  night,
  filters,
}

/// Enum for different filter types
enum FilterType {
  none,
  grayscale,
  sepia,
  vintage,
  vivid,
  cold,
  warm,
}

/// Configuration class for camera modes
class CameraModeConfig {
  final CameraMode mode;
  final String displayName;
  final IconData icon;
  final Color primaryColor;
  final String description;
  final bool requiresPostProcessing;
  final FilterType? defaultFilter;

  const CameraModeConfig({
    required this.mode,
    required this.displayName,
    required this.icon,
    required this.primaryColor,
    required this.description,
    this.requiresPostProcessing = false,
    this.defaultFilter,
  });
}

/// Predefined camera mode configurations
class CameraModes {
  static const List<CameraModeConfig> availableModes = [
    CameraModeConfig(
      mode: CameraMode.normal,
      displayName: 'PHOTO',
      icon: Icons.camera_alt,
      primaryColor: Colors.blue,
      description: 'Standard photo capture',
      requiresPostProcessing: false,
    ),
    CameraModeConfig(
      mode: CameraMode.portrait,
      displayName: 'PORTRAIT',
      icon: Icons.portrait,
      primaryColor: Colors.purple,
      description: 'Background blur effect',
      requiresPostProcessing: true,
    ),
    CameraModeConfig(
      mode: CameraMode.hdr,
      displayName: 'HDR',
      icon: Icons.hdr_on,
      primaryColor: Colors.orange,
      description: 'High dynamic range',
      requiresPostProcessing: true,
    ),
    CameraModeConfig(
      mode: CameraMode.night,
      displayName: 'NIGHT',
      icon: Icons.nightlight,
      primaryColor: Colors.indigo,
      description: 'Enhanced low light',
      requiresPostProcessing: true,
    ),
    CameraModeConfig(
      mode: CameraMode.filters,
      displayName: 'FILTERS',
      icon: Icons.filter,
      primaryColor: Colors.teal,
      description: 'Creative filters',
      requiresPostProcessing: true,
      defaultFilter: FilterType.vintage,
    ),
  ];

  /// Get configuration for a specific mode
  static CameraModeConfig getConfig(CameraMode mode) {
    return availableModes.firstWhere(
      (config) => config.mode == mode,
      orElse: () => availableModes.first,
    );
  }

  /// Get display name for a mode
  static String getDisplayName(CameraMode mode) {
    return getConfig(mode).displayName;
  }

  /// Get icon for a mode
  static IconData getIcon(CameraMode mode) {
    return getConfig(mode).icon;
  }

  /// Get primary color for a mode
  static Color getColor(CameraMode mode) {
    return getConfig(mode).primaryColor;
  }

  /// Check if mode requires post-processing
  static bool requiresPostProcessing(CameraMode mode) {
    return getConfig(mode).requiresPostProcessing;
  }
}

/// Filter configurations
class FilterConfig {
  final FilterType type;
  final String displayName;
  final IconData icon;
  final Color accentColor;

  const FilterConfig({
    required this.type,
    required this.displayName,
    required this.icon,
    required this.accentColor,
  });
}

/// Predefined filter configurations
class CameraFilters {
  static const List<FilterConfig> availableFilters = [
    FilterConfig(
      type: FilterType.none,
      displayName: 'Original',
      icon: Icons.crop_original,
      accentColor: Colors.grey,
    ),
    FilterConfig(
      type: FilterType.grayscale,
      displayName: 'B&W',
      icon: Icons.monochrome_photos,
      accentColor: Colors.black,
    ),
    FilterConfig(
      type: FilterType.sepia,
      displayName: 'Sepia',
      icon: Icons.wb_incandescent,
      accentColor: Colors.brown,
    ),
    FilterConfig(
      type: FilterType.vintage,
      displayName: 'Vintage',
      icon: Icons.auto_fix_high,
      accentColor: Colors.amber,
    ),
    FilterConfig(
      type: FilterType.vivid,
      displayName: 'Vivid',
      icon: Icons.color_lens,
      accentColor: Colors.red,
    ),
    FilterConfig(
      type: FilterType.cold,
      displayName: 'Cool',
      icon: Icons.ac_unit,
      accentColor: Colors.blue,
    ),
    FilterConfig(
      type: FilterType.warm,
      displayName: 'Warm',
      icon: Icons.wb_sunny,
      accentColor: Colors.orange,
    ),
  ];

  /// Get configuration for a specific filter
  static FilterConfig getConfig(FilterType type) {
    return availableFilters.firstWhere(
      (config) => config.type == type,
      orElse: () => availableFilters.first,
    );
  }

  /// Get display name for a filter
  static String getDisplayName(FilterType type) {
    return getConfig(type).displayName;
  }

  /// Get icon for a filter
  static IconData getIcon(FilterType type) {
    return getConfig(type).icon;
  }

  /// Get accent color for a filter
  static Color getAccentColor(FilterType type) {
    return getConfig(type).accentColor;
  }
}

/// Camera mode state management
class CameraModeManager extends ChangeNotifier {
  CameraMode _currentMode = CameraMode.normal;
  FilterType _currentFilter = FilterType.none;
  bool _isProcessing = false;

  CameraMode get currentMode => _currentMode;
  FilterType get currentFilter => _currentFilter;
  bool get isProcessing => _isProcessing;

  /// Get current mode configuration
  CameraModeConfig get currentConfig => CameraModes.getConfig(_currentMode);

  /// Check if current mode requires post-processing
  bool get requiresPostProcessing => CameraModes.requiresPostProcessing(_currentMode);

  /// Set camera mode
  void setMode(CameraMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      
      // Reset filter when changing modes (except for filter mode)
      if (mode != CameraMode.filters) {
        _currentFilter = FilterType.none;
      } else if (_currentFilter == FilterType.none) {
        // Set default filter for filter mode
        _currentFilter = FilterType.vintage;
      }
      
      notifyListeners();
    }
  }

  /// Set filter type
  void setFilter(FilterType filter) {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      notifyListeners();
    }
  }

  /// Set processing state
  void setProcessing(bool processing) {
    if (_isProcessing != processing) {
      _isProcessing = processing;
      notifyListeners();
    }
  }

  /// Reset to default mode
  void reset() {
    _currentMode = CameraMode.normal;
    _currentFilter = FilterType.none;
    _isProcessing = false;
    notifyListeners();
  }

  /// Get display name for current mode
  String get currentModeDisplayName => CameraModes.getDisplayName(_currentMode);

  /// Get icon for current mode
  IconData get currentModeIcon => CameraModes.getIcon(_currentMode);

  /// Get color for current mode
  Color get currentModeColor => CameraModes.getColor(_currentMode);

  /// Get display name for current filter
  String get currentFilterDisplayName => CameraFilters.getDisplayName(_currentFilter);

  /// Get icon for current filter
  IconData get currentFilterIcon => CameraFilters.getIcon(_currentFilter);

  /// Get accent color for current filter
  Color get currentFilterColor => CameraFilters.getAccentColor(_currentFilter);
}
