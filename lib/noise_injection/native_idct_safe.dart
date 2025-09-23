// Optional native IDCT library wrapper
// This implementation is designed to be completely optional and not interfere with Android builds
class NativeFastIdct {
  static bool _initialized = false;
  static bool _initAttempted = false;
  
  // Initialize the native library (completely optional)
  static bool init() {
    if (_initAttempted) return _initialized;
    _initAttempted = true;
    
    // For now, always return false to ensure Dart fallback is used
    // This ensures the app works on all platforms without FFI dependencies
    print('ℹ️  Native IDCT disabled for maximum Android compatibility');
    return false;
  }
  
  // Fast 2D IDCT using native C implementation (currently disabled)
  static List<List<double>>? fastIdct2d(List<List<double>> input) {
    // Always return null to use Dart fallback
    // This ensures consistent behavior across all platforms
    return null;
  }
}
