# EdgeSync Project Documentation

## 1. Project Overview

EdgeSync is a feature-rich, intelligent camera application built with Flutter. It goes beyond standard camera functionality by integrating on-device AI to provide smart features like automatic smile detection, voice-activated controls, and a unique privacy-preserving noise injection system. The application is designed to be performant on a wide range of devices through its adaptive performance-tuning capabilities.

## 2. Core Features

### 📸 Camera System

- **High-Quality Capture**: Supports high-resolution photo and video recording.
- **Tap-to-Focus**: Users can tap anywhere on the camera preview to set the focus point. The camera also defaults to auto-focus on startup.
- **Flash Control**: Full control over flash modes: Off, Auto, Always On, and Torch.
- **Camera Switching**: Seamlessly switch between front and rear cameras.
- **Mode Toggling**: Easily switch between dedicated Photo and Video modes.

### 🖼️ Swipeable Gallery

- **Full-Screen Viewer**: A dedicated, full-screen gallery to view all captured photos and videos.
- **Swipe Navigation**: Users can easily swipe left and right to navigate between all the media captured in the session.
- **Dynamic Updates**: When a new "privacy" image is generated, it automatically appears in the gallery for immediate viewing.
- **Animated UI**: The Harmonizer and Privacy buttons in the gallery view appear with a smooth fade and scale animation when the user taps on a photo.

## 3. Advanced Features (AI & Privacy)

### ✨ Harmonizer Service

- The Harmonizer is a feature designed to process images for aesthetic improvements. When enabled, it presents a dialog after a photo is captured to apply its effects.

### 🔒 Privacy Mode (Noise Injection)

- **Concept**: This mode applies a layer of AI-generated noise to an image, preserving privacy while maintaining the general structure of the photo.
- **Implementation**: It uses a TFLite model to predict noise parameters.
- **Current Status (Important)**: The TFLite model inference is currently **commented out** in `lib/noise_injection/android_noise_injector.dart`. This is a temporary workaround to prevent a native `SIGSEGV` crash. The system currently falls back to using default noise parameters.
- **Gallery Integration**: Images processed with Privacy Mode are saved directly to the public device gallery using the `gal` package to ensure they are immediately visible.

### 😊 Smile Capture

- **Automatic Photo Capture**: The app uses on-device face detection (`google_mlkit_face_detection`) to detect smiling faces.
- **Countdown Timer**: When a majority of detected faces are smiling, a 3-second countdown is automatically triggered, after which a photo is taken. This allows for hands-free group photos.

### 🎤 Voice Commands

- **Hands-Free Control**: A microphone button enables voice commands to control the camera.
- **Functionality**: Users can say commands like "take picture", "start video", "stop video", "switch camera", etc.
- **Implementation**: Uses the `speech_to_text` package for voice recognition. The microphone automatically turns off after a command is processed.

## 4. Performance Optimization

The application includes a robust system to ensure it runs smoothly on both old and new devices.

- **Automatic Detection**: On startup, the app runs a quick benchmark to determine if the device is "old" or "new".
- **Dynamic Processing Intervals**:
  - **Old Device Mode**: Uses a longer interval (1500ms) between face detection frames to reduce CPU load and prevent crashes.
  - **New Device Mode**: Uses a shorter interval (500ms) for more responsive detection.
- **Manual Toggle**: A "speed" icon in the UI allows the user to manually override the performance mode, with a SnackBar providing clear feedback.

## 5. Technical Details

### Architecture

The app is built using Flutter and follows a standard widget-based architecture. Key components are separated into services (`HarmonizerService`, `VoiceCommandService`), screens (`GalleryScreen`), and the main camera logic (`CameraApp`).

### Key Dependencies

- `camera`: Core camera functionality.
- `google_mlkit_face_detection`: For on-device smile detection.
- `speech_to_text`: For voice command recognition.
- `tflite_flutter`: For running the noise injection model (currently partially disabled).
- `image`: For advanced image manipulation during noise injection.
- `gal`: For saving images and videos to the public device gallery.
- `permission_handler`: For managing camera and microphone permissions.
- `video_player`: For playing videos within the gallery.

### Project Structure

```
lib/
├── main.dart                   # App entry point
├── camera_app.dart             # Main camera UI and core logic
├──
├── screens/
│   ├── gallery_screen.dart     # Full-screen, swipeable media gallery
│   └── harmonizer_settings_screen.dart
├──
├── services/
│   ├── harmonizer_service.dart # Logic for the harmonizer feature
│   └── voice_command_service.dart  # Handles voice recognition
├──
├── noise_injection/
│   └── android_noise_injector.dart # Handles privacy noise injection
├──
└── widgets/
    ├── harmonizer_dialog.dart
    └── ui_components.dart      # Reusable UI widgets
```

## 6. Setup and Usage

### Prerequisites

- Flutter SDK
- Android Studio or Xcode
- A physical device with a camera

### Installation

1.  **Clone the repository.**
2.  **Move the project** to a file path that **does not contain spaces** (e.g., `C:\dev\EdgeSync`). This is critical to avoid Gradle build errors on Windows.
3.  **Install dependencies**: `flutter pub get`
4.  **Run the app**: `flutter run`

## 7. Troubleshooting

### Critical Build & Runtime Issues

1.  **Build Failure on Windows**:

    - **Error**: `Failed to create parent directory 'C:\Users\User Name With Spaces\...'`
    - **Solution**: The Gradle build process on Windows fails if the project path contains spaces. You **must** move the entire project folder to a simple path (e.g., `C:\dev\`) and run `flutter clean` before trying to build again.

2.  **Native Crash on Using Privacy Mode**:
    - **Error**: `Fatal signal 11 (SIGSEGV)` in `libtensorflowlite_jni.so`.
    - **Cause**: This is a native crash occurring during the TFLite model inference.
    - **Current Workaround**: The model prediction call in `lib/noise_injection/android_noise_injector.dart` has been commented out. The feature still "works" but uses default noise values instead of AI-predicted ones. To debug this, a developer would need to re-enable the call and investigate the tensor inputs/outputs or the model file itself.

### Common Issues

- **Camera not working**: Ensure you have granted Camera and Microphone permissions in your device settings.
- **App crashes on startup**: Ensure your device has functional camera hardware.

## 8. Future Enhancements

- Manual camera controls (ISO, shutter speed).
- Photo filters and effects.
- Time-lapse and burst photo modes.
- QR code scanning.
