# EdgeSync Camera App

A feature-rich camera application built with Flutter that supports both photo and video capture with advanced features.

## Features

### 📸 Photo Capture
- High-quality photo capture
- Flash control (Off, Auto, Always On, Torch)
- Front and rear camera switching
- Automatic saving to device gallery

### 🎥 Video Recording
- High-definition video recording
- Audio recording support
- Real-time recording indicator
- Automatic saving to device gallery

### 🔄 Camera Controls
- **Flash Modes**: 
  - 💡 Off
  - ⚡ Auto
  - 🔆 Always On
  - 🔦 Torch
- **Camera Switch**: Toggle between front and rear cameras
- **Mode Toggle**: Switch between Photo and Video modes

### 📱 User Interface
- Clean, modern dark theme
- Intuitive controls
- Live camera preview
- Last captured media preview
- Full-screen media viewer

## Getting Started

### Prerequisites
- Flutter SDK (3.9.0 or higher)
- Android Studio or Xcode for mobile development
- A device with camera capabilities

### Installation

1. Clone the repository:
```bash
git clone https://github.com/BlueBolt0/EdgeSync.git
cd EdgeSync/edgesync
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Permissions

The app automatically requests the following permissions:
- **Camera**: Required for photo and video capture
- **Microphone**: Required for video recording with audio
- **Storage**: Required for saving captured media to gallery

## How to Use

1. **Launch the App**: Open EdgeSync Camera
2. **Choose Mode**: Tap "PHOTO" or "VIDEO" at the top to switch modes
3. **Adjust Settings**:
   - Tap the flash icon (💡) to cycle through flash modes
   - Tap the flip camera icon to switch between front/rear cameras
4. **Capture**:
   - **Photo Mode**: Tap the white circle button to take a photo
   - **Video Mode**: Tap the red circle to start recording, tap again to stop
5. **View Media**: Tap the thumbnail on the bottom left to view your last captured photo/video

## Technical Details

### Dependencies
- `camera`: Camera functionality
- `permission_handler`: Runtime permissions
- `gallery_saver`: Save media to device gallery
- `video_player`: Video playback in preview
- `path`: File path utilities

### Supported Platforms
- ✅ Android
- ✅ iOS
- ✅ Web (limited camera support)

### Camera Features
- Multiple resolution support (up to high definition)
- Real-time preview
- Automatic focus
- Flash control
- Front/rear camera switching
- Landscape and portrait orientation support

## Project Structure

```
lib/
├── main.dart          # App entry point
└── camera_app.dart    # Main camera functionality
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Troubleshooting

### Common Issues

1. **Camera not working**: Ensure permissions are granted in device settings
2. **App crashes on startup**: Check that your device has camera hardware
3. **Videos not saving**: Verify storage permissions are granted
4. **Poor video quality**: Try adjusting the resolution in camera settings

### Performance Tips
- Close other camera apps before using EdgeSync
- Ensure adequate storage space for media files
- Use good lighting for better photo/video quality

## Future Enhancements

- [ ] Manual camera controls (ISO, shutter speed, etc.)
- [ ] Photo filters and effects
- [ ] Time-lapse video recording
- [ ] Burst photo mode
- [ ] HDR photography
- [ ] QR code scanning
- [ ] Cloud storage integration
